import 'dart:async';
import 'dart:io';

import 'package:kfm/features/connect/data/pinned_client.dart';
import 'package:kfm/features/connect/data/remote_errors.dart';
import 'package:kfm/features/connect/domain/protocol.dart';

/// One recorded call to [FakeRemoteHttp].
typedef FakeRemoteCall = ({
  String method,
  String path,
  Map<String, String> query,
  Object? body,
  String? token,
});

/// Answers a JSON call: return the response JSON, or throw
/// [RemoteApiException] / [RemoteUnavailableException].
typedef FakeJsonHandler = FutureOr<Map<String, Object?>> Function(
  FakeRemoteCall call,
);

/// In-memory [RemoteHttp] for N2/N5/N7/N10 tests (TASK-N1). Register
/// answers per route key (`'GET /v1/info'`); unknown routes answer
/// `404 not_found` like the real server.
class FakeRemoteHttp implements RemoteHttp {
  new({Uri? base}) : base = base ?? Uri.parse('https://192.168.1.20:4433');

  @override
  final Uri base;

  @override
  String? bearerToken;

  final Map<RouteKey, FakeJsonHandler> json = {};

  /// Streaming answers (getStream) per route key.
  final Map<RouteKey, Future<HttpClientResponse> Function(FakeRemoteCall)>
  streams = {};

  /// Every call, in order.
  final List<FakeRemoteCall> calls = [];

  /// When set, every call fails with it (e.g. the device went away).
  Object? failAll;

  bool closed = false;

  /// Registers [answer] for `METHOD path`.
  void on(String method, String path, FakeJsonHandler answer) =>
      json[routeKey(method, path)] = answer;

  /// Makes `METHOD path` fail with an API error.
  void fail(String method, String path, ApiErrorCode code) => on(
    method,
    path,
    (_) => throw RemoteApiException(code.status, ApiErrorDto(code.wire, '')),
  );

  Future<T> _call<T>(
    String method,
    String path,
    Map<String, String> query,
    Object? body,
    T Function(Map<String, Object?> json) decode,
  ) async {
    if (closed) throw StateError('FakeRemoteHttp is closed');
    final call = (
      method: method,
      path: path,
      query: query,
      body: body,
      token: bearerToken,
    );
    calls.add(call);
    final fail = failAll;
    // ignore: only_throw_errors, the test decides what to throw
    if (fail != null) throw fail;
    final handler = json[routeKey(method, path)];
    if (handler == null) {
      throw RemoteApiException(
        404,
        ApiErrorDto(ApiErrorCode.notFound.wire, ''),
      );
    }
    return decode(await handler(call));
  }

  @override
  Future<T> getJson<T>(
    String path, {
    required T Function(Map<String, Object?> json) decode,
    Map<String, String> query = const {},
  }) => _call('GET', path, query, null, decode);

  @override
  Future<T> postJson<T>(
    String path,
    Object? body, {
    required T Function(Map<String, Object?> json) decode,
    Duration? timeout,
  }) => _call('POST', path, const {}, body, decode);

  @override
  Future<T> deleteJson<T>(
    String path, {
    required T Function(Map<String, Object?> json) decode,
  }) => _call('DELETE', path, const {}, null, decode);

  @override
  Future<HttpClientResponse> getStream(
    String path, {
    Map<String, String> query = const {},
    Map<String, String> headers = const {},
  }) async {
    if (closed) throw StateError('FakeRemoteHttp is closed');
    final call = (
      method: 'GET',
      path: path,
      query: query,
      body: null,
      token: bearerToken,
    );
    calls.add(call);
    final fail = failAll;
    // ignore: only_throw_errors, the test decides what to throw
    if (fail != null) throw fail;
    final handler = streams[routeKey('GET', path)];
    if (handler == null) {
      throw RemoteApiException(
        404,
        ApiErrorDto(ApiErrorCode.notFound.wire, ''),
      );
    }
    return await handler(call);
  }

  @override
  Future<T> putStream<T>(
    String path,
    Stream<List<int>> body,
    int length, {
    required T Function(Map<String, Object?> json) decode,
    Map<String, String> query = const {},
  }) async {
    final bytes = <int>[];
    await body.forEach(bytes.addAll);
    return await _call('PUT', path, query, bytes, decode);
  }

  @override
  void close() => closed = true;
}
