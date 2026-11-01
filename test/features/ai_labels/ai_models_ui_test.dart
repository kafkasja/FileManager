import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/features/ai_labels/data/ai_labels_providers.dart';
import 'package:kfm/features/ai_labels/data/ai_licenses.dart';
import 'package:kfm/features/ai_labels/data/ai_model_manifest.dart';
import 'package:kfm/features/ai_labels/data/ai_model_store.dart';
import 'package:kfm/features/ai_labels/ui/ai_labels_card.dart';
import 'package:kfm/features/ai_labels/ui/ai_models_details_screen.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

import '../../core/files/fake_file_source.dart';
import '../../helpers/pump_app.dart';

/// No network, no files: download/remove just change state.
class FakeStore extends AiModelStore {
  new({required this.installed})
    : super(
        manifest: AiModelManifest.parse(
          File(AiModelManifest.assetPath).readAsStringSync(),
        ),
        baseDir: () async => Directory.systemTemp,
        wifiOnly: () async => true,
        isOnWifi: () async => true,
        wifiChanges: const Stream.empty(),
      );

  bool installed;
  int downloads = 0;
  int removes = 0;

  @override
  Future<AiModelState> verifyInstalled() async {
    emit(
      installed
          ? AiModelsInstalled(manifest.totalBytes)
          : const AiModelsNotInstalled(),
    );
    return state;
  }

  @override
  Future<bool> download({bool useMobileData = false}) async {
    downloads++;
    emit(AiModelsDownloading(0, manifest.totalBytes));
    installed = true;
    emit(AiModelsInstalled(manifest.totalBytes));
    return true;
  }

  @override
  Future<void> remove() async {
    removes++;
    installed = false;
    emit(const AiModelsNotInstalled());
  }

  @override
  Future<AiModelBytes?> loadVerified() async => null;
}

final AppLocalizations _l10n = lookupAppLocalizations(const Locale('en'));

