import 'dart:convert';
import 'dart:io';

import 'package:kfm/features/connect/data/pinned_client.dart';
import 'package:kfm/features/connect/data/remote_errors.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:shelf/shelf.dart';

class FakeConnectionInfo implements HttpConnectionInfo {
  new(String ip) : remoteAddress = InternetAddress(ip);

  @override
  final InternetAddress remoteAddress;

  @override
  int get localPort => 4433;

  @override
  int get remotePort => 50000;
}

/// Builds a request as shelf_io would, from [ip].
Request fakeRequest(
  String method,
  String path, {
  String ip = '192.168.1.40',
  Object? body,
}) => Request(
  method,
  Uri.parse('https://192.168.1.23:4433$path'),
  body: body == null ? null : jsonEncode(body),
  headers: {'content-type': 'application/json'},
  context: {'shelf.io.connection_info': FakeConnectionInfo(ip)},
);

/// A [FirstContactHttp] that calls a shelf [Handler] in-process (no TLS):
/// the "certificate" it sees is [serverFingerprint]. Lets N2 tests run the
/// real `PairingClient` against the real routes.
class HandlerRemoteHttp implements FirstContactHttp {
  new(
    this.handler, {
    required this.serverFingerprint,
    this.ip = '192.168.1.40',
    Uri? base,
  }) : base = base ?? Uri.parse('https://192.168.1.23:4433');

  final Handler handler;
  final String serverFingerprint;
  final String ip;

  @override
  final Uri base;

  @override
  String? bearerToken;

  /// "METHOD path" of every request that reached [handler].
  final List<String> sent = [];

  /// Bodies sent, in order.
  final List<Object?> bodies = [];
  bool closed = false;
  bool promoted = false;

  @override
  String? get seenFingerprint => serverFingerprint;

  @override
  RemoteHttp promote() {
    promoted = true;
    return this;
  }

  Future<T> _send<T>(
    String method,
    String path,
    Object? body,
    T Function(Map<String, Object?> json) decode,
  ) async {
    if (closed) {
      throw const RemoteUnavailableException(RemoteUnavailableReason.network);
    }
    sent.add('$method $path');
    bodies.add(body);
    final res = await handler(fakeRequest(method, path, ip: ip, body: body));
    final text = await res.readAsString();
    final json = text.isEmpty
        ? const <String, Object?>{}
        : jsonDecode(text) as Map<String, Object?>;
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw RemoteApiException(res.statusCode, ApiErrorDto.fromJson(json));
    }
    return decode(json);
  }

  @override
  Future<T> getJson<T>(
    String path, {
    required T Function(Map<String, Object?> json) decode,
    Map<String, String> query = const {},
  }) => _send('GET', path, null, decode);

  @override
  Future<T> postJson<T>(
    String path,
    Object? body, {
    required T Function(Map<String, Object?> json) decode,
    Duration? timeout,
  }) => _send('POST', path, body, decode);

  @override
  Future<T> deleteJson<T>(
    String path, {
    required T Function(Map<String, Object?> json) decode,
  }) => _send('DELETE', path, null, decode);

  @override
  Future<HttpClientResponse> getStream(
    String path, {
    Map<String, String> query = const {},
    Map<String, String> headers = const {},
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
  void close() => closed = true;
}
