import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/domain/known_device.dart';
import 'package:kfm/features/transfers/data/transfer_providers.dart';
import 'package:kfm/features/transfers/domain/transfer_job.dart';

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
  });
}
