import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/theme/app_theme.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/apk_install/data/apk_cache.dart';
import 'package:kfm/features/apk_install/data/apk_platform.dart';
import 'package:kfm/features/apk_install/domain/apk_detect.dart';
import 'package:kfm/features/apk_install/domain/apk_info.dart';
import 'package:kfm/features/apk_install/ui/apk_info_sheet.dart';
import 'package:kfm/features/apk_install/ui/apk_install_controller.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

FileRef _file(
  String name, {
  String? mime,
  FileOrigin origin = FileOrigin.local,
  String? uri,
}) => FileRef(
  id: 'path:/storage/emulated/0/Download/$name',
  uri: uri ?? 'file:///storage/emulated/0/Download/$name',
  name: name,
  mimeType: mime,
  kind: FileKind.other,
  sizeBytes: 1234,
  modifiedAt: DateTime.utc(2026),
  folderPath: '/storage/emulated/0/Download',
  origin: origin,
);

ApkInfo _info({
  int code = 2,
  int? installed,
  bool visible = true,
  bool? sameSigner,
  bool isCopy = false,
}) => ApkInfo(
  label: 'KFM',
  packageName: 'com.kaf.kfm',
  versionName: '0.2.0',
  versionCode: code,
  installedVisible: visible,
  installedVersionName: installed == null ? null : '0.1.0',
  installedVersionCode: installed,
  sameSigner: sameSigner,
  installPath: '/cache/apk/x.apk',
  isCopy: isCopy,
);

class FakeApkPlatform implements ApkPlatform {
  ApkInfo? info;
  Exception? error;
  bool canInstallValue = true;
  bool installerExists = true;
  final installed = <String>[];
  final discarded = <String>[];
  int settingsOpened = 0;

  @override
  Future<ApkInfo> inspect(FileRef f) async {
    if (error != null) throw error!;
    return info!;
  }

  @override
  Future<bool> canInstall() async => canInstallValue;

  @override
  Future<bool> openPermissionSettings() async {
    settingsOpened++;
    return true;
  }

  @override
  Future<bool> install(String path) async {
    if (!installerExists) return false;
    installed.add(path);
    return true;
  }

  @override
  Future<void> discardCopy(String path) async => discarded.add(path);
}

