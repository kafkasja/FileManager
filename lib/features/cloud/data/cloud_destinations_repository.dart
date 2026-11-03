import 'dart:developer' as developer;

import 'package:drift/drift.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/tables/cloud_items_table.dart';
import 'package:kfm/core/files/android/files_channel.dart';
import 'package:kfm/features/cloud/domain/cloud_destination.dart';

/// The system tree picker and persisted grants, as X3 needs them (Android:
/// U1's `SafTrees.kt` plus `CloudSaf.kt`'s label lookup).
abstract interface class CloudTreePlatform {
  /// Null = cancelled.
  Future<String?> pickTree();
  Future<bool> persistTree(String uri);
  Future<bool> releaseTree(String uri);
  Future<List<String>> persistedTrees();
  Future<({String? authority, String? name})> label(String uri);
}

class ChannelCloudTreePlatform implements CloudTreePlatform {
  const new(this._channel);

  final FilesChannel _channel;

  @override
  Future<String?> pickTree() async => (await _channel.pickTree())?.uri;

  @override
  Future<bool> persistTree(String uri) => _channel.persistTree(uri);

  @override
  Future<bool> releaseTree(String uri) => _channel.releaseTree(uri);

  @override
  Future<List<String>> persistedTrees() => _channel.persistedTrees();

  @override
  Future<({String? authority, String? name})> label(String uri) =>
      _channel.cloudTreeLabel(uri);
}

/// How [CloudDestinationsRepository.addFromPicker] ended.
enum CloudAddOutcome { added, cancelled, failed }

CloudDestination _toDomain(CloudDestinationRow r) => CloudDestination(
  id: r.id,
  label: r.label,
  provider: r.providerGuess,
  location: r.location,
  addedAt: r.addedAt,
  removedAt: r.removedAt,
);

