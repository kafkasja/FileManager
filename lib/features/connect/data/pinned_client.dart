import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:kfm/features/connect/data/remote_errors.dart';
import 'package:kfm/features/connect/domain/protocol.dart';

/// The small interface every remote caller depends on (N2 `PairingClient`,
/// N5 proxy/heartbeat/thumbnails, N7 `RemoteFileSource`, N9/N10 transfers),
/// so tests use a fake. [PinnedClient] is its only real implementation.
abstract interface class RemoteHttp {
  /// `https://<host>:<port>`.
  Uri get base;

  /// Memory only (N3).
  String? get bearerToken;
  set bearerToken(String? value);

  /// JSON request; non-2xx → throws [RemoteApiException]. [timeout]
  /// defaults to [kDefaultRequestTimeout] (N10: a server-side hash takes
  /// longer).
  Future<T> getJson<T>(
    String path, {
    required T Function(Map<String, Object?> json) decode,
    Map<String, String> query = const {},
    Duration? timeout,
  });

  Future<T> postJson<T>(
    String path,
    Object? body, {
    required T Function(Map<String, Object?> json) decode,
    Duration? timeout,
  });

  /// `DELETE` (N9: cancel an upload); non-2xx → [RemoteApiException].
  Future<T> deleteJson<T>(
    String path, {
    required T Function(Map<String, Object?> json) decode,
  });

  /// Streaming GET (thumb/preview/content, Range); the caller cancels the
  /// subscription.
  Future<HttpClientResponse> getStream(
    String path, {
    Map<String, String> query = const {},
    Map<String, String> headers = const {},
  });

  /// Streaming PUT (N10 chunks).
  Future<T> putStream<T>(
    String path,
    Stream<List<int>> body,
    int length, {
    required T Function(Map<String, Object?> json) decode,
    Map<String, String> query = const {},
  });

  void close();
}

/// A [RemoteHttp] in first-contact mode (N2 short-code path): trusts the
/// first certificate it sees, then [promote] pins it.
abstract interface class FirstContactHttp implements RemoteHttp {
  /// The fingerprint of the first certificate presented; null before any
  /// connection.
  String? get seenFingerprint;

  /// A pinned client for the same base; closes this one.
  RemoteHttp promote();
}

/// Max JSON response the client reads (N7 pages stay far below it).
const int kMaxJsonResponseBytes = 8 * 1024 * 1024;

/// Default request timeout when the caller passes none.
const Duration kDefaultRequestTimeout = Duration(seconds: 30);

/// A chunk upload with no progress (no body bytes taken, no answer) for
/// this long is aborted (Q7 follow-up).
const Duration kPutStallTimeout = Duration(seconds: 30);

/// HTTPS client that trusts exactly one certificate fingerprint (TASK-N1).
///
/// With `withTrustedRoots: false` every certificate fails normal
/// verification, so [HttpClient.badCertificateCallback] runs for every
/// handshake and is the only trust decision: a CA-signed cert for the same IP
/// is still rejected unless its fingerprint matches.
final class PinnedClient implements FirstContactHttp {
  /// Accepts only a server whose cert fingerprint equals
  /// [expectedFingerprint] (from the QR, N6's known_devices row, or a
  /// promoted first contact).
  new pinned(Uri base, String expectedFingerprint)
    : this._(base, expectedFingerprint.toLowerCase());

  /// Short-code path only (N2). Trusts the first fingerprint presented, then
  /// requires every later connection to present the same one. Only the
  /// routes in [firstContactRoutes] may be called (others throw [StateError]
  /// before any byte is sent). Call [promote] after the SPAKE2 confirmation
  /// has been verified.
  new firstContact(Uri base) : this._(base, null);

  new _(this.base, this._pin) : _http = HttpClient(context: SecurityContext()) {
    _http
      ..connectionTimeout = const Duration(seconds: 5)
      ..idleTimeout = const Duration(seconds: 15)
      // Never through a proxy: only the local device (rule 7).
      ..findProxy = ((_) => 'DIRECT')
      ..badCertificateCallback = _trust;
  }

  static const Set<RouteKey> firstContactRoutes = {
    'GET /v1/info',
    'POST /v1/pair/code/start',
  };

  @override
  final Uri base;
  final String? _pin;
  String? _seen;
  bool _pinRejected = false;
  bool _closed = false;
  final HttpClient _http;