void main() {
  group('isApk', () {
    test('by name (any case) or MIME, never remote', () {
      expect(isApk(_file('a.apk')), isTrue);
      expect(isApk(_file('A.APK')), isTrue);
      expect(isApk(_file('pkg', mime: apkMimeType)), isTrue);
      expect(isApk(_file('a.apks')), isFalse);
      expect(isApk(_file('a.jpg')), isFalse);
      expect(isApk(_file('a.apk', origin: FileOrigin.remote)), isFalse);
    });
  });

  group('ApkInfo', () {
    test('update / downgrade / same / new / unknown', () {
      expect(_info(installed: 1).isUpdate, isTrue);
      expect(_info(installed: 3).isDowngrade, isTrue);
      expect(_info(installed: 2).isSameVersion, isTrue);
      expect(_info().isNewApp, isTrue);
      final hidden = _info(visible: false);
      expect(hidden.isNewApp, isFalse);
      expect(hidden.isInstalled, isFalse);
      expect(_info(installed: 1, sameSigner: false).signerMismatch, isTrue);
      expect(_info(installed: 1).signerMismatch, isFalse);
    });

    test('parses the channel map', () {
      final info = apkInfoFromRow({
        'label': 'KFM',
        'packageName': 'com.kaf.kfm',
        'versionName': '0.2.0',
        'versionCode': 2,
        'iconPng': Uint8List(3),
        'installedVisible': true,
        'installedVersionName': '0.1.0',
        'installedVersionCode': 1,
        'sameSigner': false,
        'path': '/x.apk',
        'isCopy': false,
      });
      expect(info.isUpdate, isTrue);
      expect(info.signerMismatch, isTrue);
      expect(info.installPath, '/x.apk');
      expect(
        () => apkInfoFromRow({'label': 'x'}),
        throwsA(isA<ApkException>()),
      );
    });
  });

  group('ApkInstallController', () {
    late FakeApkPlatform platform;
    late ProviderContainer container;
    final file = _file('kfm.apk');

    setUp(() {
      platform = FakeApkPlatform()..info = _info(isCopy: true);
      container = ProviderContainer(
        overrides: [apkPlatformProvider.overrideWithValue(platform)],
      );
    });

    tearDown(() => container.dispose());

    test('installs, or asks for the permission first', () async {
      final sub = container.listen(
        apkInstallControllerProvider(file),
        (_, _) {},
      );
      final notifier = container.read(
        apkInstallControllerProvider(file).notifier,
      );
      await container.read(apkInstallControllerProvider(file).future);
      platform.canInstallValue = false;
      expect(await notifier.install(), ApkInstallOutcome.needsPermission);
      expect(
        await notifier.resumeAfterSettings(),
        ApkInstallOutcome.permissionDenied,
      );
      platform.canInstallValue = true;
      expect(await notifier.resumeAfterSettings(), ApkInstallOutcome.handedOff);
      expect(platform.installed, ['/cache/apk/x.apk']);
      platform.installerExists = false;
      expect(await notifier.install(), ApkInstallOutcome.noInstaller);
      sub.close();
    });

    test('a cache copy is deleted when the sheet goes away', () async {
      final sub = container.listen(
        apkInstallControllerProvider(file),
        (_, _) {},
      );
      await container.read(apkInstallControllerProvider(file).future);
      sub.close();
      await container.pump();
      expect(platform.discarded, ['/cache/apk/x.apk']);
    });

    test('inspect errors reach the state', () async {
      platform.error = const ApkException(ApkFailure.invalid, 'bad');
      final sub = container.listen(
        apkInstallControllerProvider(file),
        (_, _) {},
      );
      await expectLater(
        container.read(apkInstallControllerProvider(file).future),
        throwsA(isA<ApkException>()),
      );
      expect(container.read(apkInstallControllerProvider(file)).hasError, true);
      sub.close();
    });
  });

  group('ApkInfoSheet', () {
    Future<FakeApkPlatform> pumpSheet(
      WidgetTester tester, {
      ApkInfo? info,
      Exception? error,
    }) async {
      final platform = FakeApkPlatform()
        ..info = info
        ..error = error;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [apkPlatformProvider.overrideWithValue(platform)],
          child: MaterialApp(
            theme: buildTheme(Brightness.light),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: ApkInfoSheet(file: _file('kfm.apk'))),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return platform;
    }

    testWidgets('invalid package: message, no Install', (tester) async {
      await pumpSheet(
        tester,
        error: const ApkException(ApkFailure.invalid, 'bad'),
      );
      expect(find.text("This file isn't a valid app package."), findsOneWidget);
      expect(find.byKey(const ValueKey('apk-install')), findsNothing);
    });

    testWidgets('update with a different signer warns, Install hands off', (
      tester,
    ) async {
      final platform = await pumpSheet(
        tester,
        info: _info(installed: 1, sameSigner: false),
      );
      expect(find.text('Update from 0.1.0 to 0.2.0'), findsOneWidget);
      expect(find.byKey(const ValueKey('apk-signer-mismatch')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('apk-install')));
      await tester.pumpAndSettle();
      expect(platform.installed, hasLength(1));
    });

    testWidgets('permission off: explain, open settings, deny on return', (
      tester,
    ) async {
      final platform = await pumpSheet(tester, info: _info(visible: false));
      expect(
        find.text('Android will show whether this is a new app or an update'),
        findsOneWidget,
      );
      platform.canInstallValue = false;
      await tester.tap(find.byKey(const ValueKey('apk-install')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('apk-permission-why')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('apk-open-settings')));
      await tester.pumpAndSettle();
      expect(platform.settingsOpened, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('apk-permission-denied')),
        findsOneWidget,
      );
      expect(platform.installed, isEmpty);
    });
  });

  group('ApkCache', () {
    test('removes copies older than a day only', () async {
      final dir = Directory.systemTemp.createTempSync('kfm_apk_cache');
      addTearDown(() => dir.deleteSync(recursive: true));
      final apkDir = Directory('${dir.path}/apk')..createSync();
      final old = File('${apkDir.path}/old.apk')..writeAsStringSync('x');
      final fresh = File('${apkDir.path}/new.apk')..writeAsStringSync('x');
      old.setLastModifiedSync(DateTime.now().subtract(const Duration(days: 2)));
      final cache = ApkCache(() async => dir);
      expect(await cache.cleanUp(), 1);
      expect(old.existsSync(), isFalse);
      expect(fresh.existsSync(), isTrue);
      expect(
        await ApkCache(() async => Directory('${dir.path}/x')).cleanUp(),
        0,
      );
    });
  });
}
