import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:kfm/app/theme/app_theme.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/features/browse/ui/widgets/file_actions_menu.dart';
import 'package:kfm/features/privacy/data/copying_location_stripper.dart';
import 'package:kfm/features/privacy/data/privacy_providers.dart';
import 'package:kfm/features/privacy/ui/move_warning_dialog.dart';
import 'package:kfm/features/privacy/ui/privacy_settings_section.dart';
import 'package:kfm/features/privacy/ui/share_flow.dart';
import 'package:kfm/features/selection/ui/selection_actions.dart';
import 'package:kfm/features/settings/ui/settings_sections.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

import '../../core/platform/permissions/fake_permission_service.dart';
import 'location_fixtures.dart';

FileRef _ref(File f, {FileKind kind = FileKind.image, String? mime}) => FileRef(
  id: 'path:${f.path}',
  uri: f.path,
  name: f.uri.pathSegments.last,
  kind: kind,
  mimeType: mime,
  sizeBytes: f.lengthSync(),
  modifiedAt: DateTime.utc(2026, 11, 2),
  folderPath: f.parent.path,
  origin: FileOrigin.local,
);

class _Harness {
  new(this.container, this.db, this.permissions, this.shared);

  final ProviderContainer container;
  final AppDatabase db;
  final FakePermissionService permissions;
  final List<List<Map<String, String?>>> shared;
}

Future<_Harness> _pump(
  WidgetTester tester,
  Widget Function(WidgetRef ref) body, {
  Directory? root,
  bool mediaLocation = true,
}) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final db = AppDatabase(NativeDatabase.memory());
  final permissions = FakePermissionService()..mediaLocation = mediaLocation;
  final shared = <List<Map<String, String?>>>[];
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      permissionServiceProvider.overrideWithValue(permissions),
      shareSheetProvider.overrideWithValue((items) async {
        shared.add(items);
        return true;
      }),
      if (root != null)
        locationStripperProvider.overrideWithValue(
          CopyingLocationStripper(
            root: () async => root,
            copy: (f, out) => File(f.path).copy(out),
          ),
        ),
    ],
  );
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await db.close();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildTheme(Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Consumer(builder: (context, ref, _) => body(ref))),
      ),
    ),
  );
  await _settle(tester);
  return _Harness(container, db, permissions, shared);
}