  @override
  String? bearerToken;

  /// [putStream]'s no-progress limit (tests shorten it).
  Duration putStallTimeout = kPutStallTimeout;

  /// The first fingerprint a server presented to this client.
  @override
  String? get seenFingerprint => _seen;

  /// Whether this client may only call [firstContactRoutes].
  bool get isFirstContact => _pin == null;

  /// The ONLY trust decision. Visible for the N5 regression test.
  bool _trust(X509Certificate cert, String host, int port) {
    final fp = sha256.convert(cert.der).toString();
    _seen ??= fp;
    final ok = fp == (_pin ?? _seen);
    if (!ok) _pinRejected = true;
    return ok;
  }

  /// Test hook: runs the trust decision on a certificate.
  bool debugTrust(X509Certificate cert) => _trust(cert, base.host, base.port);

  /// New pinned client for the same base; closes this one. Throws
  /// [StateError] if no certificate was seen yet.
  @override
  PinnedClient promote() {
    final seen = _seen;
    if (seen == null) {
      throw StateError('promote() before any certificate was seen');
    }
    final next = PinnedClient.pinned(base, seen)..bearerToken = bearerToken;
    close();
    return next;
  }

  @override
  Future<T> getJson<T>(
    String path, {
    required T Function(Map<String, Object?> json) decode,
    Map<String, String> query = const {},
    Duration? timeout,
  }) => _json(
    'GET',
    path,
    query: query,
    decode: decode,
    timeout: timeout ?? kDefaultRequestTimeout,
  );

  @override
  Future<T> postJson<T>(
    String path,
    Object? body, {
    required T Function(Map<String, Object?> json) decode,
    Duration? timeout,
  }) => _json(
    'POST',
    path,
    body: utf8.encode(jsonEncode(body)),
    decode: decode,
    timeout: timeout ?? kDefaultRequestTimeout,
  );

  @override
  Future<T> deleteJson<T>(
    String path, {
    required T Function(Map<String, Object?> json) decode,
  }) => _json('DELETE', path, decode: decode, timeout: kDefaultRequestTimeout);