/// `cloud_destinations` (TASK-X3). Writes go through the [DbWriteQueue].
class CloudDestinationsRepository {
  new(
    this._db,
    this._queue, {
    required this._platform,
    required this._protectedTrees,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final DbWriteQueue _queue;

  /// Null off Android (nothing can be added).
  final CloudTreePlatform? _platform;

  /// Tree URIs other features hold (U1 volume grants): never released here.
  final Future<Set<String>> Function() _protectedTrees;
  final DateTime Function() _now;

  /// [DbWriteQueue.enqueue] with the write's result.
  Future<T> _write<T>(Future<T> Function() run) async {
    late T result;
    await _queue.enqueue(null, () async => result = await run());
    return result;
  }

  Stream<List<CloudDestination>> watchActive() =>
      (_db.select(_db.cloudDestinations)
            ..where((d) => d.removedAt.isNull())
            ..orderBy([(d) => OrderingTerm.asc(d.label)]))
          .watch()
          .map((rows) => rows.map(_toDomain).toList());

  /// Every destination, removed ones too (labels of old uploads).
  Stream<Map<int, CloudDestination>> watchAllById() => _db
      .select(_db.cloudDestinations)
      .watch()
      .map((rows) => {for (final r in rows) r.id: _toDomain(r)});

  Future<CloudDestination?> byId(int id) async {
    final r = await (_db.select(
      _db.cloudDestinations,
    )..where((d) => d.id.equals(id))).getSingleOrNull();
    return r == null ? null : _toDomain(r);
  }

  /// Cheap start-up check (Hard rule 1).
  Future<bool> hasActive() async {
    final r = await _db
        .customSelect(
          'SELECT EXISTS (SELECT 1 FROM cloud_destinations '
          'WHERE removed_at IS NULL) AS e',
          readsFrom: {_db.cloudDestinations},
        )
        .getSingle();
    return r.read<bool>('e');
  }

  /// Adds the folder at [location], or re-activates its removed row (same
  /// id, its history stays linked). Returns the id.
  Future<int> add({
    required String location,
    required String label,
    required CloudProviderGuess provider,
  }) => _write(
    () => _db.transaction(() async {
      final old = await (_db.select(
        _db.cloudDestinations,
      )..where((d) => d.location.equals(location))).getSingleOrNull();
      if (old != null) {
        await (_db.update(
          _db.cloudDestinations,
        )..where((d) => d.id.equals(old.id))).write(
          CloudDestinationsCompanion(
            removedAt: const Value(null),
            label: old.removedAt == null ? const Value.absent() : Value(label),
          ),
        );
        return old.id;
      }
      return await _db
          .into(_db.cloudDestinations)
          .insert(
            CloudDestinationsCompanion.insert(
              label: label,
              providerGuess: provider,
              location: location,
              addedAt: _now(),
            ),
          );
    }),
  );

  /// The system picker → persisted grant → a destination. A grant that
  /// can't be stored is released again.
  Future<CloudAddOutcome> addFromPicker() async {
    final platform = _platform;
    if (platform == null) return CloudAddOutcome.failed;
    final uri = await platform.pickTree();
    if (uri == null) return CloudAddOutcome.cancelled;
    if (!await platform.persistTree(uri)) return CloudAddOutcome.failed;
    try {
      final info = await platform.label(uri);
      final provider = guessProvider(info.authority);
      await add(
        location: uri,
        label: defaultCloudLabel(provider, info.name),
        provider: provider,
      );
      return CloudAddOutcome.added;
    } on Object {
      await _release(uri);
      rethrow;
    }
  }

  Future<void> rename(int id, String label) {
    final clean = clampCloudLabel(label);
    if (clean.isEmpty) throw ArgumentError.value(label, 'label', 'empty');
    return _write(
      () => (_db.update(_db.cloudDestinations)..where((d) => d.id.equals(id)))
          .write(CloudDestinationsCompanion(label: Value(clean))),
    );
  }

  /// Soft delete (Hard rule 4): `removedAt` is set, its waiting uploads
  /// fail ("destination removed"), with [forgetUploads] its `cloud_items`
  /// are deleted; then the grant is released (a failure there is only
  /// logged).
  Future<void> remove(int id, {required bool forgetUploads}) async {
    final location = await _write(
      () => _db.transaction(() async {
        final row = await (_db.select(
          _db.cloudDestinations,
        )..where((d) => d.id.equals(id))).getSingleOrNull();
        if (row == null) return null;
        await (_db.update(_db.cloudDestinations)..where((d) => d.id.equals(id)))
            .write(CloudDestinationsCompanion(removedAt: Value(_now())));
        await (_db.update(_db.cloudItems)..where(
              (i) =>
                  i.destinationId.equals(id) &
                  i.status.isInValues(const [
                    CloudItemStatus.queued,
                    CloudItemStatus.uploading,
                  ]),
            ))
            .write(
              const CloudItemsCompanion(
                status: Value(CloudItemStatus.failed),
                error: Value(CloudItemErrors.destinationRemoved),
              ),
            );
        if (forgetUploads) {
          await (_db.delete(
            _db.cloudItems,
          )..where((i) => i.destinationId.equals(id))).go();
        }
        return row.location;
      }),
    );
    if (location != null) await _release(location);
  }

  Future<void> _release(String uri) async {
    final platform = _platform;
    if (platform == null) return;
    try {
      if ((await _protectedTrees()).contains(uri)) return;
      if ((await platform.persistedTrees()).contains(uri)) {
        await platform.releaseTree(uri);
      }
    } on Object catch (e) {
      developer.log('cloud grant not released: $e', name: 'kfm.cloud');
    }
  }

  /// The persisted-permission check: a destination whose grant is gone
  /// "Needs reconnecting". Empty when there is nothing to check (no
  /// platform call then).
  Future<Map<int, CloudDestinationHealth>> health(
    List<CloudDestination> destinations,
  ) async {
    final platform = _platform;
    if (platform == null || destinations.isEmpty) return const {};
    final held = (await platform.persistedTrees()).toSet();
    return {
      for (final d in destinations)
        d.id: held.contains(d.location)
            ? CloudDestinationHealth.ok
            : CloudDestinationHealth.needsReconnecting,
    };
  }

  /// Re-picks a destination whose grant was lost. The picked folder must
  /// be the same one (same tree URI); another folder is added as a new
  /// destination instead.
  Future<CloudAddOutcome> reconnect(CloudDestination d) => addFromPicker();
}

/// Error codes stored in `cloud_items.error`.
abstract final class CloudItemErrors {
  static const destinationRemoved = 'destinationRemoved';
  static const needsReconnecting = 'needsReconnecting';
  static const cancelled = 'cancelled';
  static const verify = 'verify';
  static const verifyUnavailable = 'verifyUnavailable';
  static const sourceGone = 'sourceGone';
  static const sourceChanged = 'sourceChanged';
  static const unsupported = 'unsupported';
  static const locationNotRemoved = 'locationNotRemoved';
  static const copyMissing = 'copyMissing';
  static const interrupted = 'interrupted';
}
