import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/platform/permissions/storage_access.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';

import 'fake_permission_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakePermissionService service;
  late ProviderContainer container;

  setUp(() {
    service = FakePermissionService(
      grantedAccess.copyWith(media: MediaAccess.unknown),
    );
    container = ProviderContainer(
      overrides: [permissionServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
  });

  test('build checks the current access', () async {
    final access = await container.read(storageAccessControllerProvider.future);
    expect(access.media, MediaAccess.unknown);
    expect(access.canUseSwipe, isFalse);
  });

  test('requestMedia updates the state', () async {
    await container.read(storageAccessControllerProvider.future);
    service.onRequest = MediaAccess.limited;
    await container
        .read(storageAccessControllerProvider.notifier)
        .requestMedia();
    final access = container.read(storageAccessControllerProvider).value!;
    expect(access.media, MediaAccess.limited);
    expect(access.canUseSwipe, isTrue);
  });

  test('errors propagate to the state, never swallowed', () async {
    service.checkError = StateError('boom');
    await expectLater(
      container.read(storageAccessControllerProvider.future),
      throwsStateError,
    );
    expect(container.read(storageAccessControllerProvider).hasError, isTrue);
  });

  test('recheck reads the new access', () async {
    await container.read(storageAccessControllerProvider.future);
    service.current = grantedAccess;
    final access = await container
        .read(storageAccessControllerProvider.notifier)
        .recheck();
    expect(access, grantedAccess);
  });

  test('canSeeAllFiles needs media access and All files access', () {
    expect(grantedAccess.canSeeAllFiles, isTrue);
    expect(
      grantedAccess
          .copyWith(allFiles: AllFilesAccess.notGranted)
          .canSeeAllFiles,
      isFalse,
    );
    expect(
      grantedAccess
          .copyWith(allFiles: AllFilesAccess.notRequired)
          .canSeeAllFiles,
      isTrue,
    );
    expect(
      grantedAccess.copyWith(media: MediaAccess.denied).canSeeAllFiles,
      isFalse,
    );
  });
}