  @override
  Future<HttpClientResponse> getStream(
    String path, {
    Map<String, String> query = const {},
    Map<String, String> headers = const {},
  }) => _guard(kDefaultRequestTimeout, () async {
    final req = await _open('GET', path, query);
    headers.forEach(req.headers.set);
    final res = await req.close();
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw await _apiError(res);
    }
    return res;
  });

  @override
  Future<T> putStream<T>(
    String path,
    Stream<List<int>> body,
    int length, {
    required T Function(Map<String, Object?> json) decode,
    Map<String, String> query = const {},
  }) => _guard(null, () async {
    final req = await _open('PUT', path, query);
    req.headers.contentType = ContentType.binary;
    req.contentLength = length;
    // Q7/Q8: no fixed timeout (a chunk on slow Wi-Fi takes a while), but
    // one that stops moving for [putStallTimeout] (a dead-but-open link)
    // is aborted instead of waiting for the heartbeat's teardown. E1: one
    // periodic check instead of a new Timer per 64 KiB.
    final quiet = Stopwatch()..start();
    final limit = putStallTimeout;
    final tick = limit ~/ 4 < const Duration(seconds: 1)
        ? limit ~/ 4
        : const Duration(seconds: 1);
    final stall = Timer.periodic(tick, (t) {
      if (quiet.elapsed < limit) return;
      t.cancel();
      req.abort(TimeoutException('chunk stalled', limit));
    });
    try {
      await req.addStream(
        body.map((b) {
          quiet.reset();
          return b;
        }),
      );
      quiet.reset(); // now waiting for the answer
      final res = await req.close();
      quiet.reset();
      return await _finish(res, decode);
    } finally {
      stall.cancel();
    }
  });

  @override
  void close() {
    if (_closed) return;
    _closed = true;
    _http.close(force: true);
  }

  Future<T> _json<T>(
    String method,
    String path, {
    required T Function(Map<String, Object?> json) decode,
    required Duration timeout,
    Map<String, String> query = const {},
    List<int>? body,
  }) => _guard(timeout, () async {
    final req = await _open(method, path, query);
    req.headers.set(HttpHeaders.acceptHeader, 'application/json');
    if (body != null) {
      req
        ..headers.contentType = ContentType.json
        ..contentLength = body.length
        ..add(body);
    }
    return await _finish(await req.close(), decode);
  });

  Future<HttpClientRequest> _open(
    String method,
    String path,
    Map<String, String> query,
  ) async {
    if (_closed) throw StateError('PinnedClient is closed');
    if (!path.startsWith('/')) throw ArgumentError.value(path, 'path');
    if (_pin == null && !firstContactRoutes.contains(routeKey(method, path))) {
      throw StateError('$method $path is not allowed before promote()');
    }
    final uri = base.replace(
      path: path,
      queryParameters: query.isEmpty ? null : query,
    );
    final req = await _http.openUrl(method, uri);
    req.followRedirects = false;
    final token = bearerToken;
    if (token != null) {
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    }
    return req;
  }

  Future<T> _finish<T>(
    HttpClientResponse res,
    T Function(Map<String, Object?> json) decode,
  ) async {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw await _apiError(res);
    }
    final bytes = await _readCapped(res);
    if (bytes.isEmpty) return decode(const {});
    final Object? json;
    try {
      json = jsonDecode(utf8.decode(bytes));
    } on FormatException catch (e) {
      throw RemoteUnavailableException(RemoteUnavailableReason.badResponse, e);
    }
    if (json is! Map<String, Object?>) {
      throw const RemoteUnavailableException(
        RemoteUnavailableReason.badResponse,
      );
    }
    try {
      return decode(json);
    } on FormatException catch (e) {
      throw RemoteUnavailableException(RemoteUnavailableReason.badResponse, e);
    }
  }

  Future<RemoteApiException> _apiError(HttpClientResponse res) async {
    var error = ApiErrorDto(ApiErrorCode.internal.wire, '');
    try {
      final bytes = await _readCapped(res, max: kMaxJsonBodyBytes);
      final json = jsonDecode(utf8.decode(bytes));
      if (json is Map<String, Object?>) error = ApiErrorDto.fromJson(json);
    } on Object {
      // Not protocol JSON: keep `internal`, the status still tells the caller.
    }
    return RemoteApiException(res.statusCode, error);
  }

  static Future<List<int>> _readCapped(
    HttpClientResponse res, {
    int max = kMaxJsonResponseBytes,
  }) async {
    final out = BytesBuilder(copy: false);
    await for (final chunk in res) {
      out.add(chunk);
      if (out.length > max) {
        throw const RemoteUnavailableException(
          RemoteUnavailableReason.badResponse,
        );
      }
    }
    return out.takeBytes();
  }

  /// Maps transport failures to [RemoteUnavailableException]; API errors,
  /// [StateError] and [ArgumentError] pass through.
  Future<T> _guard<T>(Duration? timeout, Future<T> Function() body) async {
    try {
      final f = body();
      return await (timeout == null ? f : f.timeout(timeout));
    } on RemoteApiException {
      rethrow;
    } on RemoteUnavailableException {
      rethrow;
    } on TimeoutException catch (e) {
      throw RemoteUnavailableException(RemoteUnavailableReason.timeout, e);
    } on HandshakeException catch (e) {
      throw RemoteUnavailableException(
        _pinRejected
            ? RemoteUnavailableReason.pinMismatch
            : RemoteUnavailableReason.network,
        e,
      );
    } on TlsException catch (e) {
      throw RemoteUnavailableException(
        _pinRejected
            ? RemoteUnavailableReason.pinMismatch
            : RemoteUnavailableReason.network,
        e,
      );
    } on SocketException catch (e) {
      throw RemoteUnavailableException(
        isConnectionRefused(e)
            ? RemoteUnavailableReason.refused
            : RemoteUnavailableReason.network,
        e,
      );
    } on HttpException catch (e) {
      throw RemoteUnavailableException(RemoteUnavailableReason.network, e);
    }
  }
}

/// Connection refused (N5): ECONNREFUSED 111 Linux/Android, 61 macOS/iOS;
/// Windows reports WSAECONNREFUSED 10061 or ERROR_CONNECTION_REFUSED 1225
/// (what dart:io gives there).
bool isConnectionRefused(SocketException e) {
  final code = e.osError?.errorCode;
  return code == 111 || code == 61 || code == 10061 || code == 1225;
}
