import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/core/db/app_database.dart' show TransferFilesCompanion;
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/domain/known_device.dart';
import 'package:kfm/features/transfers/data/transfer_providers.dart';
import 'package:kfm/features/transfers/domain/transfer_job.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';

import '../../helpers/pump_app.dart';

final String _fp = 'cd' * 32;

void main() {
  testWidgets('Downloads · Uploads; a queued job waits for its device; '
      'Cancel, then Clear finished', (tester) async {
    final app = await pumpApp(tester);
    final repo = app.container.read(transfersRepositoryProvider);
    late String jobId;
    await tester.runAsync(() async {
      final d = await app.container
          .read(knownDevicesRepositoryProvider)
          .saveAfterPairing(
            PairedPeer(
              fingerprint: _fp,
              peerDeviceId: 'p',
              name: 'PC',
              platform: 'windows',
            ),
            temporary: false,
          );
      jobId = await repo.createJob(
        deviceId: d.id,
        direction: TransferDirection.upload,
        targetRootId: 'cam',
        targetPath: '',
        files: [
          (
            sourceFileId: 'path:/x/a.jpg',
            name: 'a.jpg',
            sizeBytes: 2048,
            sourceModifiedAtMs: 0,
          ),
          (
            sourceFileId: 'path:/x/b.jpg',
            name: 'b.jpg',
            sizeBytes: 2048,
            sourceModifiedAtMs: 0,
          ),
        ],
      );
    });

    app.container.read(routerProvider).go(AppRoutes.transfers);
    await tester.pumpAndSettle();
    expect(find.text('Transfers'), findsOneWidget);
    expect(
      find.text(
        'No downloads yet. Select files on a connected device '
        'and tap Download.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Uploads'));
    await tester.pumpAndSettle();
    expect(find.text('To PC'), findsOneWidget);
    expect(find.text('2 files · Waiting for PC'), findsOneWidget);
    expect(find.text('0 B of 4 KB'), findsOneWidget);

    // N10: Pause → "Paused" with Resume; Resume without a connection
    // waits for the device and offers Reconnect (remembered device).
    await tester.tap(find.byKey(ValueKey('transfer-pause-$jobId')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(find.text('2 files · Paused'), findsOneWidget);
    expect(find.byKey(ValueKey('transfer-pause-$jobId')), findsNothing);
    await tester.tap(find.byKey(ValueKey('transfer-resume-$jobId')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(find.text('2 files · Waiting for PC'), findsOneWidget);
    expect(find.text('Reconnect'), findsOneWidget);
    expect(find.text('Resume'), findsNothing);
    expect(find.text('Pause'), findsOneWidget);

    await tester.tap(find.byKey(ValueKey('transfer-cancel-$jobId')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(find.text('2 files · Cancelled'), findsOneWidget);
    expect(find.byKey(ValueKey('transfer-retry-$jobId')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('transfers-clear-finished')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(find.text('To PC'), findsNothing);
    expect(
      find.text('No uploads yet. Select files and tap Send to device.'),
      findsOneWidget,
    );
    // Let the engine's recovery tick find nothing waiting.
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('N11: a move job shows where each original went and offers '
      '"Delete originals" for kept ones', (tester) async {
    final app = await pumpApp(tester);
    final repo = app.container.read(transfersRepositoryProvider);
    late String jobId;
    await tester.runAsync(() async {
      final d = await app.container
          .read(knownDevicesRepositoryProvider)
          .saveAfterPairing(
            PairedPeer(
              fingerprint: _fp,
              peerDeviceId: 'p',
              name: 'PC',
              platform: 'windows',
            ),
            temporary: false,
          );
      jobId = await repo.createJob(
        deviceId: d.id,
        direction: TransferDirection.upload,
        targetRootId: 'cam',
        targetPath: '',
        mode: TransferMode.move,
        deleteMode: DeleteMode.trash,
        files: [
          for (final n in ['a.jpg', 'b.jpg', 'c.jpg'])
            (
              sourceFileId: 'path:/x/$n',
              name: n,
              sizeBytes: 10,
              sourceModifiedAtMs: 0,
            ),
        ],
      );
      final job = (await repo.dao.job(jobId))!;
      final outcomes = [SourceOutcome.trashed, SourceOutcome.keptDeclined];
      for (final (i, f) in job.files.indexed) {
        await repo.setFile(
          f.id,
          jobId,
          TransferFilesCompanion(
            status: Value(
              i < 2 ? TransferFileStatus.done : TransferFileStatus.failed,
            ),
            error: Value(i < 2 ? null : TransferErrors.verificationFailed),
            receiverSha256: Value(i < 2 ? 'a' * 64 : null),
            sourceOutcome: Value(i < 2 ? outcomes[i] : null),
          ),
        );
      }
    });

    app.container.read(routerProvider).go(AppRoutes.transfers);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uploads'));
    await tester.pumpAndSettle();
    expect(find.text('Moving to PC'), findsOneWidget);
    expect(
      find.byKey(ValueKey('transfer-delete-originals-$jobId')),
      findsOneWidget,
    );
    await tester.tap(find.text('Moving to PC'));
    await tester.pumpAndSettle();
    expect(find.text('Verified · original moved to trash'), findsOneWidget);
    expect(
      find.text('Verified · original kept (you declined)'),
      findsOneWidget,
    );
    expect(find.text('Verification failed. Original kept.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('Q8: a copy whose bytes are all there shows "Checking…" '
      '(a move "Verifying…")', (tester) async {
    final app = await pumpApp(tester);
    final repo = app.container.read(transfersRepositoryProvider);
    await tester.runAsync(() async {
      final d = await app.container
          .read(knownDevicesRepositoryProvider)
          .saveAfterPairing(
            PairedPeer(
              fingerprint: _fp,
              peerDeviceId: 'p',
              name: 'PC',
              platform: 'windows',
            ),
            temporary: false,
          );
      for (final mode in TransferMode.values) {
        final jobId = await repo.createJob(
          deviceId: d.id,
          direction: TransferDirection.upload,
          targetRootId: 'cam',
          targetPath: '',
          mode: mode,
          deleteMode: DeleteMode.trash,
          files: [
            (
              sourceFileId: 'path:/x/${mode.name}.bin',
              name: '${mode.name}.bin',
              sizeBytes: 10,
              sourceModifiedAtMs: 0,
            ),
          ],
        );
        final f = (await repo.dao.job(jobId))!.files.single;
        await repo.setFile(
          f.id,
          jobId,
          const TransferFilesCompanion(
            status: Value(TransferFileStatus.verifying),
            bytesDone: Value(10),
          ),
        );
      }
    });

    app.container.read(routerProvider).go(AppRoutes.transfers);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uploads'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('To PC'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Moving to PC'));
    await tester.pumpAndSettle();
    expect(find.text('Checking…'), findsWidgets);
    expect(find.text('Verifying…'), findsWidgets);
    await tester.pump(const Duration(seconds: 6));
  });
}
