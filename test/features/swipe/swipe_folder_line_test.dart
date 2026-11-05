import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/theme/app_theme.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/browse/domain/browse_source_chip.dart';
import 'package:kfm/features/browse/ui/browse_controller.dart';
import 'package:kfm/features/browse/ui/browse_screen.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';
import 'package:kfm/features/swipe/ui/swipe_folder_line.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

import '../../core/files/fake_file_source.dart';
import '../../helpers/pump_app.dart';

/// TASK-E4 §4: the swipe screen shows the current file's folder; one tap
/// copies its path or opens the folder.
void main() {
  const root = '/storage/emulated/0';
  const folder = '$root/DCIM/Camera';

  FakeFileSource library() => FakeFileSource()
    ..addFile('$folder/c1.jpg', modifiedAt: DateTime.utc(2025, 1, 2))
    ..addFile('$folder/c2.jpg', modifiedAt: DateTime.utc(2025));

  final line = find.byKey(const ValueKey('swipe-folder-line'));

  List<String> mockClipboard(WidgetTester tester) {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    return copied;
  }

  testWidgets('shows leaf folder + place; Copy path copies the path', (
    tester,
  ) async {
    await pumpApp(tester, files: library());
    expect(line, findsOneWidget);
    expect(find.text('Camera · Internal storage'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Folder: Camera · Internal storage'),
      findsOne,
    );

    final copied = mockClipboard(tester);
    await tester.tap(line);
    await tester.pumpAndSettle();
    expect(find.text('$folder/c1.jpg'), findsOneWidget); // full path
    await tester.tap(find.text('Copy path'));
    await tester.pumpAndSettle();
    expect(copied, ['$folder/c1.jpg']);
    expect(find.text('Path copied'), findsOneWidget);

    // Long press copies directly.
    await tester.longPress(line);
    await tester.pumpAndSettle();
    expect(copied, hasLength(2));
  });

  testWidgets('Open folder lands in Browse folder mode; the session is kept', (
    tester,
  ) async {
    final app = await pumpApp(tester, files: library());
    final session = app.container
        .read(swipeDeckControllerProvider)
        .value!
        .session
        .id;
    await tester.tap(line);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open folder'));
    await tester.pumpAndSettle();
    expect(find.byType(BrowseScreen), findsOneWidget);
    final view = app.container.read(browseViewControllerProvider);
    expect(view.layout, BrowseLayout.folders);
    expect(view.folder, folder);
    // The file it came for is flashed once.
    expect(find.byKey(const ValueKey('results-flash')), findsOneWidget);

    await tester.tap(find.text('Swipe'));
    await tester.pumpAndSettle();
    expect(
      app.container.read(swipeDeckControllerProvider).value!.session.id,
      session,
    );
    expect(line, findsOneWidget);
  });

  testWidgets('the setting off removes the line', (tester) async {
    final app = await pumpApp(tester, files: library());
    expect(line, findsOneWidget);
    await app.container
        .read(settingsRepositoryProvider)
        .write(AppSettings.swipeShowFolder, false);
    await tester.pumpAndSettle();
    expect(line, findsNothing);
    expect(find.byType(SwipeFolderLine), findsOneWidget);
  });

  testWidgets('a connected device deck offers only Copy', (tester) async {
    final file = FileRef(
      id: 'remote:ab:r1/Pictures/Cats/cat.jpg',
      uri: 'r1/Pictures/Cats/cat.jpg',
      name: 'cat.jpg',
      kind: FileKind.image,
      sizeBytes: 1,
      modifiedAt: DateTime.utc(2025),
      folderPath: 'r1/Pictures/Cats',
      origin: FileOrigin.remote,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          swipeShowFolderProvider.overrideWith((ref) => Stream.value(true)),
        ],
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SwipeFolderLine(file: file, remote: true)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cats'), findsOneWidget);
    await tester.tap(line);
    await tester.pumpAndSettle();
    expect(find.text('Copy path'), findsOneWidget);
    expect(find.text('Open folder'), findsNothing);
    expect(find.text('Details'), findsNothing);
  });

  test('remote folder label is the last part of the relative path', () {
    expect(remoteFolderLabel('r1/Pictures/Cats'), 'Cats');
    expect(remoteFolderLabel('r1'), 'r1');
  });
}
