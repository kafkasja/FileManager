import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/utils/random_id.dart';
import 'package:kfm/features/connect/data/pinned_client.dart';
import 'package:kfm/features/connect/data/remote_errors.dart';
import 'package:kfm/features/connect/domain/link.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:kfm/features/connect/domain/remote_file_id.dart';

/// Plain-HTTP server on `127.0.0.1` that lets a media player stream a remote
/// file (TASK-N5). Players can't use [PinnedClient], so they get
/// `http://127.0.0.1:<port>/m/<handle>` and the proxy forwards each request
/// (with `Range`) over the pinned connection.
///
/// Handles are random per call and per connection; [revokeAll] / [close] on
/// disconnect. Nothing here logs URLs or headers (they map to tokens).
class LoopbackMediaProxy {
  /// `http` is read per request, so a replaced connection is picked up.
  /// [allowPeer] is a test hook; the default accepts loopback peers only.
  new({
    required this._http,
    this._onUnauthorized,
    Random? random,
    bool Function(InternetAddress peer)? allowPeer,
  }) : _random = random ?? Random.secure(),
       _allowPeer = allowPeer ?? _isLoopback;

  static bool _isLoopback(InternetAddress peer) => peer.isLoopback;

  /// Headers the proxy forwards to the remote device.
  static const List<String> forwardedRequestHeaders = [
    HttpHeaders.rangeHeader,
    HttpHeaders.ifRangeHeader,
  ];

  /// Headers the proxy copies back to the player (besides content-length,
  /// which goes through [HttpResponse.contentLength]).
  static const List<String> copiedResponseHeaders = [
    HttpHeaders.contentTypeHeader,
    HttpHeaders.contentRangeHeader,
    HttpHeaders.acceptRangesHeader,
    HttpHeaders.etagHeader,
  ];

  final RemoteHttp Function() _http;
  final void Function()? _onUnauthorized;
  final Random _random;
  final bool Function(InternetAddress peer) _allowPeer;

  /// handle → server id (the other device's own file id).
  final Map<String, String> _handles = {};
  HttpServer? _server;
  StreamSubscription<HttpRequest>? _requests;

  /// The bound port; null before [start] and after [close].
  int? get port => _server?.port;

  /// Binds `127.0.0.1:0`. A second call while running does nothing.
  Future<void> start() async {
    if (_server != null) return;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server = server;
    _requests = server.listen((req) => unawaited(_serve(req)));
  }

  /// E1: asks the other device before [f] streams (a video is a "take"
  /// when its owner wants to be asked). Older devices (404) never ask.
  /// Throws [FileOpException] (`permissionDenied`) when declined or not
  /// answered.
  Future<void> prepare(FileRef f) async {
    final serverId = parseRemoteFileId(f.id).serverId;
    try {
      await _http().postJson<void>(
        ApiRoutes.take,
        {
          'ids': [serverId],
        },
        decode: (_) {},
        timeout: kTakeClientWait,
      );
    } on RemoteApiException catch (e) {
      if (e.code == ApiErrorCode.notFound) return;
      if (e.code == ApiErrorCode.unauthorized) _onUnauthorized?.call();
      throw FileOpException(FileOpFailure.permissionDenied, 'take ${e.code}');
    }
  }

  /// A fresh URL for [f] (a `remote:<fp>:<serverId>` file). Throws
  /// [StateError] before [start] / after [close] or for a non-remote file,
  /// [FormatException] for a malformed remote id.
  Uri urlFor(FileRef f) {
    final p = port;
    if (p == null) throw StateError('LoopbackMediaProxy is not running');
    if (f.origin != FileOrigin.remote) {
      throw StateError('urlFor() needs a remote file');
    }
    final serverId = parseRemoteFileId(f.id).serverId;
    var handle = randomHexId(_random);
    while (_handles.containsKey(handle)) {
      handle = randomHexId(_random);
    }
    _handles[handle] = serverId;
    return Uri(
      scheme: 'http',
      host: InternetAddress.loopbackIPv4.address,
      port: p,
      path: '/m/$handle',
    );
  }

  /// Every URL handed out so far answers 404 from now on.
  void revokeAll() => _handles.clear();

  /// Revokes every handle and stops the server (open streams are cut).
  Future<void> close() async {
    revokeAll();
    final server = _server;
    _server = null;
    await _requests?.cancel();
    _requests = null;
    await server?.close(force: true);
  }

  Future<void> _serve(HttpRequest req) async {
    final res = req.response;
    // The player may hang up at any time; that is not an error for us.
    unawaited(res.done.then<void>((_) {}, onError: (Object _) {}));
    try {
      final peer = req.connectionInfo?.remoteAddress;
      if (peer == null || !_allowPeer(peer)) {
        return await _status(res, HttpStatus.forbidden);
      }
      final isHead = req.method == 'HEAD';
      final segments = req.uri.pathSegments;
      if ((req.method != 'GET' && !isHead) ||
          segments.length != 2 ||
          segments[0] != 'm') {
        return await _status(res, HttpStatus.notFound);
      }
      final serverId = _handles[segments[1]];
      if (serverId == null) return await _status(res, HttpStatus.notFound);

      final headers = <String, String>{
        for (final name in forwardedRequestHeaders)
          name: ?req.headers.value(name),
      };
      final HttpClientResponse up;
      try {
        up = await _http().getStream(
          ApiRoutes.fileContent(serverId),
          headers: headers,
        );
      } on RemoteApiException catch (e) {
        if (e.status == HttpStatus.unauthorized) _onUnauthorized?.call();
        final status =
            e.status == HttpStatus.requestedRangeNotSatisfiable ||
                e.status == HttpStatus.notFound
            ? e.status
            : HttpStatus.badGateway;
        return await _status(res, status);
      } on Object {
        // Unreachable device, timeout, closed client: the player sees a
        // gateway error; the heartbeat reports the disconnect to the UI.
        return await _status(res, HttpStatus.badGateway);
      }
      await _relay(up, res, isHead: isHead);
    } on Object {
      // The player went away mid-response; the socket is already gone.
      await _closeQuietly(res);
    }
  }

  Future<void> _relay(
    HttpClientResponse up,
    HttpResponse res, {
    required bool isHead,
  }) async {
    res.statusCode = up.statusCode;
    for (final name in copiedResponseHeaders) {
      final v = up.headers.value(name);
      if (v != null) res.headers.set(name, v);
    }
    if (up.contentLength >= 0) res.contentLength = up.contentLength;
    if (isHead) {
      await up.listen(null).cancel();
      await res.close();
      return;
    }
    StreamSubscription<List<int>>? sub;
    final body = StreamController<List<int>>(
      onPause: () => sub?.pause(),
      onResume: () => sub?.resume(),
      onCancel: () => sub?.cancel(),
    );
    sub = up.listen(body.add, onError: body.addError, onDone: body.close);
    // Player disconnected → stop pulling bytes from the remote device.
    unawaited(
      res.done.then<void>((_) {}, onError: (Object _) => sub?.cancel()),
    );
    try {
      await res.addStream(body.stream);
      await res.close();
    } finally {
      await sub.cancel();
    }
  }

  static Future<void> _status(HttpResponse res, int status) async {
    res
      ..statusCode = status
      ..contentLength = 0;
    await res.close();
  }

  static Future<void> _closeQuietly(HttpResponse res) async {
    try {
      await res.close();
    } on Object {
      // Already closed or the socket is gone.
    }
  }
}
