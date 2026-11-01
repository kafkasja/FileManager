import 'package:kfm/features/connect/data/client_session_store.dart';
import 'package:kfm/features/connect/data/middleware/authenticate.dart';
import 'package:kfm/features/connect/data/server_pipeline.dart';
import 'package:kfm/features/connect/domain/files_protocol.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:shelf/shelf.dart';

/// TASK-N5 session routes. Both touch no files (`kNoFileAccessRoutes`).
/// - `GET /v1/session`: the client's heartbeat. `authenticate` already
///   touched the session (401 comes from `authenticate` when the token is
///   gone). Since N7 it answers 200 `SessionDto{changeToken}` from
///   [changeToken] (live sync); without one, 204 as in N5.
/// - `POST /v1/session/close`: the client ends its own session (Disconnect
///   or app exit); the body is ignored.
List<ServerRoute> sessionRoutes(
  ClientSessionStore sessions, {
  Future<String?> Function(String clientFingerprint)? changeToken,
}) => [
  ServerRoute('GET', ApiRoutes.session, (request) async {
    final session = sessionOf(request);
    if (session == null) return apiError(ApiErrorCode.unauthorized);
    if (changeToken == null) return Response(204);
    final token = await changeToken(session.clientFingerprint);
    return jsonOk(SessionDto(changeToken: token).toJson());
  }),
  ServerRoute('POST', ApiRoutes.sessionClose, (request) {
    final session = sessionOf(request);
    if (session == null) return apiError(ApiErrorCode.unauthorized);
    sessions.revoke(session.sessionId);
    return Response(204);
  }),
];
