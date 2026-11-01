import 'package:kfm/features/connect/data/client_session_store.dart';
import 'package:kfm/features/connect/data/server_pipeline.dart';
import 'package:kfm/features/connect/domain/connection_request.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:shelf/shelf.dart';

/// Request-context key of the authenticated [ClientSession] (N4/N7 read it).
const String kSessionContextKey = 'kfm.session';

/// The session [authenticate] attached to [request]; null on the
/// unauthenticated routes.
ClientSession? sessionOf(Request request) {
  final s = request.context[kSessionContextKey];
  return s is ClientSession ? s : null;
}

final RegExp _bearer = RegExp(r'^Bearer ([A-Za-z0-9_\-]{1,128})$');

/// 3. `authenticate` (TASK-N3, replaces N1's deny-all stub): routes in
/// [kUnauthenticatedRoutes] pass; everything else needs
/// `Authorization: Bearer <token>` of a live session, or gets
/// `401 unauthorized` without detail. The session is touched and attached
/// to the request context.
Middleware authenticate(ClientSessionStore sessions) =>
    (inner) => (request) {
      if (kUnauthenticatedRoutes.contains(
        routeKey(request.method, requestPath(request)),
      )) {
        return inner(request);
      }
      final header = request.headers['authorization'];
      final match = header == null ? null : _bearer.firstMatch(header.trim());
      final session = match == null ? null : sessions.verify(match.group(1)!);
      if (session == null) return apiError(ApiErrorCode.unauthorized);
      return inner(request.change(context: {kSessionContextKey: session}));
    };
