import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/file_reveal.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/ui/incoming_offer_prompter.dart';
import 'package:kfm/features/connect/ui/receive_folder_tile.dart';
import 'package:kfm/features/transfers/data/transfer_providers.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

import '../../helpers/pump_app.dart';

/// TASK-E1 D ("i have no idea where that video is now"): the receive
/// folder setting and "… saved to …" with Show in folder / Open / Copy
/// path.
void main() {
  test('prettyFolder starts at the downloads folder', () {
    const d = '/storage/emulated/0/Download';
    expect(
      prettyFolder('$d/KFM/Phone', downloads: d),
      'Download › KFM › Phone',
    );
    expect(prettyFolder(d, downloads: d), 'Download');
    expect(
      prettyFolder(
        'C:/Users/kaf/Downloads/KFM',
        downloads: 'C:/Users/kaf/Downloads',
      ),
      'Downloads › KFM',
    );
    expect(prettyFolder('/a/b/c/d/e', downloads: d), 'c › d › e');
  });

  testWidgets('received files go to Downloads/KFM by default; the setting '
      'moves new receives elsewhere', (tester) async {
    final app = await pumpApp(tester);
    final c = app.container..listen(receiveDownloadsRootProvider, (_, _) {});
    expect(c.read(receiveDownloadsRootProvider), defaultReceiveFolder());
    expect(c.read(receiveDownloadsRootProvider), endsWith('/KFM'));
    expect(c.read(downloadsRootProvider), defaultReceiveFolder());
    await tester.runAsync(
      () => c
          .read(receiveFolderSettingProvider.notifier)
          .set('/storage/emulated/0/Movies'),
    );
    expect(
      await tester.runAsync(
        () =>
            c.read(settingsRepositoryProvider).read(AppSettings.receiveFolder),
      ),
      '/storage/emulated/0/Movies',
    );
    await tester.pump();
    await tester.pump();
    expect(c.read(receiveDownloadsRootProvider), '/storage/emulated/0/Movies');
    expect(c.read(downloadsRootProvider), '/storage/emulated/0/Movies');
    // The offer service follows without being rebuilt.
    expect(
      c.read(offerServiceProvider).downloadsRoot,
      '/storage/emulated/0/Movies',
    );
  });

  testWidgets('Settings → Connect a device shows where received files go; '
      'Change opens the folder picker', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    final row = find.byKey(const ValueKey('settings-receive-folder'));
    await tester.scrollUntilVisible(row, 200);
    await tester.pumpAndSettle();
    expect(find.byType(ReceiveFolderTile), findsOneWidget);
    expect(find.text('Received files go to'), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('receive-folder-path')))
          .data,
      endsWith('› KFM'),
    );
    // Default folder: nothing to reset.
    expect(find.byKey(const ValueKey('receive-folder-reset')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('receive-folder-change')));
    await tester.pumpAndSettle();
    // Android: KFM's own folder picker.
    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets('"cat.mp4 saved to …" with Show in folder, Open and Copy '
      'path', (tester) async {
    final app = await pumpApp(tester);
    final downloads = platformDownloadsFolder();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: app.container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () => showReceivedSnackBar(
                  context,
                  ref,
                  folder: '$downloads/KFM/Phone',
                  files: [
                    (
                      name: 'cat.mp4',
                      fileId: 'path:$downloads/KFM/Phone/cat.mp4',
                    ),
                  ],
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(
      find.text('cat.mp4 saved to Downloads › KFM › Phone'),
      findsOneWidget,
    );
    expect(find.text('Show in folder'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('saved-more')));
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Copy path'), findsOneWidget);
    await tester.tapAt(Offset.zero);
    await tester.pump(const Duration(seconds: 10));
  });
}
