import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/app.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/core/thumbs/thumbnail_cache.dart';
import 'package:kfm/features/swipe/ui/video_controller_pool.dart';

import '../core/files/fake_file_source.dart';
import '../core/platform/permissions/fake_permission_service.dart';
import '../features/swipe/fake_video.dart';

/// The whole app on an in-memory database and a fake permission service.
class TestApp {
  new _(this.container, this.db, this.permissions, this.files);

  final ProviderContainer container;
  final AppDatabase db;
  final FakePermissionService permissions;
  final FakeFileSource files;
}

Future<TestApp> pumpApp(
  WidgetTester tester, {
  FakePermissionService? permissions,
  FakeFileSource? files,
  FakeVideoFactory? videos,
}) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final db = AppDatabase(NativeDatabase.memory());
  final service = permissions ?? FakePermissionService();
  final fileSource = files ?? FakeFileSource();
  final thumbDir = Directory.systemTemp.createTempSync('kfm_app_thumbs');
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      permissionServiceProvider.overrideWithValue(service),
      fileSourceProvider.overrideWithValue(fileSource),
      videoHandleFactoryProvider.overrideWithValue(
        (videos ?? FakeVideoFactory()).call,
      ),
      thumbnailCacheProvider.overrideWith(
        (ref) async => DiskThumbnailCache(
          dir: thumbDir,
          generator: (_, _) async => null,
          maxDiskBytes: () async => 1 << 20,
        ),
      ),
    ],
  );
  addTearDown(() async {
    // Unmount first so no widget listens while providers are disposed.
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await db.close();
    await fileSource.dispose();
    thumbDir.deleteSync(recursive: true);
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const App()),
  );
  await tester.pumpAndSettle();
  return TestApp._(container, db, service, fileSource);
}
