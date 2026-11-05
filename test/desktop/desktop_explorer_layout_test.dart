import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/desktop/browse/desktop_browse_controller.dart';
import 'package:kfm/desktop/shell/desktop_address_bar.dart';
import 'package:kfm/desktop/shell/desktop_location.dart';
import 'package:kfm/desktop/shell/desktop_status_bar.dart';
import 'package:kfm/desktop/tabs/desktop_tabs_controller.dart';
import 'package:kfm/features/external_storage/data/places_repository.dart';
import 'package:kfm/features/external_storage/domain/storage_place.dart';

import '../core/files/fake_file_source.dart';
import '../helpers/pump_app.dart';
import 'desktop_helpers.dart';

FakeFileSource _library() {
  final files = FakeFileSource();
  for (final (i, name) in ['a.jpg', 'b.jpg'].indexed) {
    files.addFile('/s/DCIM/$name', modifiedAt: DateTime.utc(2025, 1, 1, 0, i));
  }
  files
    ..addFile('/s/DCIM/Trip/t.jpg', modifiedAt: DateTime.utc(2025))
    ..addFile('/s/Other/o.jpg', modifiedAt: DateTime.utc(2025));
  return files;
}

StoragePlace _drive({required int free, int total = 1000}) => StoragePlace(
  id: kInternalPlaceId,
  label: '',
  kind: PlaceKind.internal,
  access: AccessMethod.directPath,
  isMounted: true,
  rootPath: '/s',
  totalBytes: total,
  freeBytes: free,
);

Future<void> _ctrl(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool shift = false,
}) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(key);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
}

DesktopTabsState _tabs(TestApp app) =>
    app.container.read(desktopTabsControllerProvider);

