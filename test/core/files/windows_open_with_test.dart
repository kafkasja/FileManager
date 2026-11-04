import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/open_with.dart';
import 'package:kfm/core/platform/windows/windows_channel.dart';
import 'package:kfm/features/browse/ui/open_file.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

import '../platform/windows/fake_windows_channel.dart';

FileRef _file(String path, {FileOrigin origin = FileOrigin.local}) => FileRef(
  id: 'path:$path',
  uri: path,
  name: path.split('/').last,
  kind: FileKind.document,
  sizeBytes: 1,
  modifiedAt: DateTime.utc(2026),
  folderPath: path.substring(0, path.lastIndexOf('/')),
  origin: origin,
);

class _Broken implements OpenWithService {
  @override
  Future<void> open(FileRef f) async => throw StateError('boom');

  @override
  Future<void> openWith(FileRef f) async => throw StateError('boom');
}

void main() {
  late FakeWindowsChannel channel;
  late WindowsOpenWithService service;
  final pdf = _file('C:/Users/me/Documents/manual.pdf');

  setUp(() {
    channel = FakeWindowsChannel();
    service = WindowsOpenWithService(channel);
  });

  test('open = the default app; no default app shows the chooser', () async {
    await service.open(pdf);
    expect(channel.calls, ['openFile']);
    channel
      ..calls.clear()
      ..openFileResult = ShellOpenResult.noApp;
    await service.open(pdf);
    expect(channel.calls, ['openFile', 'openWith']);
    expect(channel.openedPaths.last, 'C:/Users/me/Documents/manual.pdf');
  });

  test('open with = the chooser; closing it is not an error', () async {
    channel.openWithResult = ShellOpenResult.cancelled;
    await service.openWith(pdf);
    expect(channel.calls, ['openWith']);
  });

  test('failures surface as FileOpException', () async {
    channel.openFileResult = ShellOpenResult.failed;
    await expectLater(
      service.open(pdf),
      throwsA(
        isA<FileOpException>().having(
          (e) => e.failure,
          'failure',
          FileOpFailure.ioError,
        ),
      ),
    );
    channel.openWithResult = ShellOpenResult.notFound;
    await expectLater(
      service.openWith(pdf),
      throwsA(
        isA<FileOpException>().having(
          (e) => e.failure,
          'failure',
          FileOpFailure.notFound,
        ),
      ),
    );
    // A connected device's file has no Windows path.
    await expectLater(
      service.openWith(_file('/remote/x.pdf', origin: FileOrigin.remote)),
      throwsA(isA<FileOpException>()),
    );
  });

  testWidgets('any failure shows a snackbar, never nothing', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [openWithServiceProvider.overrideWithValue(_Broken())],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => Column(
                children: [
                  TextButton(
                    onPressed: () => openWithOrExplain(context, ref, pdf),
                    child: const Text('with'),
                  ),
                  TextButton(
                    onPressed: () => openOrExplain(context, ref, pdf),
                    child: const Text('open'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('with'));
    await tester.pump();
    expect(find.text("Couldn't open this file."), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 10));
    await tester.tap(find.text('open'));
    await tester.pump();
    expect(find.text("Couldn't open this file."), findsOneWidget);
  });

  testWidgets('no Open with on this platform says so', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          openWithServiceProvider.overrideWithValue(
            const UnsupportedOpenWithService(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () => openWithOrExplain(context, ref, pdf),
                child: const Text('with'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('with'));
    await tester.pump();
    expect(find.text('No app can open this file'), findsOneWidget);
  });
}