void main() {
  late FakeStore store;

  Future<TestApp> open(
    WidgetTester tester, {
    AiSupport support = AiSupport.supported,
    bool installed = false,
  }) async {
    store = FakeStore(installed: installed);
    final files = FakeFileSource()
      ..addFile(
        '/storage/emulated/0/DCIM/Camera/p1.jpg',
        modifiedAt: DateTime.utc(2025),
      );
    final app = await pumpApp(
      tester,
      files: files,
      overrides: [
        aiSupportProvider.overrideWith((ref) async => support),
        aiModelStoreProvider.overrideWith((ref) async {
          await store.verifyInstalled();
          return store;
        }),
      ],
    );
    return app;
  }

  Future<bool> setting(TestApp app, String which) async {
    await app.container.read(dbWriteQueueProvider).flush();
    final settings = app.container.read(settingsRepositoryProvider);
    return await settings.read(
      which == 'enabled'
          ? AppSettings.aiLabelsEnabled
          : AppSettings.aiLabelsCardDismissed,
    );
  }

  Future<void> openImages(WidgetTester tester) async {
    await tester.tap(find.text('Browse'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l10n.browseKindImages));
    await tester.pumpAndSettle();
  }

  testWidgets('fresh install: labeling off, the card in Browse images and '
      'search; nothing downloaded before Download', (tester) async {
    final app = await open(tester);
    await openImages(tester);
    expect(find.text(_l10n.aiLabelsCardTitle), findsOneWidget);
    expect(await setting(app, 'enabled'), isFalse);

    await tester.tap(find.byTooltip(_l10n.searchOpen));
    await tester.pumpAndSettle();
    expect(find.byType(AiLabelsCard), findsOneWidget);
    expect(find.text(_l10n.aiLabelsCardTitle), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Turn on → the details screen (models not installed).
    await tester.tap(find.text(_l10n.aiLabelsCardTurnOn));
    await tester.pumpAndSettle();
    expect(find.byType(AiModelsDetailsScreen), findsOneWidget);
    Future<void> sees(Finder f) async {
      await tester.scrollUntilVisible(f, 100);
      expect(f, findsOneWidget);
    }

    await sees(find.text('EfficientNet-Lite0 (int8)'));
    await sees(find.text(_l10n.aiModelClassifierWhat));
    await sees(find.textContaining('efficientnet_lite0_int8_2.tflite'));
    await sees(find.text(_l10n.aiModelDetectorWhat));
    await sees(find.text('EfficientDet-Lite0'));
    await sees(find.textContaining('efficientdet_lite0_detection'));
    await sees(
      find.textContaining('No photo, thumbnail or result ever leaves'),
    );
    expect(find.textContaining(_l10n.aiModelsRemovableBody), findsOneWidget);
    expect(store.downloads, 0);
    expect(await setting(app, 'enabled'), isFalse);

    final download = find.text(_l10n.aiModelsDownloadButton(10));
    await tester.scrollUntilVisible(download, 200);
    await tester.tap(download);
    await tester.pumpAndSettle();
    expect(store.downloads, 1);
    expect(await setting(app, 'enabled'), isTrue);
    expect(find.text(_l10n.aiModelsInstalledDone), findsOneWidget);
    expect(find.byType(AiModelsDetailsScreen), findsNothing);
  });

  testWidgets('models installed: Turn on enables at once; Not now hides the '
      'card', (tester) async {
    final app = await open(tester, installed: true);
    await openImages(tester);
    await tester.tap(find.text(_l10n.aiLabelsCardTurnOn));
    await tester.pumpAndSettle();
    expect(await setting(app, 'enabled'), isTrue);
    expect(store.downloads, 0);
    expect(find.text(_l10n.aiLabelsTurnedOn), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text(_l10n.aiLabelsCardTitle), findsNothing);

    await app.container
        .read(settingsRepositoryProvider)
        .write(AppSettings.aiLabelsEnabled, false);
    await tester.pumpAndSettle();
    expect(find.text(_l10n.aiLabelsCardTitle), findsOneWidget);
    await tester.tap(find.text(_l10n.aiLabelsCardNotNow));
    await tester.pumpAndSettle();
    expect(await setting(app, 'dismissed'), isTrue);
    expect(find.text(_l10n.aiLabelsCardTitle), findsNothing);
  });

  testWidgets('Android 7 (API 24/25): no card, no download, says why', (
    tester,
  ) async {
    final app = await open(tester, support: AiSupport.needsAndroid8);
    await openImages(tester);
    expect(find.text(_l10n.aiLabelsCardTitle), findsNothing);

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    final line = find.text(_l10n.aiLabelsNeedsAndroid8);
    await tester.scrollUntilVisible(line, 200);
    expect(line, findsOneWidget);
    expect(find.text(_l10n.aiModelsAbout), findsNothing);
    expect(store.downloads, 0);
    // A turn-on attempt is refused.
    expect(
      await app.container.read(aiLabelsControllerProvider).turnOn(),
      TurnOnResult.unsupported,
    );
    await tester.pumpAndSettle();
  });

  testWidgets('Settings: on/off, remove with "Also delete the photo labels"', (
    tester,
  ) async {
    final app = await open(tester, installed: true);
    await app.db.customStatement(
      'INSERT INTO ai_labels (file_id, label, confidence) VALUES '
      "('ms:1', 'cat', 0.9)",
    );
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    final installedLine = find.text(_l10n.aiModelsInstalled(10));
    await tester.scrollUntilVisible(installedLine, 200);
    expect(installedLine, findsOneWidget);
    final toggle = find.text(_l10n.aiLabelsEnable);
    await tester.scrollUntilVisible(toggle, 100);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(await setting(app, 'enabled'), isTrue);

    final remove = find.text(_l10n.aiModelsRemove);
    await tester.scrollUntilVisible(remove, 200);
    await tester.tap(remove);
    await tester.pumpAndSettle();
    expect(find.text(_l10n.aiModelsRemoveTitle(10)), findsOneWidget);
    await tester.tap(find.text(_l10n.aiModelsRemoveAlsoLabels));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_l10n.aiModelsRemoveConfirm));
    await tester.pumpAndSettle();
    expect(store.removes, 1);
    expect(await setting(app, 'enabled'), isFalse);
    await app.container.read(dbWriteQueueProvider).flush();
    expect(await app.db.select(app.db.aiLabels).get(), isEmpty);
    await tester.pumpAndSettle();
  });

  testWidgets('the label vocabulary is there without any model', (
    tester,
  ) async {
    final app = await open(tester, support: AiSupport.unsupportedPlatform);
    await app.container.read(labelMapProvider.future);
    final vocab = app.container.read(labelVocabularyProvider);
    expect(vocab, containsAll(['cat', 'beach', 'person', 'color:blue']));
    expect(store.downloads, 0);
  });

  test('licences include the models and COCO names', () async {
    registerAiLicenses();
    final packages = <String>{};
    await for (final l in LicenseRegistry.licenses) {
      packages.addAll(l.packages);
    }
    expect(
      packages,
      containsAll([
        'EfficientNet-Lite0 (int8)',
        'EfficientDet-Lite0',
        'COCO category names',
      ]),
    );
  });
}
