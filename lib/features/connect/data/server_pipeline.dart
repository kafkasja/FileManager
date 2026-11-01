import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:kfm/features/connect/data/crypto/identity_proof.dart';
import 'package:kfm/features/connect/data/pair_nonce_store.dart';
import 'package:kfm/features/connect/data/share_server.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// One registered route. Routes are a plain list (not only a shelf Router)
/// so N4's route-coverage test can enumerate them.
@immutable
class ServerRoute {
  const new(this.method, this.path, this.handler);

  final String method;

  /// shelf_router syntax, e.g. `/v1/files/<id>`.
  final String path;
  final Handler handler;

  RouteKey get key => routeKey(method, path);
}

/// JSON error response with the code's HTTP status (no stack traces).
Response apiError(ApiErrorCode code, [String message = '']) => Response(
  code.status,
  body: jsonEncode(ApiErrorDto(code.wire, message).toJson()),
  headers: _jsonHeaders,
);

/// 200 JSON response.
Response jsonOk(Object? body) =>
    Response.ok(jsonEncode(body), headers: _jsonHeaders);

const Map<String, String> _jsonHeaders = {
  HttpHeaders.contentTypeHeader: 'application/json; charset=utf-8',
  HttpHeaders.cacheControlHeader: 'no-store',
};

/// The peer's IP (from shelf_io's connection info); null if unknown.
InternetAddress? remoteAddressOf(Request request) {
  final info = request.context['shelf.io.connection_info'];
  return info is HttpConnectionInfo ? info.remoteAddress : null;
}

/// Exact request path with a leading slash (`/v1/info`).
String requestPath(Request request) => request.requestedUri.path;

/// Whether [peer] is in the same subnet as one of [served] (prefix compare).
@visibleForTesting
bool sameSubnet(InternetAddress peer, List<LocalAddress> served) {
  if (peer.type != InternetAddressType.IPv4) return false;
  final p = _ipv4(peer);
  for (final s in served) {
    if (s.address.type != InternetAddressType.IPv4) continue;
    final bits = s.prefixLength.clamp(0, 32);
    final mask = bits == 0 ? 0 : (0xFFFFFFFF << (32 - bits)) & 0xFFFFFFFF;
    if ((p & mask) == (_ipv4(s.address) & mask)) return true;
  }
  return false;
}

int _ipv4(InternetAddress a) {
  final b = a.rawAddress;
  return (b[0] << 24) | (b[1] << 16) | (b[2] << 8) | b[3];
}

/// 1. Rejects (403 `forbidden`) every peer outside the served subnets.
Middleware privateNetworkOnly(List<LocalAddress> served) =>
    (inner) => (request) {
      final peer = remoteAddressOf(request);
      if (peer == null || !sameSubnet(peer, served)) {
        return apiError(ApiErrorCode.forbidden);
      }
      return inner(request);
    };

/// 2. JSON bodies over [maxBytes] → 413 `too_large`. Routes for which
/// [exempt] is true (N10's chunk route) enforce their own limit.
Middleware requestSizeLimit({
  int maxBytes = kMaxJsonBodyBytes,
  bool Function(Request request)? exempt,
}) => (inner) => (request) async {
  if (exempt != null && exempt(request)) return await inner(request);
  final declared = request.contentLength;
  if (declared != null) {
    if (declared > maxBytes) return apiError(ApiErrorCode.tooLarge);
    return await inner(request);
  }
  // No Content-Length (chunked): buffer up to the limit.
  final out = BytesBuilder(copy: false);
  await for (final chunk in request.read()) {
    out.add(chunk);
    if (out.length > maxBytes) return apiError(ApiErrorCode.tooLarge);
  }
  return await inner(request.change(body: out.takeBytes()));
};

/// 3. N1 stub of N3's `authenticate`: every route outside
/// [kUnauthenticatedRoutes] gets 401 until N3 replaces it.
Middleware denyAllAuthenticate() =>
    (inner) => (request) {
      if (kUnauthenticatedRoutes.contains(
        routeKey(request.method, requestPath(request)),
      )) {
        return inner(request);
      }
      return apiError(ApiErrorCode.unauthorized);
    };

/// Outermost: any uncaught error → 500 `internal` (logged without bodies).
Middleware _internalErrors() =>
    (inner) => (request) async {
      try {
        return await inner(request);
      } on HijackException {
        rethrow;
      } on Object catch (e) {
        developer.log(
          'share server: ${request.method} ${requestPath(request)} failed: '
          '${e.runtimeType}',
          name: 'kfm.connect',
        );
        return apiError(ApiErrorCode.internal);
      }
    };

/// The fixed middleware chain + deny-by-default router (TASK-N1):
/// `privateNetworkOnly` → `requestSizeLimit` → `authenticate` → router.
/// Later tasks add [routes] and replace [authenticate] (N3); N4's allow-list
/// is a per-route `guarded(...)` wrapper, not a middleware.
Handler buildSharePipeline({
  required List<LocalAddress> served,
  required List<ServerRoute> routes,
  Middleware? authenticate,
  bool Function(Request request)? sizeLimitExempt,
}) {
  final router = Router(
    notFoundHandler: (_) => apiError(ApiErrorCode.notFound),
  );
  final seen = <RouteKey>{};
  for (final r in routes) {
    if (!seen.add(r.key)) throw ArgumentError('duplicate route ${r.key}');
    router.add(r.method, r.path, r.handler);
  }
  return const Pipeline()
      .addMiddleware(_internalErrors())
      .addMiddleware(privateNetworkOnly(served))
      .addMiddleware(requestSizeLimit(exempt: sizeLimitExempt))
      .addMiddleware(authenticate ?? denyAllAuthenticate())
      .addHandler(router.call);
}

/// The routes N1 owns: `GET /v1/info` and `POST /v1/pair/nonce`.
List<ServerRoute> coreRoutes({
  required Future<ServerInfoDto> Function() info,
  required PairNonceStore nonces,
}) => [
  ServerRoute('GET', ApiRoutes.info, (_) async => jsonOk((await info()).toJson())),
  ServerRoute('POST', ApiRoutes.pairNonce, (request) {
    final peer = remoteAddressOf(request);
    if (peer == null) return apiError(ApiErrorCode.forbidden);
    final nonce = nonces.issue(peer.address);
    return jsonOk(
      PairNonceDto(
        nonce: b64url(nonce),
        expiresInSeconds: kPairNonceLifetime.inSeconds,
      ).toJson(),
    );
  }),
];