void main() {
  testWidgets('Ctrl+T opens Home, Ctrl+W and middle-click close, '
      'Ctrl+Shift+T reopens', (tester) async {
    final app = await pumpDesktopApp(tester, files: _library());
    expect(_tabs(app).tabs, hasLength(1));
    await _ctrl(tester, LogicalKeyboardKey.keyT);
    expect(_tabs(app).tabs.map((t) => t.location), const [
      SortLocation(),
      HomeLocation(),
    ]);
    expect(_tabs(app).active, 1);
    await _ctrl(tester, LogicalKeyboardKey.keyW);
    expect(_tabs(app).tabs, hasLength(1));
    await _ctrl(tester, LogicalKeyboardKey.keyT, shift: true);
    expect(_tabs(app).tabs, hasLength(2));
    // Middle-click on the Home tab closes it.
    final home = find.text('Home').first;
    await tester.tap(home, buttons: kMiddleMouseButton);
    await tester.pumpAndSettle();
    expect(_tabs(app).tabs.map((t) => t.location), const [SortLocation()]);
    // The + button and a double-click on the empty strip open tabs.
    await tester.tap(find.byKey(const ValueKey('desktop-tab-new')));
    await tester.pumpAndSettle();
    expect(_tabs(app).tabs, hasLength(2));
  });

  testWidgets('a nav pane click navigates the tab; Back returns', (
    tester,
  ) async {
    final app = await pumpDesktopApp(tester, files: _library());
    await tester.tap(find.byKey(const ValueKey('desktop-nav-browse')));
    await tester.pumpAndSettle();
    expect(_tabs(app).current.location, const HomeLocation());
    expect(_tabs(app).tabs, hasLength(1));
    await tester.tap(find.byKey(const ValueKey('browse-back')));
    await tester.pumpAndSettle();
    expect(_tabs(app).current.location, const SortLocation());
  });

  testWidgets('holding a drag over a tab switches to it; dropping on a '
      'folder tab moves the file there', (tester) async {
    final app = await pumpDesktopApp(tester, files: _library());
    final tabs = app.container.read(desktopTabsControllerProvider.notifier)
      ..navigate(const FolderLocation('/s/Other'))
      ..openInNewTab(const FolderLocation('/s/DCIM'));
    await tester.pumpAndSettle();
    expect(find.text('a.jpg'), findsOneWidget);
    final start = tester.getCenter(find.text('a.jpg'));
    final tab = tester.getCenter(find.text('Other').first);
    final g = await tester.startGesture(start, kind: PointerDeviceKind.mouse);
    for (var i = 1; i <= 8; i++) {
      await g.moveTo(Offset.lerp(start, tab, i / 8)!);
      await tester.pump();
    }
    expect(_tabs(app).active, 1);
    await tester.pump(const Duration(milliseconds: 700));
    // 0.6 s over the tab: it is the active one now.
    expect(_tabs(app).active, 0);
    await g.up();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect({
      for (final f in app.files.files) f.path,
    }, contains('/s/Other/a.jpg'));
    tabs.activate(1);
  });

  group('address bar', () {
    testWidgets('a typed folder opens; %VAR% expands; Esc restores', (
      tester,
    ) async {
      final app = await pumpDesktopApp(
        tester,
        files: _library(),
        overrides: [
          desktopEnvironmentProvider.overrideWithValue({'KFMROOT': '/s'}),
          desktopPathKindProvider.overrideWithValue(
            (p) async => p == '/s/DCIM' || p == '/s'
                ? TypedPathKind.folder
                : p == '/s/DCIM/a.jpg'
                ? TypedPathKind.file
                : TypedPathKind.missing,
          ),
        ],
      );
      await tester.tap(find.byKey(const ValueKey('desktop-address-crumbs')));
      await tester.pumpAndSettle();
      final field = find.byKey(const ValueKey('desktop-address-field'));
      expect(field, findsOneWidget);
      await tester.enterText(field, r'"%KFMROOT%\DCIM\"');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(_tabs(app).current.location, const FolderLocation('/s/DCIM'));
      expect(field, findsNothing);

      // A missing path: inline error, no navigation.
      await tester.tap(find.byKey(const ValueKey('desktop-address-crumbs')));
      await tester.pumpAndSettle();
      await tester.enterText(field, '/nope');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.textContaining("KFM can't find '/nope'"), findsOneWidget);
      expect(_tabs(app).current.location, const FolderLocation('/s/DCIM'));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(field, findsNothing);

      // A file path: its folder, with the file selected.
      app.container
          .read(desktopTabsControllerProvider.notifier)
          .navigate(const HomeLocation());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('desktop-address-crumbs')));
      await tester.pumpAndSettle();
      await tester.enterText(field, r'\s\DCIM\a.jpg');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(_tabs(app).current.location, const FolderLocation('/s/DCIM'));
      expect(find.textContaining('1 selected'), findsOneWidget);
    });

    test('typed paths are normalised', () {
      final env = {'USERPROFILE': r'C:\Users\kaf'};
      expect(
        normalizeTypedPath(r'%userprofile%\Downloads', env),
        'C:/Users/kaf/Downloads',
      );
      expect(normalizeTypedPath(r'"C:\"', env), 'C:');
      expect(normalizeTypedPath('c:/', env), 'C:');
      expect(normalizeTypedPath('D:/stuff/', env), 'D:/stuff');
      expect(normalizeTypedPath('%NOPE%/x', env), '%NOPE%/x');
      expect(normalizeTypedPath('  ', env), isNull);
      expect(windowsPathOf('C:'), r'C:\');
      expect(windowsPathOf('C:/a/b'), r'C:\a\b');
    });

    testWidgets('search in a folder opens a results tab with a Folder column', (
      tester,
    ) async {
      final app = await pumpDesktopApp(tester, files: _library());
      app.container
          .read(desktopTabsControllerProvider.notifier)
          .navigate(const FolderLocation('/s'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('desktop-search')),
        'jpg',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(
        _tabs(app).current.location,
        const SearchLocation('jpg', scope: '/s'),
      );
      expect(find.text('Folder'), findsOneWidget);
      expect(find.text('t.jpg'), findsOneWidget);
      expect(find.text('o.jpg'), findsOneWidget);
      expect(find.text(r'\s\DCIM\Trip'), findsOneWidget);
    });
  });

  group('status bar', () {
    test('driveOf picks the longest root', () {
      final c = _drive(free: 1);
      const d = StoragePlace(
        id: 'usb',
        label: 'Stick',
        kind: PlaceKind.usbDrive,
        access: AccessMethod.directPath,
        isMounted: true,
        rootPath: '/s/mnt',
      );
      expect(driveOf('/s/mnt/a', [c, d])?.id, 'usb');
      expect(driveOf('/s/x', [c, d])?.id, kInternalPlaceId);
      expect(driveOf('/q/x', [c, d]), isNull);
    });

    for (final (free, low) in [(500, false), (90, true)]) {
      testWidgets('drive space: $free of 1000 free → low=$low', (tester) async {
        await pumpDesktopApp(
          tester,
          files: _library(),
          overrides: [
            placesProvider.overrideWith((ref) async => [_drive(free: free)]),
          ],
        );
        await tester.tap(find.byKey(const ValueKey('desktop-nav-browse')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('desktop-status-drive')), findsOne);
        expect(
          find.byKey(ValueKey(low ? 'drive-bar-low' : 'drive-bar')),
          findsOneWidget,
        );
        expect(find.textContaining('free of'), findsOneWidget);
        // Never "-- items": Home counts its entries.
        expect(find.byKey(const ValueKey('desktop-status-items')), findsOne);
      });
    }

    testWidgets('view toggles switch Browse between Details and icons', (
      tester,
    ) async {
      final app = await pumpDesktopApp(tester, files: _library());
      app.container
          .read(desktopTabsControllerProvider.notifier)
          .navigate(const FolderLocation('/s/DCIM'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('status-view-icons')));
      await tester.pumpAndSettle();
      expect(
        app.container.read(desktopBrowseControllerProvider).layout.name,
        'largeIcons',
      );
      await tester.tap(find.byKey(const ValueKey('status-view-details')));
      await tester.pumpAndSettle();
      expect(
        app.container.read(desktopBrowseControllerProvider).layout.name,
        'details',
      );
    });
  });
}
