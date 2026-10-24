import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/utils/debouncer.dart';
import 'package:kfm/features/presets/data/preset_repository.dart';
import 'package:kfm/features/presets/domain/preset.dart';
import 'package:kfm/features/session/domain/session.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';

/// The active swipe session and its quiet, lag-free saving (TASK-SE1).
///
/// - Progress (cursor) is debounced 300 ms and coalesced in the write queue.
/// - Layout/filter are written when they change.
/// - Undo rows (S2) and pending deletes (D2) are written immediately by their
///   own repositories through the same queue.
class SessionRepository {
  new(this._db, this._queue, {this._clock = DateTime.now});

  static const cursorDebounce = Duration(milliseconds: 300);

  final AppDatabase _db;
  final DbWriteQueue _queue;
  final DateTime Function() _clock;
  final Debouncer _cursorDebouncer = Debouncer(cursorDebounce);

  Future<Session?> active() async {
    final row = await (_db.select(
      _db.sessions,
    )..where((s) => s.isActive.equals(true))).getSingleOrNull();
    return row == null ? null : _toSession(row);
  }

  Stream<Session?> watchActive() =>
      (_db.select(_db.sessions)..where((s) => s.isActive.equals(true)))
          .watchSingleOrNull()
          .map((row) => row == null ? null : _toSession(row));

  /// The active session; else the active preset's paused session (P6),
  /// resumed; else a new one for the active preset (or Basic's saved
  /// layout) with [deleteMode] (default: the current setting).
  Future<Session> getOrCreateActive({DeleteMode? deleteMode}) async {
    await _queue.flush();
    return await _db.transaction(() async {
      final existing = await active();
      if (existing != null) return existing;
      final presetKey = AppSettings.activePresetId.decodeFromDb(
        await _setting(AppSettings.activePresetId.name) ?? '0',
      );
      PresetRow? preset;
      if (presetKey != 0) {
        preset = await (_db.select(
          _db.presets,
        )..where((p) => p.id.equals(presetKey))).getSingleOrNull();
        // Missing or unreadable preset: back to Basic.
        if (preset == null ||
            PresetRepository.toEntry(preset) is PresetLoadError) {
          preset = null;
          await _writeSetting(AppSettings.activePresetId.name, '0');
        }
      }
      final paused = await _pausedRow(preset?.id);
      if (paused != null) {
        await (_db.update(
          _db.sessions,
        )..where((x) => x.id.equals(paused.id))).write(
          SessionsCompanion(
            isActive: const Value(true),
            updatedAt: Value(_clock()),
          ),
        );
        return (await _byId(paused.id))!;
      }
      final layoutJson =
          preset?.layoutJson ??
          _layoutOrBasic(await _setting(AppSettings.swipeLayoutCurrent.name));
      final mode =
          deleteMode ??
          DeleteMode.parse(
            AppSettings.deleteMode.decodeFromDb(
              await _setting(AppSettings.deleteMode.name) ?? '"trash"',
            ),
          );
      final now = _clock();
      final id = await _db
          .into(_db.sessions)
          .insert(
            SessionsCompanion.insert(
              presetId: Value(preset?.id),
              layout: layoutJson,
              filter: Value(preset?.filterJson),
              deleteMode: Value(mode.name),
              startedAt: now,
              updatedAt: now,
              isActive: true,
            ),
          );
      return (await _byId(id))!;
    });
  }

  /// Debounced: ten swipes in a second become one UPDATE.
  void saveCursor(int sessionId, int cursor, String? fileId) {
    _cursorDebouncer.run(
      () => _queue
          .enqueue(
            'session.cursor:$sessionId',
            () =>
                (_db.update(
                  _db.sessions,
                )..where((s) => s.id.equals(sessionId))).write(
                  SessionsCompanion(
                    cursor: Value(cursor),
                    cursorFileId: Value(fileId),
                    updatedAt: Value(_clock()),
                  ),
                ),
          )
          .fireAndForget(),
    );
  }

  /// Saves the layout on the session. A Basic session also mirrors it as the
  /// app-wide current layout; in a preset it's a session-only change (the
  /// preset changes only in its editor, P6).
  Future<void> saveLayout(int sessionId, SwipeLayout layout) {
    final json = jsonEncode(layout.toJson());
    return _queue.enqueue(
      'session.layout:$sessionId',
      () => _db.transaction(() async {
        await (_db.update(
          _db.sessions,
        )..where((s) => s.id.equals(sessionId))).write(
          SessionsCompanion(layout: Value(json), updatedAt: Value(_clock())),
        );
        final session = await _byId(sessionId);
        if (session?.presetId != null) return;
        await _db
            .into(_db.settings)
            .insertOnConflictUpdate(
              SettingRow(
                key: AppSettings.swipeLayoutCurrent.name,
                value: AppSettings.swipeLayoutCurrent.encodeToDb(json),
              ),
            );
      }),
    );
  }

