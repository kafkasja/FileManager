import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/tables/known_devices_table.dart';
import 'package:kfm/core/utils/random_id.dart';
import 'package:kfm/features/connect/data/path_guard.dart';
import 'package:kfm/features/connect/domain/known_device.dart';
import 'package:kfm/features/connect/domain/share_scope.dart';

part 'known_devices_dao.g.dart';

/// Raw access to `known_devices` (TASK-N6). Use [KnownDevicesRepository]
/// from the UI isolate (writes go through the write queue).
@DriftAccessor(tables: [KnownDevices])
class KnownDevicesDao extends DatabaseAccessor<AppDatabase>
    with _$KnownDevicesDaoMixin {
  new(super.attachedDatabase);

  Stream<List<KnownDeviceRow>> watchVisible() =>
      (select(knownDevices)
            ..where((d) => d.isTemporary.equals(false))
            ..orderBy([
              (d) => OrderingTerm.desc(d.lastSeenAtMs),
              (d) => OrderingTerm.asc(d.id),
            ]))
          .watch();

  Future<List<KnownDeviceRow>> all() => select(knownDevices).get();

  Future<KnownDeviceRow?> byFingerprint(String fp) => (select(
    knownDevices,
  )..where((d) => d.publicKeyFingerprint.equals(fp))).getSingleOrNull();

  Future<void> insertRow(KnownDevicesCompanion row) =>
      into(knownDevices).insert(row);

  Future<void> updateByFingerprint(String fp, KnownDevicesCompanion row) =>
      (update(
        knownDevices,
      )..where((d) => d.publicKeyFingerprint.equals(fp))).write(row);

  Future<void> deleteById(String id) =>
      (delete(knownDevices)..where((d) => d.id.equals(id))).go();

  Future<void> deleteAll() => delete(knownDevices).go();

  /// Temporary rows not seen since [cutoffMs]; returns how many.
  Future<int> deleteTemporaryBefore(int cutoffMs) =>
      (delete(knownDevices)..where(
            (d) =>
                d.isTemporary.equals(true) &
                d.lastSeenAtMs.isSmallerThanValue(cutoffMs),
          ))
          .go();
}

KnownDevice knownDeviceFromRow(KnownDeviceRow r) => KnownDevice(
  id: r.id,
  peerDeviceId: r.peerDeviceId,
  name: r.name,
  platform: r.platform,
  fingerprint: r.publicKeyFingerprint,
  lastSeenAt: DateTime.fromMillisecondsSinceEpoch(r.lastSeenAtMs),
  lastAddresses: decodeAddresses(r.lastAddresses),
  allowedRoots: decodeStoredRoots(r.allowedRootsJson),
  canShareToUs: r.canShareToUs,
  isTemporary: r.isTemporary,
  autoAccept: r.autoAccept,
  autoAcceptFiles: r.autoAcceptFiles,
);

