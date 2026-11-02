import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/platform/permissions/storage_access.dart';
import 'package:kfm/features/share_in/data/share_in_channel.dart';
import 'package:kfm/features/share_in/data/share_in_service.dart';
import 'package:kfm/features/share_in/ui/shared_files_screen.dart';
import 'package:kfm/features/swipe/ui/swipe_screen.dart';

import '../../core/files/fake_file_source.dart';
import '../../core/platform/permissions/fake_permission_service.dart';
import '../../helpers/pump_app.dart';
import 'share_in_service_test.dart' show FakeShareInPlatform;

void main() {
  testWidgets(
    'a share during the permission gate opens the Shared screen after it',
    (tester) async {
      final files = FakeFileSource();
      final a = files.addFile('/storage/emulated/0/DCIM/a.jpg');
      final copy = files.addFile(
        '/data/user/0/com.kaf.kfm/files/shared_in/1000/b.jpg',
      );
      final platform = FakeShareInPlatform()
        ..pending = {
          'id': 'share-1000',
          'receivedAtMs': 1000,
          'items': [
            {'kind': 'copy', 'path': a.path},
            {'kind': 'copy', 'path': copy.path},
          ],
          'notFiles': false,
        };
      addTearDown(platform.controller.close);
      final permissions = FakePermissionService(
        grantedAccess.copyWith(media: MediaAccess.unknown),
      );
      await pumpApp(
        tester,
        permissions: permissions,
        files: files,
        overrides: [shareInPlatformProvider.overrideWithValue(platform)],
      );
      expect(find.byType(SharedFilesScreen), findsNothing);

      await tester.tap(find.text('Allow'));
      await tester.pumpAndSettle();
      expect(find.byType(SharedFilesScreen), findsOneWidget);
      expect(find.text('2 shared files'), findsOneWidget);
      expect(find.text('Swipe through them'), findsOneWidget);
      // b.jpg is KFM's copy: the note says deleting it removes KFM's copy.
      expect(find.textContaining('removed from KFM'), findsOneWidget);

      // Back returns to the deck; the batch is forgotten.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(SwipeScreen), findsOneWidget);
    },
  );

  testWidgets('text only shows a hint, no screen', (tester) async {
    final platform = FakeShareInPlatform();
    addTearDown(platform.controller.close);
    final app = await pumpApp(
      tester,
      overrides: [shareInPlatformProvider.overrideWithValue(platform)],
    );
    platform.pending = {
      'id': 'share-2',
      'receivedAtMs': 2,
      'items': <Object?>[],
      'notFiles': true,
    };
    platform.controller.add(const ShareInReady('share-2'));
    await tester.pumpAndSettle();
    expect(find.byType(SharedFilesScreen), findsNothing);
    expect(find.text('Only files can be shared into KFM'), findsOneWidget);
    expect(app.container.read(pendingSharedBatchProvider).batchId, isNull);
    await tester.pump(const Duration(seconds: 5));
  });
}
