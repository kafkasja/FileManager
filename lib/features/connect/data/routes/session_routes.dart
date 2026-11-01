import 'package:kfm/features/connect/data/client_session_store.dart';
import 'package:kfm/features/connect/data/middleware/authenticate.dart';
import 'package:kfm/features/connect/data/server_pipeline.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:shelf/shelf.dart';

/// TASK-N5 session routes. Both touch no files (`kNoFileAccessRoutes`).
/// - `GET /v1/session`: the client's heartbeat. `authenticate` already
///   touched the session, so it only answers 204 (401 comes from
///   `authenticate` when the token is gone).
/// - `POST /v1/session/close`: the client ends its own session (Disconnect
///   or app exit); the body is ignored.
List<ServerRoute> sessionRoutes(ClientSessionStore sessions) => [
  ServerRoute('GET', ApiRoutes.session, (request) {
    if (sessionOf(request) == null) return apiError(ApiErrorCode.unauthorized);
    return Response(204);
  }),
  ServerRoute('POST', ApiRoutes.sessionClose, (request) {
    final session = sessionOf(request);
    if (session == null) return apiError(ApiErrorCode.unauthorized);
    sessions.revoke(session.sessionId);
    return Response(204);
  }),
];