  Future<void> saveFilter(int sessionId, String? filterJson) => _queue.enqueue(
    'session.filter:$sessionId',
    () =>
        (_db.update(_db.sessions)..where((s) => s.id.equals(sessionId))).write(
          SessionsCompanion(
            filter: Value(filterJson),
            updatedAt: Value(_clock()),
          ),
        ),
  );

  /// Ends the active session (Done / SE3). Its history stays for stats.
  Future<void> endActive() async {
    await flush();
    await _queue.enqueue(
      null,
      () => (_db.update(_db.sessions)..where((s) => s.isActive.equals(true)))
          .write(
            SessionsCompanion(
              isActive: const Value(false),
              updatedAt: Value(_clock()),
              endedAt: Value(_clock()),
            ),
          ),
    );
  }

  /// P6: the open but inactive session of [presetId] (null = Basic).
  Future<Session?> pausedFor(int? presetId) async {
    final row = await _pausedRow(presetId);
    return row == null ? null : _toSession(row);
  }

  Future<SessionRow?> _pausedRow(int? presetId) =>
      (_db.select(_db.sessions)..where(
            (s) =>
                s.isActive.equals(false) &
                s.endedAt.isNull() &
                (presetId == null
                    ? s.presetId.isNull()
                    : s.presetId.equals(presetId)),
          ))
          .getSingleOrNull();

  /// P6: pauses [fromSessionId], resumes [toPresetId]'s paused session if
  /// there is one, and makes [toPresetId] the active preset, in one
  /// transaction. Without a paused session nothing is active afterwards;
  /// the deck (or D1's gate) creates it.
  Future<void> switchActive({
    required int fromSessionId,
    required int? toPresetId,
  }) async {
    await flush();
    await _queue.enqueue(
      null,
      () => _db.transaction(() async {
        final now = _clock();
        await (_db.update(
          _db.sessions,
        )..where((s) => s.id.equals(fromSessionId))).write(
          SessionsCompanion(
            isActive: const Value(false),
            updatedAt: Value(now),
          ),
        );
        final paused = await _pausedRow(toPresetId);
        if (paused != null) {
          await (_db.update(
            _db.sessions,
          )..where((s) => s.id.equals(paused.id))).write(
            SessionsCompanion(
              isActive: const Value(true),
              updatedAt: Value(now),
            ),
          );
        }
        await _writeSetting(
          AppSettings.activePresetId.name,
          AppSettings.activePresetId.encodeToDb(toPresetId ?? 0),
        );
      }),
    );
  }

  /// P6 editor Save: the preset's open session (active or paused) uses the
  /// setup just saved.
  Future<void> applyPresetToOpenSession(
    int presetId, {
    required SwipeLayout layout,
    String? filterJson,
  }) => _queue.enqueue(
    null,
    () =>
        (_db.update(_db.sessions)
              ..where((s) => s.presetId.equals(presetId) & s.endedAt.isNull()))
            .write(
              SessionsCompanion(
                layout: Value(jsonEncode(layout.toJson())),
                filter: Value(filterJson),
                updatedAt: Value(_clock()),
              ),
            ),
  );

  Future<void> _writeSetting(String key, String value) => _db
      .into(_db.settings)
      .insertOnConflictUpdate(SettingRow(key: key, value: value));

  /// App pause/hide/detach and before SE3 clears: everything lands on disk.
  Future<void> flush() async {
    _cursorDebouncer.flushNow();
    await _queue.flush();
  }

  Future<String?> _setting(String key) async => (await (_db.select(
    _db.settings,
  )..where((s) => s.key.equals(key))).getSingleOrNull())?.value;

  Future<Session?> _byId(int id) async {
    final row = await (_db.select(
      _db.sessions,
    )..where((s) => s.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toSession(row);
  }

  /// Settings value is JSON-encoded layout JSON; '' or bad → basic.
  static String _layoutOrBasic(String? settingValue) {
    final layout = settingValue == null
        ? ''
        : AppSettings.swipeLayoutCurrent.decodeFromDb(settingValue);
    return layout.isEmpty ? jsonEncode(SwipeLayout.basic.toJson()) : layout;
  }

  static Session _toSession(SessionRow r) => Session(
    id: r.id,
    layout: _parseLayout(r.layout),
    deleteMode: DeleteMode.parse(r.deleteMode),
    filterJson: r.filter,
    cursor: r.cursor,
    cursorFileId: r.cursorFileId,
    presetId: r.presetId,
    startedAt: r.startedAt,
    updatedAt: r.updatedAt,
  );

  /// Corrupt layout → basic (logged); the user's files are unaffected.
  static SwipeLayout _parseLayout(String json) => SwipeLayout.decode(json);
}
