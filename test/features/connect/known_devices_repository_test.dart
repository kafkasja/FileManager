import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/features/connect/data/known_devices_dao.dart';
import 'package:kfm/features/connect/data/path_guard.dart';
import 'package:kfm/features/connect/domain/known_device.dart';
import 'package:kfm/features/connect/domain/share_scope.dart';

void main() {
  late AppDatabase db;
  late DbWriteQueue queue;
  late KnownDevicesRepository repo;
  var now = DateTime(2026, 11, 2, 12);

  final fpA = 'aa' * 32;
  final fpB = 'bb' * 32;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    queue = DbWriteQueue();
    now = DateTime(2026, 11, 2, 12);
    repo = KnownDevicesRepository(KnownDevicesDao(db), queue, clock: () => now);
  });

  tearDown(() async {
    await queue.close();
    await db.close();
  });

  PairedPeer peer(
    String fp, {
    String deviceId = 'dev-a',
    String name = 'Phone A',
    String platform = 'android',
    List<String> addresses = const [],
    bool canShareToUs = false,
    bool? autoAccept,
  }) => PairedPeer(
    fingerprint: fp,
    peerDeviceId: deviceId,
    name: name,
    platform: platform,
    addresses: addresses,
    canShareToUs: canShareToUs,
    autoAccept: autoAccept,
  );

  test('saveAfterPairing inserts, then updates the same row by '
      'fingerprint', () async {
    final first = await repo.saveAfterPairing(
      peer(fpA, addresses: ['10.0.0.1:1'], canShareToUs: true),
      temporary: false,
    );
    expect(first.fingerprint, fpA);
    expect(first.id, hasLength(32));
    expect(first.lastAddresses, ['10.0.0.1:1']);
    expect(first.canShareToUs, isTrue);

    now = now.add(const Duration(hours: 1));
    final second = await repo.saveAfterPairing(
      peer(fpA, name: 'Renamed', platform: '', addresses: ['10.0.0.2:2']),
      temporary: false,
    );
    expect(second.id, first.id);
    expect(second.name, 'Renamed');
    // An empty platform (failed probe) keeps the old one.
    expect(second.platform, 'android');
    expect(second.lastAddresses, ['10.0.0.2:2', '10.0.0.1:1']);
    // canShareToUs stays true once set.
    expect(second.canShareToUs, isTrue);
    expect(second.lastSeenAt, now);
    expect(await repo.all(), hasLength(1));
  });

  test('a new key for the same deviceId makes a second row and leaves the '
      'first untouched', () async {
    final a = await repo.saveAfterPairing(peer(fpA), temporary: false);
    await repo.saveAfterPairing(
      peer(fpB, name: 'Phone A (new)'),
      temporary: false,
    );
    final all = await repo.all();
    expect(all, hasLength(2));
    expect((await repo.byFingerprint(fpA))!.name, a.name);
    expect((await repo.byFingerprint(fpB))!.peerDeviceId, 'dev-a');
  });

  test('temporary rows are hidden from the list but found by fingerprint; '
      'a remembered save clears the flag', () async {
    await repo.saveAfterPairing(peer(fpA), temporary: true);
    await repo.saveAfterPairing(peer(fpB, name: 'B'), temporary: false);
    var visible = await repo.watchVisible().first;
    expect(visible.map((d) => d.fingerprint), [fpB]);
    expect((await repo.byFingerprint(fpA))!.isTemporary, isTrue);

    // A temporary save never makes a remembered row temporary.
    await repo.saveAfterPairing(peer(fpB, name: 'B'), temporary: true);
    expect((await repo.byFingerprint(fpB))!.isTemporary, isFalse);

    await repo.saveAfterPairing(peer(fpA), temporary: false);
    visible = await repo.watchVisible().first;
    expect(visible.map((d) => d.fingerprint).toSet(), {fpA, fpB});
  });

  test(
    'purgeTemporary removes temporary rows older than 7 days only',
    () async {
      await repo.saveAfterPairing(peer(fpA), temporary: true);
      await repo.saveAfterPairing(peer(fpB, name: 'B'), temporary: false);
      now = now.add(const Duration(days: 6));
      expect(await repo.purgeTemporary(), 0);
      now = now.add(const Duration(days: 2));
      expect(await repo.purgeTemporary(), 1);
      expect((await repo.all()).single.fingerprint, fpB);
    },
  );

  test('autoAccept: set on save, kept when not given, toggled', () async {
    await repo.saveAfterPairing(peer(fpA, autoAccept: true), temporary: false);
    await repo.saveAfterPairing(peer(fpA), temporary: false);
    expect((await repo.byFingerprint(fpA))!.autoAccept, isTrue);
    await repo.setAutoAccept(fpA, autoAccept: false);
    expect((await repo.byFingerprint(fpA))!.autoAccept, isFalse);
    // Unknown device: no row appears.
    await repo.setAutoAccept(fpB, autoAccept: true);
    expect(await repo.byFingerprint(fpB), isNull);
  });

  test('touch updates lastSeenAt and keeps at most 3 addresses', () async {
    await repo.saveAfterPairing(
      peer(fpA, addresses: ['a:1', 'b:2', 'c:3']),
      temporary: false,
    );
    now = now.add(const Duration(minutes: 5));
    await repo.touch(fpA, ['d:4']);
    final d = (await repo.byFingerprint(fpA))!;
    expect(d.lastAddresses, ['d:4', 'a:1', 'b:2']);
    expect(d.lastSeenAt, now);
  });

  test('remove / removeAll', () async {
    final a = await repo.saveAfterPairing(peer(fpA), temporary: false);
    await repo.saveAfterPairing(peer(fpB, name: 'B'), temporary: false);
    await repo.remove(a.id);
    expect(await repo.byFingerprint(fpA), isNull);
    await repo.removeAll();
    expect(await repo.all(), isEmpty);
  });

  test('allowedRoots: re-canonicalised, ids recomputed from the salt, '
      'missing folders dropped', () async {
    await repo.saveAfterPairing(peer(fpA), temporary: false);
    await repo.setAllowedRoots(fpA, const [
      SharedRoot(
        id: 'stale-id',
        path: '/sdcard/DCIM',
        label: 'Camera',
        readOnly: true,
      ),
      SharedRoot(
        id: 'x',
        path: '/storage/emulated/0/Gone',
        label: 'Gone',
        readOnly: false,
      ),
    ]);
    final salt = List<int>.filled(32, 7);
    final stored = await repo.allowedRoots(
      fpA,
      salt: salt,
      guard: PathGuard(resolver: (p) async => p),
      exists: (p) async => p == '/storage/emulated/0/DCIM',
    );
    expect(stored.dropped, isTrue);
    final root = stored.roots.single;
    expect(root.path, '/storage/emulated/0/DCIM');
    expect(root.id, PathGuard.rootId(salt, '/storage/emulated/0/DCIM'));
    expect(root.label, 'Camera');
    expect(root.readOnly, isTrue);

    // Nothing stored / unknown device.
    final none = await repo.allowedRoots(
      fpB,
      salt: salt,
      guard: PathGuard(resolver: (p) async => p),
      exists: (_) async => true,
    );
    expect(none.roots, isEmpty);
    expect(none.dropped, isFalse);
  });
}
