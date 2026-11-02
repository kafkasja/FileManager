import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/connect/data/loopback_media_proxy.dart';
import 'package:kfm/features/connect/data/pinned_client.dart';
import 'package:kfm/features/connect/data/remote_errors.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:kfm/features/connect/domain/remote_file_id.dart';

/// The "remote device": a plain loopback server answering
/// `GET /v1/files/<id>/content` from [data], honouring `Range: bytes=a-b`.
class _RemoteDevice {
  new _(this._server, this.data);

  static Future<_RemoteDevice> start(Uint8List data) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final device = _RemoteDevice._(server, data);
    server.listen(device._serve);
    return device;
  }

  final HttpServer _server;
  final Uint8List data;
  final List<String> paths = [];
  final List<String?> ranges = [];

  Uri get base => Uri.parse('http://127.0.0.1:${_server.port}');

  Future<void> _serve(HttpRequest req) async {
    paths.add(req.uri.path);
    final range = req.headers.value(HttpHeaders.rangeHeader);
    ranges.add(range);
    final res = req.response
      ..headers.contentType = ContentType('video', 'mp4')
      ..headers.set(HttpHeaders.acceptRangesHeader, 'bytes')
      ..headers.set(HttpHeaders.etagHeader, '"v1"');
    final m = range == null
        ? null
        : RegExp(r'^bytes=(\d+)-(\d*)$').firstMatch(range);
    if (m == null) {
      res
        ..statusCode = 200
        ..contentLength = data.length
        ..add(data);
    } else {
      final start = int.parse(m[1]!);
      final end = m[2]!.isEmpty ? data.length - 1 : int.parse(m[2]!);
      if (start >= data.length) {
        res
          ..statusCode = 416
          ..contentLength = 0;
      } else {
        final slice = data.sublist(start, end + 1);
        res
          ..statusCode = 206
          ..headers.set(
            HttpHeaders.contentRangeHeader,
            'bytes $start-$end/${data.length}',
          )
          ..contentLength = slice.length
          ..add(slice);
      }
    }
    await res.close();
  }

  Future<void> close() => _server.close(force: true);
}

/// [RemoteHttp] over a real (unpinned, test-only) client to [_RemoteDevice];
/// non-2xx → [RemoteApiException] like [PinnedClient].
class _UpstreamHttp implements RemoteHttp {
  new(this.base);

  @override
  final Uri base;

  @override
  String? bearerToken;

  final HttpClient _client = HttpClient();

  /// When set, getStream fails with this status before contacting the device.
  int? failStatus;
  final List<Map<String, String>> sentHeaders = [];

  @override
  Future<HttpClientResponse> getStream(
    String path, {
    Map<String, String> query = const {},
    Map<String, String> headers = const {},
  }) async {
    sentHeaders.add(headers);
    final fail = failStatus;
    if (fail != null) {
      throw RemoteApiException(fail, const ApiErrorDto('x', ''));
    }
    final req = await _client.getUrl(base.replace(path: path));
    headers.forEach(req.headers.set);
    final res = await req.close();
    if (res.statusCode < 200 || res.statusCode >= 300) {
      await res.drain<void>();
      throw RemoteApiException(res.statusCode, const ApiErrorDto('x', ''));
    }
    return res;
  }

  @override
  Future<T> getJson<T>(
    String path, {
    required T Function(Map<String, Object?> json) decode,
    Map<String, String> query = const {},
  }) => throw UnimplementedError();

  @override
  Future<T> postJson<T>(
    String path,
    Object? body, {
    required T Function(Map<String, Object?> json) decode,
    Duration? timeout,
  }) => throw UnimplementedError();

  @override
  Future<T> putStream<T>(
    String path,
    Stream<List<int>> body,
    int length, {
    required T Function(Map<String, Object?> json) decode,
    Map<String, String> query = const {},
  }) => throw UnimplementedError();

  @override
  Future<T> deleteJson<T>(
    String path, {
    required T Function(Map<String, Object?> json) decode,
  }) => throw UnimplementedError();

  @override
  void close() => _client.close(force: true);
}

FileRef _remoteFile(String serverId) => FileRef(
  id: remoteFileId('abcd', serverId),
  uri: 'remote',
  name: 'v.mp4',
  kind: FileKind.video,
  sizeBytes: 1000,
  modifiedAt: DateTime.utc(2026),
  folderPath: '/remote',
  origin: FileOrigin.remote,
);

typedef _Answer = ({int status, HttpHeaders headers, List<int> body});

