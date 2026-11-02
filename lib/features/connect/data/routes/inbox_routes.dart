import 'package:kfm/features/connect/data/middleware/allow_list.dart';
import 'package:kfm/features/connect/data/middleware/authenticate.dart';
import 'package:kfm/features/connect/data/offer_service.dart';
import 'package:kfm/features/connect/data/routes/offer_routes.dart';
import 'package:kfm/features/connect/data/server_pipeline.dart';
import 'package:kfm/features/connect/domain/offer_protocol.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:shelf/shelf.dart';

/// TASK-N12b reverse routes: offers this (sharing) device makes to a
/// connected client. All in `kNoFileAccessRoutes`: the files themselves go
/// through the guarded N7 file routes (an accepted offer grants reads of
/// exactly its files).
/// - `GET /v1/inbox`: pending offers made to the caller.
/// - `POST /v1/inbox/<id>/accept` / `decline`: the caller's decision;
///   another client's id is 404.
/// - `POST /v1/inbox/<id>/finished {done, failed}`: best-effort end
///   report; the grant ends.
List<ServerRoute> inboxRoutes(OfferService Function() service) {
  Future<Response> decide(Request request, {required bool accept}) async {
    final session = sessionOf(request);
    if (session == null) return apiError(ApiErrorCode.unauthorized);
    final String id;
    try {
      id = routeParam(request, 'id');
    } on FormatException {
      return apiError(ApiErrorCode.notFound);
    }
    final ok = await service().decideOutgoing(
      session.clientFingerprint,
      id,
      accept: accept,
    );
    if (!ok) return apiError(ApiErrorCode.notFound);
    return Response(204);
  }

  return [
    ServerRoute('GET', ApiRoutes.inbox, (request) async {
      final session = sessionOf(request);
      if (session == null) return apiError(ApiErrorCode.unauthorized);
      final offers = await service().inboxFor(session.clientFingerprint);
      return jsonOk(InboxDto(offers).toJson());
    }),
    ServerRoute(
      'POST',
      '${ApiRoutes.inboxIdPattern}/accept',
      (request) => decide(request, accept: true),
    ),
    ServerRoute(
      'POST',
      '${ApiRoutes.inboxIdPattern}/decline',
      (request) => decide(request, accept: false),
    ),
    ServerRoute('POST', '${ApiRoutes.inboxIdPattern}/finished', (
      request,
    ) async {
      final session = sessionOf(request);
      if (session == null) return apiError(ApiErrorCode.unauthorized);
      final String id;
      try {
        id = routeParam(request, 'id');
      } on FormatException {
        return apiError(ApiErrorCode.notFound);
      }
      final json = await readJsonBody(request);
      final InboxFinishedDto report;
      try {
        report = InboxFinishedDto.fromJson(json ?? const {});
      } on FormatException {
        return apiError(ApiErrorCode.notFound);
      }
      final ok = await service().finishedOutgoing(
        session.clientFingerprint,
        id,
        report,
      );
      if (!ok) return apiError(ApiErrorCode.notFound);
      return Response(204);
    }),
  ];
}