/// Remembered devices (TASK-N6). Reads go straight to the DAO; every write
/// goes through [DbWriteQueue] (ordered; failures land on its error stream
/// and on the returned future).
class KnownDevicesRepository {
  new(this._dao, this._queue, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final KnownDevicesDao _dao;
  final DbWriteQueue _queue;
  final DateTime Function() _clock;

  /// Non-temporary devices, most recently seen first.
  Stream<List<KnownDevice>> watchVisible() => _dao.watchVisible().map(
    (rows) => [for (final r in rows) knownDeviceFromRow(r)],
  );

  /// Includes temporary rows (`/v1/pair/known` accepts them).
  Future<KnownDevice?> byFingerprint(String fp) async {
    final row = await _dao.byFingerprint(fp);
    return row == null ? null : knownDeviceFromRow(row);
  }

  /// Every row, temporary ones included.
  Future<List<KnownDevice>> all() async => [
    for (final r in await _dao.all()) knownDeviceFromRow(r),
  ];

  /// Inserts a row (new local id) when [peer]'s fingerprint is unknown,
  /// otherwise updates THAT row: name, platform, peerDeviceId, lastSeenAt,
  /// addresses (merged), `canShareToUs` (OR-ed), `isTemporary` (a
  /// non-temporary save clears it) and `autoAccept` (when given). The
  /// fingerprint of a row never changes.
  Future<KnownDevice> saveAfterPairing(
    PairedPeer peer, {
    required bool temporary,
  }) async {
    late KnownDevice saved;
    await _queue.enqueue(null, () async {
      saved = await _dao.transaction(() async {
        final now = _clock().millisecondsSinceEpoch;
        final existing = await _dao.byFingerprint(peer.fingerprint);
        if (existing == null) {
          await _dao.insertRow(
            KnownDevicesCompanion.insert(
              id: randomHexId(),
              peerDeviceId: peer.peerDeviceId,
              name: peer.name,
              platform: peer.platform,
              publicKeyFingerprint: peer.fingerprint,
              lastSeenAtMs: now,
              lastAddresses: Value(
                jsonEncode(mergeAddresses(peer.addresses, const [])),
              ),
              canShareToUs: Value(peer.canShareToUs),
              isTemporary: Value(temporary),
              autoAccept: Value(peer.autoAccept ?? false),
            ),
          );
        } else {
          await _dao.updateByFingerprint(
            peer.fingerprint,
            KnownDevicesCompanion(
              peerDeviceId: Value(peer.peerDeviceId),
              name: Value(peer.name),
              // A best-effort platform probe may fail: keep the old one.
              platform: Value(
                peer.platform.isEmpty ? existing.platform : peer.platform,
              ),
              lastSeenAtMs: Value(now),
              lastAddresses: Value(
                jsonEncode(
                  mergeAddresses(
                    peer.addresses,
                    decodeAddresses(existing.lastAddresses),
                  ),
                ),
              ),
              canShareToUs: Value(existing.canShareToUs || peer.canShareToUs),
              isTemporary: Value(existing.isTemporary && temporary),
              autoAccept: Value(peer.autoAccept ?? existing.autoAccept),
            ),
          );
        }
        return knownDeviceFromRow(
          (await _dao.byFingerprint(peer.fingerprint))!,
        );
      });
    });
    return saved;
  }

  /// What this device shares with [fp] (no-op for an unknown device).
  Future<void> setAllowedRoots(String fp, List<SharedRoot> roots) =>
      _queue.enqueue(
        null,
        () => _dao.updateByFingerprint(
          fp,
          KnownDevicesCompanion(
            allowedRootsJson: Value(
              encodeStoredRoots([
                for (final r in roots) StoredRoot.fromSharedRoot(r),
              ]),
            ),
          ),
        ),
      );

  /// "Always allow" (no-op for an unknown device).
  Future<void> setAutoAccept(String fp, {required bool autoAccept}) =>
      _queue.enqueue(
        null,
        () => _dao.updateByFingerprint(
          fp,
          KnownDevicesCompanion(autoAccept: Value(autoAccept)),
        ),
      );

  /// N12 "Accept files without asking" (no-op for an unknown device).
  Future<void> setAutoAcceptFiles(String fp, {required bool enabled}) =>
      _queue.enqueue(
        null,
        () => _dao.updateByFingerprint(
          fp,
          KnownDevicesCompanion(autoAcceptFiles: Value(enabled)),
        ),
      );

  /// A successful reconnect: lastSeenAt = now, [addresses] merged in front.
  Future<void> touch(String fp, List<String> addresses) =>
      _queue.enqueue('known_devices.touch.$fp', () async {
        final existing = await _dao.byFingerprint(fp);
        if (existing == null) return;
        await _dao.updateByFingerprint(
          fp,
          KnownDevicesCompanion(
            lastSeenAtMs: Value(_clock().millisecondsSinceEpoch),
            lastAddresses: Value(
              jsonEncode(
                mergeAddresses(
                  addresses,
                  decodeAddresses(existing.lastAddresses),
                ),
              ),
            ),
          ),
        );
      });

  Future<void> remove(String id) =>
      _queue.enqueue(null, () => _dao.deleteById(id));

  Future<void> removeAll() => _queue.enqueue(null, _dao.deleteAll);

  /// Startup cleanup: temporary rows not seen for [maxAge].
  Future<int> purgeTemporary([Duration maxAge = kTemporaryDeviceMaxAge]) async {
    var purged = 0;
    await _queue.enqueue(null, () async {
      purged = await _dao.deleteTemporaryBefore(
        _clock().subtract(maxAge).millisecondsSinceEpoch,
      );
    });
    return purged;
  }

  /// The stored folders of [fp], re-canonicalised with [guard]; folders
  /// that no longer exist are dropped (reported in [StoredScope.dropped]).
  /// Root ids are recomputed from [salt], never read from storage.
  Future<StoredScope> allowedRoots(
    String fp, {
    required List<int> salt,
    required PathGuard guard,
    required Future<bool> Function(String path) exists,
  }) async {
    final device = await byFingerprint(fp);
    if (device == null || device.allowedRoots.isEmpty) {
      return StoredScope.empty;
    }
    final roots = <SharedRoot>[];
    var dropped = false;
    for (final r in device.allowedRoots) {
      String path;
      try {
        path = await guard.canonicalise(r.path);
      } on GuardRejection {
        dropped = true;
        continue;
      }
      if (PathGuard.isExcluded(path) || !await exists(path)) {
        dropped = true;
        continue;
      }
      if (roots.any((x) => x.path == path)) continue;
      roots.add(
        SharedRoot(
          id: PathGuard.rootId(salt, path),
          path: path,
          label: r.label,
          readOnly: r.readOnly,
        ),
      );
    }
    return StoredScope(roots: List.unmodifiable(roots), dropped: dropped);
  }
}
