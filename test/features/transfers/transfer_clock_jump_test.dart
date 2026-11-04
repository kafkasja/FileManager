import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/features/connect/data/known_devices_dao.dart';
import 'package:kfm/features/connect/domain/known_device.dart';
import 'package:kfm/features/transfers/data/transfers_dao.dart';
import 'package:kfm/features/transfers/domain/transfer_job.dart';

/// Q5: the clock jumps while a transfer file waits for a backoff retry.
void main() {
  final fp = 'cd' * 32;
  final now = DateTime.utc(2026, 11, 4, 12);
  late AppDatabase db;
  late DbWriteQueue queue;
  late TransfersRepository repo;
  late int fileId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    queue = DbWriteQueue();
    repo = TransfersRepository(TransfersDao(db), queue, clock: () => now);
    final device = await KnownDevicesRepository(KnownDevicesDao(db), queue)
        .saveAfterPairing(
          PairedPeer(
            fingerprint: fp,
            peerDeviceId: 'p',
            name: 'Phone',
            platform: 'android',
          ),
          temporary: false,
        );
    final id = await repo.createJob(
      deviceId: device.id,
      direction: TransferDirection.download,
      targetPath: '/dl',
      files: [
        (sourceFileId: 'x', name: 'x', sizeBytes: 9, sourceModifiedAtMs: 0),
      ],
    );
    fileId = (await repo.dao.job(id))!.files.single.id;
  });

  tearDown(() async {
    await queue.close();
    await db.close();
  });

  Future<bool> dueAt(DateTime retryAt, {Duration? cap}) async {
    await (db.update(db.transferFiles)..where((f) => f.id.equals(fileId)))
        .write(TransferFilesCompanion(nextRetryAt: Value(retryAt)));
    final next = await repo.dao.nextQueued(
      fp,
      limit: 5,
      now: now,
      maxRetryWait: cap,
    );
    return next.any((q) => q.file.id == fileId);
  }

  const cap = Duration(seconds: 60);

  test('a normal backoff wait is respected', () async {
    expect(await dueAt(now.add(const Duration(seconds: 30)), cap: cap), false);
    expect(await dueAt(now, cap: cap), isTrue);
    expect(
      await dueAt(now.subtract(const Duration(days: 365)), cap: cap),
      true,
    );
  });

  test('clock went back a day after the retry was scheduled: due now, not '
      'in a day', () async {
    // Scheduled at (now + 1 day) + 8 s, then the clock was set back a day.
    final scheduled = now.add(const Duration(days: 1, seconds: 8));
    expect(await dueAt(scheduled, cap: cap), isTrue);
    // Without the cap (old behaviour) it would wait for the wall clock.
    expect(await dueAt(scheduled), isFalse);
  });

  test('a +1 year jump makes waiting files due at once', () async {
    final scheduledBeforeJump = now.subtract(const Duration(days: 365));
    expect(await dueAt(scheduledBeforeJump, cap: cap), isTrue);
  });
}
