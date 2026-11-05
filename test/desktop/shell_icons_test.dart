import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/platform/windows/shell_icons.dart';
import 'package:kfm/desktop/settings/desktop_icon_choice_dialog.dart';
import 'package:kfm/desktop/widgets/file_type_icon.dart';

import 'desktop_helpers.dart';

void main() {
  group('ShellIconKey', () {
    test('normal files are asked per extension, .exe/.lnk per path', () {
      expect(ShellIconKey.file('C:/a/Report.PDF', 16).id, 'ext:.pdf');
      expect(ShellIconKey.file('C:/a/b.tar.gz', 16).id, 'ext:.gz');
      expect(ShellIconKey.file('C:/a/noext', 16).id, 'ext:');
      expect(
        ShellIconKey.file('C:/Apps/Tool.EXE', 16).id,
        'path:c:/apps/tool.exe',
      );
      expect(ShellIconKey.file('C:/x/Game.lnk', 32).id, 'path:c:/x/game.lnk');
      // Same extension, different folders: one key (one native call).
      expect(
        ShellIconKey.file('C:/a/x.jpg', 16),
        ShellIconKey.file('D:/b/y.JPG', 16),
      );
      expect(
        ShellIconKey.file('C:/a/x.jpg', 16),
        isNot(ShellIconKey.file('C:/a/x.jpg', 32)),
      );
    });

    test('folders are generic unless special; drives by root', () {
      expect(ShellIconKey.folder('C:/Users/k/Stuff', 16).id, 'folder');
      expect(
        ShellIconKey.folder(
          'C:/Users/k/Downloads',
          16,
          special: const {'c:/users/k/downloads'},
        ).id,
        'path:c:/users/k/downloads',
      );
      expect(ShellIconKey.drive('c:', 16).id, 'drive:C:');
    });

    test('pixel size follows the device pixel ratio', () {
      expect(shellIconPx(16, 1), 16);
      expect(shellIconPx(16, 1.5), 32);
      expect(shellIconPx(16, 2), 32);
      expect(shellIconPx(32, 1.5), 48);
      expect(shellIconPx(64, 1), 256);
    });
  });

  group('ShellIconCache', () {
    final png = Uint8List.fromList([1, 2, 3]);

    test('shares in-flight requests and caches hits', () async {
      final gate = Completer<Uint8List?>();
      var calls = 0;
      final cache = ShellIconCache((key) {
        calls++;
        return gate.future;
      });
      final key = ShellIconKey.file('a.pdf', 16);
      final a = cache.get(key);
      final b = cache.get(key);
      gate.complete(png);
      expect(await a, png);
      expect(await b, png);
      expect(await cache.get(key), png);
      expect(calls, 1);
    });

    test('evicts the least recently used entry', () async {
      final cache = ShellIconCache((key) async => png, capacity: 2);
      final a = ShellIconKey.file('a.a', 16);
      final b = ShellIconKey.file('a.b', 16);
      final c = ShellIconKey.file('a.c', 16);
      await cache.get(a);
      await cache.get(b);
      cache.peek(a); // a is now the most recent
      await cache.get(c);
      expect(cache.peek(a), isNotNull);
      expect(cache.peek(b), isNull);
      expect(cache.peek(c), isNotNull);
      expect(cache.fetches, 3);
    });

    test('a failure is cached for the run (no retry storm)', () async {
      var calls = 0;
      final cache = ShellIconCache((key) async {
        calls++;
        throw StateError('no icon');
      });
      final key = ShellIconKey.file('a.zzz', 16);
      expect(await cache.get(key), isNull);
      expect(await cache.get(key), isNull);
      expect(cache.hasFailed(key), isTrue);
      expect(calls, 1);
    });

    test('a slow icon times out as a failure', () async {
      final cache = ShellIconCache(
        (key) => Completer<Uint8List?>().future,
        timeout: const Duration(milliseconds: 10),
      );
      final key = ShellIconKey.file('//nas/share/a.doc', 16);
      expect(await cache.get(key), isNull);
      expect(cache.hasFailed(key), isTrue);
    });
  });

  testWidgets('FileTypeIcon shows the KFM icon while the shell icon loads', (
    tester,
  ) async {
    final cache = ShellIconCache((key) => Completer<Uint8List?>().future);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shellIconCacheProvider.overrideWithValue(cache),
          desktopIconStyleProvider.overrideWithValue(
            const AsyncValue.data(DesktopIconStyle.windows),
          ),
          shellSpecialFoldersProvider.overrideWithValue(
            const AsyncValue.data({}),
          ),
        ],
        child: const MaterialApp(
          home: Row(
            children: [
              FileTypeIcon.path('C:/a/report.pdf'),
              FileTypeIcon.folder('C:/a'),
            ],
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOneWidget);
    expect(find.byIcon(Icons.folder), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(2));
    // The 1 s timeout turns the stuck request into a cached failure: still
    // the KFM icon, never a blank square.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOneWidget);
    expect(find.byIcon(Icons.folder), findsOneWidget);
  });

  testWidgets('KFM style never asks the shell', (tester) async {
    var calls = 0;
    final cache = ShellIconCache((key) async {
      calls++;
      return null;
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shellIconCacheProvider.overrideWithValue(cache),
          desktopIconStyleProvider.overrideWithValue(
            const AsyncValue.data(DesktopIconStyle.kfm),
          ),
        ],
        child: const MaterialApp(home: FileTypeIcon.path('C:/a/x.zip')),
      ),
    );
    expect(find.byIcon(Icons.folder_zip_outlined), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(calls, 0);
  });

  testWidgets('first desktop start asks once which file icons to use', (
    tester,
  ) async {
    final cache = ShellIconCache((key) async => null);
    final app = await pumpDesktopApp(
      tester,
      files: desktopLibrary(1),
      overrides: [shellIconCacheProvider.overrideWithValue(cache)],
    );
    await tester.pumpAndSettle();
    expect(find.byType(DesktopIconChoiceDialog), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('icon-choice-kfm')));
    await tester.tap(find.byKey(const ValueKey('icon-choice-done')));
    await tester.pumpAndSettle();
    expect(find.byType(DesktopIconChoiceDialog), findsNothing);
    final settings = app.container.read(settingsRepositoryProvider);
    expect(await settings.read(AppSettings.desktopIconStyle), 'kfm');
    expect(await settings.read(AppSettings.desktopIconsAsked), isTrue);
  });
}
