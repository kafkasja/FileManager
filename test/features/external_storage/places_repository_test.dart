import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/db/settings/settings_repository.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/platform/permissions/storage_access.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/core/platform/volumes/mtp_channel.dart';
import 'package:kfm/core/platform/volumes/volumes_channel.dart';
import 'package:kfm/core/platform/volumes/volumes_providers.dart';
import 'package:kfm/features/external_storage/data/places_repository.dart';
import 'package:kfm/features/external_storage/data/places_watcher.dart';
import 'package:kfm/features/external_storage/data/saf_grants.dart';
import 'package:kfm/features/external_storage/domain/storage_place.dart';

import '../../core/index/media_index_dao_test.dart' show ref;
import '../../core/platform/permissions/fake_permission_service.dart';
import 'fake_volumes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('watchDeviceStorage', () {
    late FakeVolumes volumes;
    setUp(() => volumes = FakeVolumes());
    tearDown(() => volumes.close());

    test('lists on listen, re-lists after attach and detach', () async {
      final seen = <DeviceStorage>[];
      final sub = watchDeviceStorage(
        volumes,
        null,
        debounce: const Duration(milliseconds: 20),
      ).listen(seen.add);
      addTearDown(sub.cancel);
      await pumpEventQueue();
      expect(seen.single.volumes, [internalVolume]);

      volumes
        ..volumes = [internalVolume, sdVolume()]
        ..emit(const VolumeStateChanged(uuid: '1234-ABCD', state: 'mounted'));
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(seen.last.volumes, hasLength(2));

      volumes
        ..volumes = [internalVolume]
        ..emit(const VolumeStateChanged(uuid: '1234-ABCD', state: 'removed'));
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(seen.last.volumes, [internalVolume]);
    });

    test('a flapping cable is read once (debounce)', () async {
      final sub = watchDeviceStorage(
        volumes,
        null,
        debounce: const Duration(milliseconds: 50),
      ).listen((_) {});
      addTearDown(sub.cancel);
      await pumpEventQueue();
      final before = volumes.listCalls;
      for (var i = 0; i < 5; i++) {
        volumes.emit(VolumeStateChanged(uuid: 'X', state: '$i'));
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(volumes.listCalls - before, 1);
    });

    test('refresh requests (file ops, local jobs) re-read free space once, '
        'debounced', () async {
      final refresh = PlacesSpaceRefresh();
      addTearDown(refresh.dispose);
      final seen = <DeviceStorage>[];
      final sub = watchDeviceStorage(
        volumes,
        null,
        debounce: const Duration(milliseconds: 50),
        refreshes: refresh.requests,
      ).listen(seen.add);
      addTearDown(sub.cancel);
      await pumpEventQueue();
      final before = volumes.listCalls;
      volumes.volumes = [internalVolume, sdVolume().copyFree(1 << 30)];
      refresh
        ..request()
        ..request()
        ..request();
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(volumes.listCalls - before, 1);
      expect(seen.last.volumes.last.freeBytes, 1 << 30);
    });

    test(
      'a failed read is an error event; the next event reads again',
      () async {
        final errors = <Object>[];
        final seen = <DeviceStorage>[];
        volumes.listError = StateError('boom');
        final sub = watchDeviceStorage(
          volumes,
          null,
          debounce: const Duration(milliseconds: 10),
        ).listen(seen.add, onError: errors.add);
        addTearDown(sub.cancel);
        await pumpEventQueue();
        expect(errors, hasLength(1));
        volumes
          ..listError = null
          ..emit(const VolumeStateChanged(uuid: null, state: 'mounted'));
        await Future<void>.delayed(const Duration(milliseconds: 40));
        expect(seen, hasLength(1));
      },
    );

    test('camera changes re-list too', () async {
      final mtp = FakeMtp();
      final seen = <DeviceStorage>[];
      final sub = watchDeviceStorage(
        volumes,
        mtp,
        debounce: const Duration(milliseconds: 10),
      ).listen(seen.add);
      addTearDown(sub.cancel);
      await pumpEventQueue();
      mtp
        ..cameras = [const UsbCamera(deviceName: 'd', hasPermission: true)]
        ..changed();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(seen.last.cameras, hasLength(1));
    });
  });

  group('placesProvider', () {
    late AppDatabase db;
    late FakeVolumes volumes;
    late FakePermissionService permissions;
    late ProviderContainer container;

    setUp(() {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      db = AppDatabase(NativeDatabase.memory());
      volumes = FakeVolumes([internalVolume, sdVolume()]);
      permissions = FakePermissionService();
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          permissionServiceProvider.overrideWithValue(permissions),
          volumesPlatformProvider.overrideWithValue(volumes),
          mtpPlatformProvider.overrideWithValue(null),
        ],
      );
    });
    tearDown(() async {
      container.dispose();
      await volumes.close();
      await db.close();
    });

    Future<List<StoragePlace>> places() async {
      final sub = container.listen(placesProvider, (_, _) {});
      addTearDown(sub.close);
      await pumpEventQueue();
      return await container.read(placesProvider.future);
    }

    test('All files access flipping changes the access method', () async {
      expect((await places())[1].access, AccessMethod.directPath);
      permissions.current = permissions.current.copyWith(
        allFiles: AllFilesAccess.notGranted,
      );
      await container.read(storageAccessControllerProvider.notifier).recheck();
      await pumpEventQueue();
      expect((await places())[1].access, AccessMethod.saf);
    });

    test('a saved grant shows up; a lost one goes', () async {
      permissions.current = permissions.current.copyWith(
        allFiles: AllFilesAccess.notGranted,
      );
      expect((await places())[1].needsGrant, isTrue);
      final settings = container.read(settingsRepositoryProvider);
      await settings.write(AppSettings.externalSafGrants, {'1234-ABCD': 't'});
      await pumpEventQueue();
      expect((await places())[1].treeUri, 't');
      await settings.write(AppSettings.externalSafGrants, <String, String>{});
      await pumpEventQueue();
      expect((await places())[1].needsGrant, isTrue);
    });

    test('unmountedRoots: indexed roots that went away', () async {
      final sub = container.listen(unmountedRootsProvider, (_, _) {});
      addTearDown(sub.close);
      await container.read(mediaIndexDaoProvider).upsertBatch([
        ref(1, folder: '/storage/1234-ABCD/DCIM'),
      ], 1);
      expect(await container.read(unmountedRootsProvider.future), isEmpty);
      volumes
        ..volumes = [internalVolume, sdVolume(mounted: false)]
        ..emit(const VolumeStateChanged(uuid: '1234-ABCD', state: 'removed'));
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      expect(await container.read(unmountedRootsProvider.future), {
        '/storage/1234-ABCD',
      });
    });

    test(
      'pendingFolderRoots: internal plus mounted direct-path roots',
      () async {
        await places();
        final roots = await container
            .read(_rootsProvider.future)
            .timeout(const Duration(seconds: 5));
        expect(roots, ['/storage/emulated/0', '/storage/1234-ABCD']);
      },
    );
  });

  group('PlacesWatcher', () {
    late List<String> scanned;
    late List<String> dropped;
    late bool grantValid;
    late PlacesWatcher watcher;
    late List<ExternalNotice> notices;

    setUp(() {
      scanned = [];
      dropped = [];
      grantValid = true;
      notices = [];
      watcher = PlacesWatcher(
        scanRoot: (r) async => scanned.add(r),
        validateGrant: (_) async => grantValid,
        dropGrant: (u) async => dropped.add(u),
        formatHelpDelay: const Duration(milliseconds: 30),
        rescanDelay: const Duration(milliseconds: 30),
      );
      watcher.notices.listen(notices.add);
    });
    tearDown(() => watcher.dispose());

    List<StoragePlace> placesWith(List<VolumeInfo> v, {String? grant}) =>
        buildPlaces(
          volumes: v,
          cameras: const [],
          safGrants: {'1234-ABCD': ?grant},
          canSeeAllFiles: grant == null,
          sdkInt: 34,
        );

    test('baseline is quiet; attach notifies and scans twice', () async {
      watcher.onPlaces(placesWith([internalVolume, sdVolume()]));
      await pumpEventQueue();
      expect(notices, isEmpty);
      expect(scanned, isEmpty);

      watcher
        ..onPlaces(placesWith([internalVolume]))
        ..onPlaces(placesWith([internalVolume, sdVolume()]));
      await pumpEventQueue();
      expect(notices.map((n) => n.runtimeType), [PlaceRemoved, PlaceAttached]);
      expect(
        (notices.first as PlaceRemoved).place.rootPath,
        '/storage/1234-ABCD',
      );
      expect(scanned, ['/storage/1234-ABCD']);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(scanned, ['/storage/1234-ABCD', '/storage/1234-ABCD']);
    });

    test('U2 (h): the baseline walks mounted direct-path places if stale; '
        'SAF and internal ones are left alone', () async {
      final walks = <(String, DateTime?)>[];
      final mount = DateTime.utc(2026, 11, 3, 9);
      final w = PlacesWatcher(
        scanRoot: (r) async => scanned.add(r),
        walkIfStale: (r, at) async => walks.add((r, at)),
      );
      addTearDown(w.dispose);
      w.onPlaces(placesWith([internalVolume, sdVolume(mountedAt: mount)]));
      await pumpEventQueue();
      expect(walks, [('/storage/1234-ABCD', mount)]);
      expect(scanned, isEmpty);
      // Later lists don't walk again (attach uses scanRoot).
      w.onPlaces(placesWith([internalVolume, sdVolume(mountedAt: mount)]));
      await pumpEventQueue();
      expect(walks, hasLength(1));

      final saf = PlacesWatcher(
        scanRoot: (r) async => scanned.add(r),
        walkIfStale: (r, at) async => walks.add((r, at)),
      );
      addTearDown(saf.dispose);
      saf.onPlaces(placesWith([internalVolume, sdVolume()], grant: 't'));
      await pumpEventQueue();
      expect(walks, hasLength(1));
    });

    test('a remounted volume with an invalid grant loses it', () async {
      watcher.onPlaces(placesWith([internalVolume], grant: 't'));
      grantValid = false;
      watcher.onPlaces(placesWith([internalVolume, sdVolume()], grant: 't'));
      await pumpEventQueue();
      expect(dropped, ['1234-ABCD']);
    });

    test('USB stick without a volume → format help', () async {
      watcher
        ..onPlaces(placesWith([internalVolume]))
        ..onUsbMassStorage();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(notices.single, isA<UsbFormatHelp>());
    });

    test('USB stick that mounts → no format help', () async {
      watcher
        ..onPlaces(placesWith([internalVolume]))
        ..onUsbMassStorage()
        ..onPlaces(placesWith([internalVolume, sdVolume()]));
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(notices.whereType<UsbFormatHelp>(), isEmpty);
    });
  });

  group('SafGrants', () {
    late AppDatabase db;
    late DbWriteQueue queue;
    late SettingsRepository settings;
    late FakeSafTrees trees;
    late SafGrants grants;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      queue = DbWriteQueue();
      settings = SettingsRepository(db, queue);
      trees = FakeSafTrees();
      grants = SafGrants(trees, settings);
    });
    tearDown(() async {
      await queue.close();
      await db.close();
    });

    test('the volume root is persisted and saved', () async {
      trees.nextPick = (uri: 'tree1', treeDocumentId: '1234-ABCD:');
      expect(await grants.grant('1234-ABCD'), GrantOutcome.granted);
      expect(trees.persisted, {'tree1'});
      expect(await settings.read(AppSettings.externalSafGrants), {
        '1234-ABCD': 'tree1',
      });
      expect(await grants.isValid('tree1'), isTrue);
    });

    test('a subfolder is refused: nothing persisted or saved', () async {
      trees.nextPick = (uri: 'tree2', treeDocumentId: '1234-ABCD:DCIM');
      expect(await grants.grant('1234-ABCD'), GrantOutcome.wrongFolder);
      expect(trees.persisted, isEmpty);
      expect(await settings.read(AppSettings.externalSafGrants), isEmpty);
    });

    test('cancel and refused persist save nothing', () async {
      expect(await grants.grant('1234-ABCD'), GrantOutcome.cancelled);
      trees
        ..nextPick = (uri: 't', treeDocumentId: '1234-ABCD:')
        ..persistWorks = false;
      expect(await grants.grant('1234-ABCD'), GrantOutcome.failed);
      expect(await settings.read(AppSettings.externalSafGrants), isEmpty);
    });

    test('a reformatted stick fails validation; drop releases', () async {
      trees.nextPick = (uri: 'tree1', treeDocumentId: '1234-ABCD:');
      await grants.grant('1234-ABCD');
      trees.rootValid = false;
      expect(await grants.isValid('tree1'), isFalse);
      await grants.drop('1234-ABCD');
      expect(trees.calls, contains('release tree1'));
      expect(await settings.read(AppSettings.externalSafGrants), isEmpty);
    });
  });
}

final _rootsProvider = FutureProvider<List<String>>(
  (ref) => pendingFolderRoots(ref, primaryRoot: '/storage/emulated/0'),
);

extension on VolumeInfo {
  VolumeInfo copyFree(int free) => VolumeInfo(
    uuid: uuid,
    isPrimary: isPrimary,
    isRemovable: isRemovable,
    description: description,
    state: state,
    isMounted: isMounted,
    rootPath: rootPath,
    totalBytes: totalBytes,
    freeBytes: free,
  );
}
