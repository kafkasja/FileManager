import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/theme/app_theme.dart';
import 'package:kfm/features/connect/data/client_session_store.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/data/offer_service.dart';
import 'package:kfm/features/connect/data/upload_store.dart';
import 'package:kfm/features/connect/domain/connection_request.dart';
import 'package:kfm/features/connect/domain/offer_protocol.dart';
import 'package:kfm/features/connect/domain/share_offer.dart';
import 'package:kfm/features/connect/ui/offer_dialog.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

import '../../helpers/pump_app.dart';

Future<OfferAnswer?> _open(
  WidgetTester tester,
  OfferDialogData data, {
  String? picked,
}) async {
  OfferAnswer? answer;
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(Brightness.light),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            answer = await showDialog<OfferAnswer>(
              context: context,
              builder: (_) =>
                  OfferDialog(data: data, pickFolder: (_) async => picked),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    ),
  );
  await tester.tap(find.byType(TextButton));
  await tester.pump();
  return answer;
}

OfferDialogData _data({int files = 7, bool showRemember = true}) =>
    OfferDialogData(
      offerId: 'o',
      senderName: 'Pixel',
      platform: 'android',
      words: const ['acorn', 'zebra', 'tulip', 'river'],
      names: [for (var i = 0; i < files; i++) 'IMG_$i.jpg'],
      totalBytes: 24 * 1024 * 1024,
      defaultFolder: '/storage/emulated/0/Download/Pixel',
      deadline: DateTime.now().add(const Duration(minutes: 2)),
      showRemember: showRemember,
    );

void main() {
  testWidgets(
    'names (5 + more), words, folder; an excluded folder is refused',
    (tester) async {
      await _open(
        tester,
        _data(),
        picked: '/storage/emulated/0/Android/data/x',
      );
      expect(find.text('Pixel wants to send you 7 files'), findsOneWidget);
      expect(find.text('acorn zebra tulip river'), findsOneWidget);
      expect(find.text('IMG_4.jpg'), findsOneWidget);
      expect(find.text('IMG_5.jpg'), findsNothing);
      expect(find.text('and 2 more'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey('offer-change-folder')),
      );
      await tester.tap(find.byKey(const ValueKey('offer-change-folder')));
      await tester.pump();
      expect(find.text("Files can't be saved there"), findsOneWidget);
      expect(
        find.text('Save to /storage/emulated/0/Download/Pixel'),
        findsOneWidget,
      );
    },
  );

  testWidgets('accept with always: answer carries folder and flags', (
    tester,
  ) async {
    OfferAnswer? answer;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(Brightness.light),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              answer = await showDialog<OfferAnswer>(
                context: context,
                builder: (_) => OfferDialog(
                  data: _data(files: 1),
                  pickFolder: (_) async => '/storage/emulated/0/Pictures',
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(TextButton));
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey('offer-change-folder')),
    );
    await tester.tap(find.byKey(const ValueKey('offer-change-folder')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('offer-always')));
    await tester.tap(find.byKey(const ValueKey('offer-always')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('offer-accept')));
    await tester.pumpAndSettle();
    expect(answer?.accept, isTrue);
    expect(answer?.folder, '/storage/emulated/0/Pictures');
    expect(answer?.alwaysAccept, isTrue);
    expect(answer?.remember, isTrue);
  });

  testWidgets('the app shell prompts offers one at a time', (tester) async {
    final staging = Directory.systemTemp.createTempSync('kfm_prompt');
    addTearDown(() => staging.deleteSync(recursive: true));
    late OfferService service;
    final app = await pumpApp(
      tester,
      overrides: [
        offerServiceProvider.overrideWith((ref) {
          service = OfferService(
            repo: ref.watch(offerRepositoryProvider),
            devices: ref.watch(knownDevicesRepositoryProvider),
            sessions: ClientSessionStore.new,
            uploads: UploadStore(staging: () async => staging),
            freeBytes: (_) async => null,
            downloadsRoot: '/storage/emulated/0/Download',
          );
          ref.onDispose(service.dispose);
          return service;
        }),
      ],
    );
    app.container.read(offerServiceProvider);
    ClientSession session(String fp, String name) => ClientSession(
      sessionId: fp,
      clientFingerprint: fp,
      clientDeviceId: 'd',
      clientName: name,
      tokenHash: '',
      createdAt: DateTime.now(),
      lastUsedAt: DateTime.now(),
      purpose: SessionPurpose.send,
    );
    await tester.runAsync(() async {
      await service.create(
        session('aa' * 32, 'Pixel'),
        CreateOfferDto(
          offerId: 'a' * 32,
          files: const [OfferFileDto(name: 'a.jpg', size: 3)],
        ),
      );
      await service.create(
        session('bb' * 32, 'Laptop'),
        CreateOfferDto(
          offerId: 'b' * 32,
          files: const [OfferFileDto(name: 'b.jpg', size: 3)],
        ),
      );
    });
    await tester.pump();
    await tester.pump();
    expect(find.text('Pixel wants to send you 1 file'), findsOneWidget);
    expect(find.text('Laptop wants to send you 1 file'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('offer-decline')));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Laptop wants to send you 1 file'), findsOneWidget);
    expect(
      (await tester.runAsync(
        () => app.container.read(offerRepositoryProvider).dao.byId('a' * 32),
      ))?.status,
      OfferStatus.declined,
    );
    // Ended elsewhere (the sender cancels): the dialog closes.
    await tester.runAsync(() => service.cancelBySender('bb' * 32, 'b' * 32));
    await tester.pump();
    await tester.pump();
    expect(find.text('Laptop wants to send you 1 file'), findsNothing);
    await tester.pump(const Duration(minutes: 3));
  });
}
