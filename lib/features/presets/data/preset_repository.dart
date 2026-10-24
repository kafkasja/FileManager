import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/features/filters/domain/file_filter.dart';
import 'package:kfm/features/presets/domain/preset.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'preset_repository.g.dart';

/// Saved presets (TASK-P6). Writes go through the write queue and return
/// its future, so callers can show errors (rule 8). Nothing on the swipe
/// path writes here: a preset changes only in its editor.
class PresetRepository {
  new(this._db, this._queue, {this._clock = DateTime.now});

  final AppDatabase _db;
  final DbWriteQueue _queue;
  final DateTime Function() _clock;

  Stream<List<PresetEntry>> watchAll() =>
      (_db.select(_db.presets)..orderBy([
            (p) => OrderingTerm.asc(p.sortOrder),
            (p) => OrderingTerm.asc(p.id),
          ]))
          .watch()
          .map((rows) => rows.map(toEntry).toList());

  Future<PresetEntry?> byId(int id) async {
    final row = await (_db.select(
      _db.presets,
    )..where((p) => p.id.equals(id))).getSingleOrNull();
    return row == null ? null : toEntry(row);
  }

  /// Throws [PresetNameException]. Returns the new id.
  Future<int> create({
    required String name,
    required SwipeLayout layout,
    String? filterJson,
  }) {
    final trimmed = _validName(name);
    return _write(() async {
      await _checkFree(trimmed);
      return await _insert(
        PresetsCompanion.insert(
          name: trimmed,
          layoutJson: jsonEncode(layout.toJson()),
          filterJson: Value(filterJson),
          sortOrder: await _nextSortOrder(),
          createdAt: _clock(),
        ),
      );
    });
  }

  Future<void> rename(int id, String name) {
    final trimmed = _validName(name);
    return _write(() async {
      await _checkFree(trimmed, except: id);
      await (_db.update(_db.presets)..where((p) => p.id.equals(id))).write(
        PresetsCompanion(name: Value(trimmed)),
      );
    });
  }

  /// "Name (2)", first free suffix. Returns the new id.
  Future<int> duplicate(int id) => _write(() async {
    final src = await (_db.select(
      _db.presets,
    )..where((p) => p.id.equals(id))).getSingle();
    var n = 2;
    String candidate() {
      final suffix = ' ($n)';
      final base = src.name.length + suffix.length > kPresetNameMax
          ? src.name.substring(0, kPresetNameMax - suffix.length)
          : src.name;
      return '$base$suffix';
    }

    while (await _taken(candidate())) {
      n++;
    }
    return await _insert(
      PresetsCompanion.insert(
        name: candidate(),
        layoutJson: src.layoutJson,
        filterJson: Value(src.filterJson),
        includeReviewed: Value(src.includeReviewed),
        sortOrder: await _nextSortOrder(),
        createdAt: _clock(),
      ),
    );
  });

  /// Rewrites sortOrder 0..n in this order.
  Future<void> reorder(List<int> idsInOrder) => _write(() async {
    for (final (i, id) in idsInOrder.indexed) {
      await (_db.update(_db.presets)..where((p) => p.id.equals(id))).write(
        PresetsCompanion(sortOrder: Value(i)),
      );
    }
  });

  /// The editor's Save: layout + filter in one write.
  Future<void> updateSetup(
    int id, {
    required SwipeLayout layout,
    String? filterJson,
  }) => _write(
    () => (_db.update(_db.presets)..where((p) => p.id.equals(id))).write(
      PresetsCompanion(
        layoutJson: Value(jsonEncode(layout.toJson())),
        filterJson: Value(filterJson),
      ),
    ),
  );

  Future<void> setIncludeReviewed(int id, {required bool value}) => _write(
    () => (_db.update(_db.presets)..where((p) => p.id.equals(id))).write(
      PresetsCompanion(includeReviewed: Value(value)),
    ),
  );

  /// Ends the preset's open sessions and deletes the row. The caller first
  /// switches away when it is the active preset.
  Future<void> delete(int id) => _write(() async {
    final now = _clock();
    await (_db.update(
      _db.sessions,
    )..where((s) => s.presetId.equals(id) & s.endedAt.isNull())).write(
      SessionsCompanion(
        isActive: const Value(false),
        endedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    await (_db.delete(_db.presets)..where((p) => p.id.equals(id))).go();
    await (_db.delete(
      _db.reviewedLabels,
    )..where((l) => l.presetKey.equals(id))).go();
  });

  /// Strict decoding: anything off gives [PresetLoadError], never Basic.
  static PresetEntry toEntry(PresetRow r) {
    try {
      final layout = switch (jsonDecode(r.layoutJson)) {
        final Map<String, Object?> j => SwipeLayout.fromJson(j),
        _ => throw const FormatException('layout'),
      };
      if (r.filterJson case final String f) {
        switch (jsonDecode(f)) {
          case final Map<String, Object?> j:
            FileFilter.fromJson(j);
          default:
            throw const FormatException('filter');
        }
      }
      return Preset(
        id: r.id,
        name: r.name,
        sortOrder: r.sortOrder,
        layout: layout,
        filterJson: r.filterJson,
        includeReviewed: r.includeReviewed,
      );
    } on FormatException {
      return PresetLoadError(id: r.id, name: r.name, sortOrder: r.sortOrder);
    }
  }

  /// Runs [body] in a queued transaction and returns its result.
  Future<T> _write<T>(Future<T> Function() body) async {
    late T result;
    await _queue.enqueue(
      null,
      () => _db.transaction(() async => result = await body()),
    );
    return result;
  }

  Future<int> _insert(PresetsCompanion row) =>
      _db.into(_db.presets).insert(row);

  Future<int> _nextSortOrder() async {
    final max = _db.presets.sortOrder.max();
    final row = await (_db.selectOnly(
      _db.presets,
    )..addColumns([max])).getSingle();
    return (row.read(max) ?? -1) + 1;
  }

  static String _validName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > kPresetNameMax) {
      throw const PresetNameException(PresetNameProblem.invalid);
    }
    return trimmed;
  }

  Future<bool> _taken(String name, {int? except}) async {
    final rows =
        await (_db.select(_db.presets)..where((p) {
              final same = p.name.lower().equals(name.toLowerCase());
              return except == null ? same : same & p.id.equals(except).not();
            }))
            .get();
    return rows.isNotEmpty;
  }

  Future<void> _checkFree(String name, {int? except}) async {
    if (await _taken(name, except: except)) {
      throw const PresetNameException(PresetNameProblem.taken);
    }
  }
}

@Riverpod(keepAlive: true)
PresetRepository presetRepository(Ref ref) => PresetRepository(
  ref.watch(appDatabaseProvider),
  ref.watch(dbWriteQueueProvider),
);

@Riverpod(keepAlive: true)
Stream<List<PresetEntry>> presets(Ref ref) =>
    ref.watch(presetRepositoryProvider).watchAll();

/// The preset the swipe tab uses; 0 = Basic.
@Riverpod(keepAlive: true)
Stream<int> activePresetId(Ref ref) =>
    ref.watch(settingsRepositoryProvider).watch(AppSettings.activePresetId);
