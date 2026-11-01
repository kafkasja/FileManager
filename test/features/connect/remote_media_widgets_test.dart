import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/theme/app_theme.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/thumbs/thumbnail.dart';
import 'package:kfm/features/browse/ui/widgets/file_tile.dart';
import 'package:kfm/features/connect/data/pinned_client.dart';
import 'package:kfm/features/connect/domain/files_protocol.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:kfm/features/connect/domain/remote_connection_state.dart';
import 'package:kfm/features/connect/domain/remote_file_id.dart';
import 'package:kfm/features/connect/ui/remote_browse_screen.dart';
import 'package:kfm/features/connect/ui/remote_connection_controller.dart';
import 'package:kfm/features/connect/ui/remote_image_provider.dart';
import 'package:kfm/features/connect/ui/remote_thumbnail_provider.dart';
import 'package:kfm/features/swipe/ui/media_view.dart';
import 'package:kfm/features/swipe/ui/video_controller_pool.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

import '../swipe/fake_video.dart';
import 'fake_http_response.dart';
import 'fake_remote_http.dart';

const _fp = 'ab12';

/// A 1×1 transparent PNG.
const List<int> _png = [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];

FileRef _remote(
  String serverId, {
  FileKind kind = FileKind.image,
  int ms = 1000,
}) => FileRef(
  id: remoteFileId(_fp, serverId),
  uri: 'remote://$_fp/x',
  name: kind == FileKind.video ? 'v.mp4' : 'p.jpg',
  kind: kind,
  sizeBytes: 100,
  modifiedAt: DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true),
  folderPath: 'R1',
  origin: FileOrigin.remote,
);

/// Records every `File(...)` created in its zone.
final class _FileSpy extends IOOverrides {
  final List<String> created = [];

  @override
  File createFile(String path) {
    created.add(path);
    return super.createFile(path);
  }
}

/// A connected device without a real connection: [http] is the fake.
class _FakeConnection extends RemoteConnectionController {
  new(this._fake);

  final FakeRemoteHttp _fake;

  @override
  RemoteConnectionState build() => const RemoteConnected(
    peerName: 'Phone A',
    peerFingerprint: _fp,
    roots: [RootDto(id: 'R1', label: 'Camera', readOnly: false)],
  );

  @override
  RemoteHttp? get http => _fake;

  @override
  int get epoch => 1;
}