/// Lets real I/O (drift, isolates, files) finish between frames.
Future<void> _settle(WidgetTester tester, {bool Function()? until}) async {
  for (var i = 0; i < 40; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    if (until == null ? i >= 2 : until()) break;
  }
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('kfm_privacy_ui_'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('Privacy section, Share menu item and selection action are '
      'registered', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(
      [
        for (final s in container.read(settingsSectionsProvider))
          for (final e in s.entries) e.id,
      ].where((id) => id == 'privacy.location').length,
      1,
    );
    expect(container.read(fileMenuItemsProvider), contains(shareFileMenuItem));
    expect(
      container.read(selectionActionsProvider).map((a) => a.id),
      contains('x2.share'),
    );
  });

  group('Privacy section', () {
    testWidgets('the switch writes the setting; off by default', (
      tester,
    ) async {
      final h = await _pump(tester, (_) => const PrivacySettingsSection());
      final finder = find.byKey(const ValueKey('privacy-strip-location'));
      expect(tester.widget<SwitchListTile>(finder).value, isFalse);
      expect(find.text('Remove location when sharing'), findsOneWidget);
      // Location access granted: no access row.
      expect(find.text('Allow access to photo locations'), findsNothing);

      await tester.tap(finder);
      await _settle(tester);

      expect(
        await tester.runAsync(
          () => h.container
              .read(settingsRepositoryProvider)
              .read(AppSettings.privacyStripLocation),
        ),
        isTrue,
      );
      expect(tester.widget<SwitchListTile>(finder).value, isTrue);
    });

    testWidgets('without location access: the note and the access row', (
      tester,
    ) async {
      final h = await _pump(
        tester,
        (_) => const PrivacySettingsSection(),
        mediaLocation: false,
      );
      await tester.tap(find.byKey(const ValueKey('privacy-strip-location')));
      await _settle(tester);
      expect(find.text('Allow access to photo locations'), findsOneWidget);
      expect(
        find.text(
          "KFM can't read the original location of your photos; they're "
          'sent without it anyway.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Allow access to photo locations'));
      await _settle(tester);
      expect(h.permissions.calls, contains('requestMediaLocation'));
      expect(find.text('Allow access to photo locations'), findsNothing);
    });
  });

  group('Share', () {
    late File photo;
    late File doc;
    late Directory root;

    setUp(() {
      photo = writeTemp(dir, 'IMG_1.jpg', jpegWithGps());
      doc = writeTemp(dir, 'notes.txt', [1, 2, 3]);
      root = Directory('${dir.path}/privacy');
    });

    Widget button(WidgetRef ref, List<FileRef> files) => Builder(
      builder: (context) => TextButton(
        onPressed: () => unawaited(shareFiles(context, ref, files)),
        child: const Text('go'),
      ),
    );

    testWidgets('switch on (from the setting): a copy without location; '
        'other files as they are', (tester) async {
      final files = [
        _ref(photo, mime: 'image/jpeg'),
        _ref(doc, kind: FileKind.document, mime: 'text/plain'),
      ];
      final h = await _pump(tester, (ref) => button(ref, files), root: root);
      await tester.runAsync(
        () => h.container
            .read(settingsRepositoryProvider)
            .write(AppSettings.privacyStripLocation, true),
      );
      await tester.tap(find.text('go'));
      await _settle(tester);

      expect(find.text('Share 2 files'), findsOneWidget);
      final toggle = find.byKey(const ValueKey('share-remove-location'));
      expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
      await tester.tap(find.byKey(const ValueKey('share-confirm')));
      await _settle(tester, until: () => h.shared.isNotEmpty);

      expect(h.shared, hasLength(1));
      final items = h.shared.single;
      expect(items, hasLength(2));
      final copy = items[0]['path']!;
      expect(copy, startsWith(root.path));
      expect(items[0]['mime'], 'image/jpeg');
      final bytes = File(copy).readAsBytesSync();
      expect(img.decodeJpgExif(bytes)!.gpsIfd.hasGPSLatitude, isFalse);
      expect(items[1], {'path': doc.path, 'mime': 'text/plain'});
      // The original keeps its location.
      expect(
        img.decodeJpgExif(photo.readAsBytesSync())!.gpsIfd.hasGPSLatitude,
        isTrue,
      );
    });

    testWidgets('switch off: the originals are shared', (tester) async {
      final h = await _pump(
        tester,
        (ref) => button(ref, [_ref(photo)]),
        root: root,
      );
      await tester.tap(find.text('go'));
      await _settle(tester);
      expect(find.text('Share 1 file'), findsOneWidget);
      final toggle = find.byKey(const ValueKey('share-remove-location'));
      expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
      await tester.tap(find.byKey(const ValueKey('share-confirm')));
      await _settle(tester, until: () => h.shared.isNotEmpty);
      expect(h.shared.single.single['path'], photo.path);
      expect(root.existsSync(), isFalse);
    });

    testWidgets('no photos or videos: no sheet', (tester) async {
      final h = await _pump(
        tester,
        (ref) => button(ref, [_ref(doc, kind: FileKind.document)]),
        root: root,
      );
      await tester.tap(find.text('go'));
      await _settle(tester, until: () => h.shared.isNotEmpty);
      expect(find.byKey(const ValueKey('share-confirm')), findsNothing);
      expect(h.shared.single.single['path'], doc.path);
    });

    testWidgets('a photo whose location stays is not shared; the dialog '
        'names it', (tester) async {
      final jpeg = plainJpeg();
      final comment = 'GPSLatitude 52.37'.codeUnits;
      final bad = writeTemp(dir, 'bad.jpg', [
        0xFF, 0xD8, 0xFF, 0xFE, 0, comment.length + 2, ...comment, //
        ...jpeg.sublist(2),
      ]);
      final h = await _pump(
        tester,
        (ref) => button(ref, [_ref(bad), _ref(photo)]),
        root: root,
      );
      await tester.tap(find.text('go'));
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('share-remove-location')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('share-confirm')));
      await _settle(
        tester,
        until: () => find
            .byType(AlertDialog)
            .evaluate()
            .any(
              (e) => find
                  .descendant(
                    of: find.byWidget(e.widget),
                    matching: find.text('OK'),
                  )
                  .evaluate()
                  .isNotEmpty,
            ),
      );

      expect(
        find.text(
          "Location couldn't be removed from 1 file, so it wasn't shared",
        ),
        findsOneWidget,
      );
      expect(
        find.text('bad.jpg: location info was still found after removing it'),
        findsOneWidget,
      );
      expect(h.shared, isEmpty);
      await tester.tap(find.text('OK'));
      await _settle(tester, until: () => h.shared.isNotEmpty);
      final items = h.shared.single;
      expect(items, hasLength(1));
      expect(items.single['path'], endsWith('IMG_1.jpg'));
      expect(items.single['path'], startsWith(root.path));
    });
  });

  testWidgets('move warning: Copy instead, Move anyway, Cancel', (
    tester,
  ) async {
    final results = <LocationMoveChoice?>[];
    await _pump(
      tester,
      (_) => Builder(
        builder: (context) => TextButton(
          onPressed: () async =>
              results.add(await showLocationMoveWarning(context)),
          child: const Text('move'),
        ),
      ),
    );
    for (final label in ['Copy instead', 'Move anyway', 'Cancel']) {
      await tester.tap(find.text('move'));
      await tester.pumpAndSettle();
      expect(find.text('Move without location?'), findsOneWidget);
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }
    expect(results, [
      LocationMoveChoice.copyInstead,
      LocationMoveChoice.moveAnyway,
      null,
    ]);
  });
}