void main() {
  late _RemoteDevice device;
  late _UpstreamHttp upstream;
  late HttpClient player;
  final data = Uint8List.fromList(List.generate(1000, (i) => i % 251));

  setUp(() async {
    device = await _RemoteDevice.start(data);
    upstream = _UpstreamHttp(device.base);
    player = HttpClient();
  });

  tearDown(() async {
    player.close(force: true);
    upstream.close();
    await device.close();
  });

  Future<_Answer> fetch(
    Uri url, {
    String method = 'GET',
    Map<String, String> headers = const {},
  }) async {
    final req = await player.openUrl(method, url);
    headers.forEach(req.headers.set);
    final res = await req.close();
    final body = <int>[];
    await res.forEach(body.addAll);
    return (status: res.statusCode, headers: res.headers, body: body);
  }

  Future<LoopbackMediaProxy> started({
    void Function()? onUnauthorized,
    bool Function(InternetAddress)? allowPeer,
  }) async {
    final proxy = LoopbackMediaProxy(
      http: () => upstream,
      onUnauthorized: onUnauthorized,
      allowPeer: allowPeer,
    );
    await proxy.start();
    addTearDown(proxy.close);
    return proxy;
  }

  test('urlFor gives a 127.0.0.1 URL with a 32-hex handle', () async {
    final proxy = await started();
    final url = proxy.urlFor(_remoteFile('ms:12'));
    expect(url.scheme, 'http');
    expect(url.host, '127.0.0.1');
    expect(url.port, proxy.port);
    expect(url.path, matches(RegExp(r'^/m/[0-9a-f]{32}$')));
    expect(proxy.urlFor(_remoteFile('ms:12')), isNot(url));
  });

  test('urlFor throws before start and for a local file', () async {
    final proxy = LoopbackMediaProxy(http: () => upstream);
    expect(() => proxy.urlFor(_remoteFile('ms:1')), throwsStateError);
    await proxy.start();
    addTearDown(proxy.close);
    final local = _remoteFile('ms:1').copyWith(origin: FileOrigin.local);
    expect(() => proxy.urlFor(local), throwsStateError);
  });

  test('full GET streams the whole file with headers', () async {
    final proxy = await started();
    final a = await fetch(proxy.urlFor(_remoteFile('path:/s/a:b.mp4')));
    expect(a.status, 200);
    expect(a.body, data);
    expect(a.headers.contentLength, 1000);
    expect(a.headers.contentType?.mimeType, 'video/mp4');
    expect(a.headers.value(HttpHeaders.acceptRangesHeader), 'bytes');
    expect(a.headers.value(HttpHeaders.etagHeader), '"v1"');
    expect(device.paths.single, ApiRoutes.fileContent('path:/s/a:b.mp4'));
  });

  test('Range is forwarded and answered with 206 and the slice', () async {
    final proxy = await started();
    final a = await fetch(
      proxy.urlFor(_remoteFile('ms:7')),
      headers: {
        HttpHeaders.rangeHeader: 'bytes=100-199',
        HttpHeaders.ifRangeHeader: '"v1"',
      },
    );
    expect(a.status, 206);
    expect(a.body, data.sublist(100, 200));
    expect(a.headers.contentLength, 100);
    expect(
      a.headers.value(HttpHeaders.contentRangeHeader),
      'bytes 100-199/1000',
    );
    expect(device.ranges.single, 'bytes=100-199');
    expect(upstream.sentHeaders.single, {
      HttpHeaders.rangeHeader: 'bytes=100-199',
      HttpHeaders.ifRangeHeader: '"v1"',
    });
  });

  test('an unsatisfiable range answers 416', () async {
    final proxy = await started();
    final a = await fetch(
      proxy.urlFor(_remoteFile('ms:7')),
      headers: {HttpHeaders.rangeHeader: 'bytes=5000-'},
    );
    expect(a.status, 416);
  });

  test('HEAD answers headers without a body', () async {
    final proxy = await started();
    final a = await fetch(proxy.urlFor(_remoteFile('ms:7')), method: 'HEAD');
    expect(a.status, 200);
    expect(a.body, isEmpty);
    expect(a.headers.contentLength, 1000);
  });

  test('unknown handle, wrong path and wrong method answer 404', () async {
    final proxy = await started();
    final url = proxy.urlFor(_remoteFile('ms:7'));
    final base = Uri.parse('http://127.0.0.1:${proxy.port}');
    expect((await fetch(base.replace(path: '/m/${'0' * 32}'))).status, 404);
    expect((await fetch(base.replace(path: '/x'))).status, 404);
    expect((await fetch(url, method: 'POST')).status, 404);
    expect(device.paths, isEmpty);
  });

  test('revokeAll makes handed-out URLs answer 404', () async {
    final proxy = await started();
    final url = proxy.urlFor(_remoteFile('ms:7'));
    expect((await fetch(url)).status, 200);
    proxy.revokeAll();
    expect((await fetch(url)).status, 404);
  });

  test('after close the port refuses connections', () async {
    final proxy = await started();
    final url = proxy.urlFor(_remoteFile('ms:7'));
    await proxy.close();
    expect(proxy.port, isNull);
    await expectLater(fetch(url), throwsA(isA<SocketException>()));
    expect(() => proxy.urlFor(_remoteFile('ms:7')), throwsStateError);
  });

  test('upstream 401 answers 502 and reports unauthorized', () async {
    var unauthorized = 0;
    final proxy = await started(onUnauthorized: () => unauthorized++);
    upstream.failStatus = 401;
    final a = await fetch(proxy.urlFor(_remoteFile('ms:7')));
    expect(a.status, 502);
    expect(unauthorized, 1);
  });

  test('upstream 404 is passed through, other errors are 502', () async {
    final proxy = await started();
    upstream.failStatus = 404;
    expect((await fetch(proxy.urlFor(_remoteFile('ms:7')))).status, 404);
    upstream.failStatus = 500;
    expect((await fetch(proxy.urlFor(_remoteFile('ms:7')))).status, 502);
  });

  test('an unreachable device answers 502', () async {
    final proxy = await started();
    await device.close();
    expect((await fetch(proxy.urlFor(_remoteFile('ms:7')))).status, 502);
  });

  test('a non-loopback peer gets 403', () async {
    final proxy = await started(allowPeer: (_) => false);
    final a = await fetch(proxy.urlFor(_remoteFile('ms:7')));
    expect(a.status, 403);
    expect(upstream.sentHeaders, isEmpty);
  });
}
