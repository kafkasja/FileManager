import 'package:kfm/features/connect/data/middleware/authenticate.dart';
import 'package:kfm/features/connect/data/server_pipeline.dart';
import 'package:kfm/features/connect/data/share_scope_store.dart';
import 'package:kfm/features/connect/domain/protocol.dart';

/// `GET /v1/roots` (TASK-N4): the caller's shared roots as
/// `{roots:[{id,label,readOnly}]}`. Paths are never sent; the client
/// browses with `rootId` + a relative path.
ServerRoute rootsRoute(ShareScopeStore scopes) =>
    ServerRoute('GET', ApiRoutes.roots, (request) {
      final session = sessionOf(request);
      if (session == null) return apiError(ApiErrorCode.unauthorized);
      // N12: send-only sessions see no folder.
      if (session.sendOnly) return jsonOk(const RootsResponseDto([]).toJson());
      final scope = scopes.scopeOf(session.clientFingerprint);
      return jsonOk(RootsResponseDto(scope.toDtos()).toJson());
    });