FakeRemoteHttp _http() {
  final http = FakeRemoteHttp();
  Future<HttpClientResponse> png(FakeRemoteCall _) async =>
      FakeHttpResponse(_png);
  for (final id in ['ms:1', 'ms:2', 'ms:3']) {
    http.streams[routeKey('GET', ApiRoutes.fileThumb(id))] = png;
    http.streams[routeKey('GET', ApiRoutes.filePreview(id))] = png;
    http.streams[routeKey('GET', ApiRoutes.fileContent(id))] = png;
  }
  return http;
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  required FakeRemoteHttp http,
  List<Override> overrides = const [],
}) => tester.pumpWidget(
  ProviderScope(
    overrides: [
      remoteFollowsAppLifecycleProvider.overrideWithValue(false),
      remoteConnectionControllerProvider.overrideWith(
        () => _FakeConnection(http),
      ),
      videoHandleFactoryProvider.overrideWithValue(FakeVideoFactory().call),
      ...overrides,
    ],
    child: MaterialApp(
      theme: buildTheme(Brightness.light),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  ),
);

int _count(FakeRemoteHttp http, String path) =>
    http.calls.where((c) => c.path == path).length;

void main() {
  testWidgets('a remote thumbnail loads over the connection and reloads '
      'when modifiedAtMs changes', (tester) async {
    final http = _http();
    Widget tile(int ms) => SizedBox.square(
      dimension: 100,
      child: Thumbnail(file: _remote('ms:1', ms: ms)),
    );
    await _pump(tester, tile(1000), http: http);
    await tester.pump();
    expect(_count(http, ApiRoutes.fileThumb('ms:1')), 1);
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<RemoteThumbnailProvider>());

    await _pump(tester, tile(1000), http: http);
    await tester.pump();
    expect(_count(http, ApiRoutes.fileThumb('ms:1')), 1);

    await _pump(tester, tile(2000), http: http);
    await tester.pump();
    expect(_count(http, ApiRoutes.fileThumb('ms:1')), 2);
  });

  testWidgets('remote thumbnail key includes modifiedAtMs', (tester) async {
    RemoteThumbnailProvider p(int ms) => RemoteThumbnailProvider(
      http: FakeRemoteHttp(),
      cache: RemoteThumbnailCache(),
      peerFingerprint: _fp,
      serverId: 'ms:1',
      epoch: 1,
      modifiedAtMs: ms,
    );
    expect(p(1), p(1));
    expect(p(1), isNot(p(2)));
    expect(p(1).cacheKey, isNot(p(2).cacheKey));
  });

  testWidgets('MediaView of a remote photo never builds File or FileImage', (
    tester,
  ) async {
    final http = _http();
    final spy = _FileSpy();
    await IOOverrides.runWithIOOverrides(() async {
      await _pump(tester, MediaView(file: _remote('ms:1')), http: http);
      await tester.pump();
    }, spy);
    expect(spy.created, isEmpty);
    final providers = [
      for (final i in tester.widgetList<Image>(find.byType(Image))) i.image,
    ];
    expect(providers.whereType<RemoteImageProvider>(), hasLength(1));
    expect(providers.whereType<FileImage>(), isEmpty);
    expect(providers.whereType<ResizeImage>(), isEmpty);
    expect(_count(http, ApiRoutes.filePreview('ms:1')), 1);
  });

  testWidgets('displayImageProvider without a connection fails, never '
      'reading a local file', (tester) async {
    final spy = _FileSpy();
    late ImageProvider<Object> p;
    IOOverrides.runWithIOOverrides(
      () => p = displayImageProvider(_remote('ms:1'), 100),
      spy,
    );
    expect(p, isA<RemoteImageProvider>());
    expect((p as RemoteImageProvider).http, isNull);
    expect(spy.created, isEmpty);
  });

  test(
    'PlayerHandle: a remote video uses the media proxy, never a file',
    () async {
      final spy = _FileSpy();
      var asked = 0;
      await IOOverrides.runWithIOOverrides(() async {
        final h = PlayerHandle(
          _remote('ms:3', kind: FileKind.video),
          mediaProxy: () async {
            asked++;
            throw StateError('not connected');
          },
        );
        expect(h.state.value.isInitialized, isFalse);
        await expectLater(h.initialize(), throwsStateError);
        await h.dispose();
      }, spy);
      expect(asked, 1);
      expect(spy.created, isEmpty);
      // The local branch still builds its controller from a file.
      final local = PlayerHandle(
        FileRef(
          id: 'path:/x/v.mp4',
          uri: '/x/v.mp4',
          name: 'v.mp4',
          kind: FileKind.video,
          sizeBytes: 1,
          modifiedAt: DateTime.utc(2026),
          folderPath: '/x',
          origin: FileOrigin.local,
        ),
      );
      expect(local.state, isNotNull);
    },
  );

  testWidgets('remote browse: roots → grid → viewer without local files', (
    tester,
  ) async {
    final http = _http()
      ..on(
        'GET',
        ApiRoutes.files,
        (_) => FilePageDto(
          items: [
            for (final id in ['ms:1', 'ms:2'])
              RemoteFileDto(
                id: id,
                name: '$id.jpg',
                kind: FileKind.image,
                sizeBytes: 100,
                modifiedAtMs: 1000,
                rootId: 'R1',
                relativeFolder: '',
              ),
          ],
          total: 2,
        ).toJson(),
      )
      ..on(
        'GET',
        ApiRoutes.folders,
        (_) => const FoldersResponseDto([
          RemoteFolderDto(name: 'Sub', relativePath: 'Sub', fileCount: 4),
        ]).toJson(),
      )
      ..on(
        'GET',
        ApiRoutes.fileStat('ms:1'),
        (_) => const RemoteFileDto(
          id: 'ms:1',
          name: 'ms:1.jpg',
          kind: FileKind.image,
          sizeBytes: 100,
          modifiedAtMs: 1000,
          rootId: 'R1',
          relativeFolder: '',
        ).toJson(),
      );
    final spy = _FileSpy();
    await IOOverrides.runWithIOOverrides(() async {
      await _pump(
        tester,
        const RemoteBrowseScreen(peerFingerprint: _fp),
        http: http,
      );
      await tester.pumpAndSettle();
      expect(find.text('Camera'), findsOneWidget);
      await tester.tap(find.text('Camera'));
      await tester.pumpAndSettle();
      expect(find.text('Sub'), findsOneWidget);
      expect(find.byType(FileGridTile), findsNWidgets(2));
      await tester.tap(find.byType(FileGridTile).first);
      await tester.pumpAndSettle();
      // The viewer is open on the remote photo.
      final providers = [
        for (final i in tester.widgetList<Image>(find.byType(Image))) i.image,
      ];
      expect(providers.whereType<RemoteImageProvider>(), isNotEmpty);
      expect(providers.whereType<FileImage>(), isEmpty);
      expect(
        providers.whereType<RemoteImageProvider>().where((p) => p.original),
        isNotEmpty,
      );
    }, spy);
    expect(spy.created, isEmpty);
    expect(_count(http, ApiRoutes.fileStat('ms:1')), 1);
    expect(find.text('This file is no longer available'), findsNothing);
  });

  testWidgets('remote browse while disconnected shows Connect again', (
    tester,
  ) async {
    final http = _http();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          remoteFollowsAppLifecycleProvider.overrideWithValue(false),
          remoteConnectionControllerProvider.overrideWith(() => _Idle(http)),
        ],
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const RemoteBrowseScreen(peerFingerprint: _fp),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Phone A isn’t connected'), findsOneWidget);
    expect(find.text('Connect again'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(http.calls, isEmpty);
  });
}

class _Idle extends _FakeConnection {
  new(super._fake);

  @override
  RemoteConnectionState build() => const RemoteDisconnected(
    peerName: 'Phone A',
    reason: DisconnectReason.remoteStopped,
  );

  @override
  RemoteHttp? get http => null;
}
