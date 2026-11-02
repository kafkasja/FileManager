import 'dart:convert';

import 'package:kfm/features/connect/data/middleware/allow_list.dart';
import 'package:kfm/features/connect/data/middleware/authenticate.dart';
import 'package:kfm/features/connect/data/offer_service.dart';
import 'package:kfm/features/connect/data/server_pipeline.dart';
import 'package:kfm/features/connect/domain/offer_protocol.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:shelf/shelf.dart';

/// Whether [request] creates an offer: its body (up to 500 files) has its
/// own limit, [kMaxOfferBodyBytes], instead of the 64 KB JSON limit
/// (`buildSharePipeline(sizeLimitExempt:)`).
bool isOfferCreateRequest(Request request) =>
    request.method == 'POST' && request.requestedUri.path == ApiRoutes.offers;

/// Reads a JSON object body of at most [max] bytes; null when too large
/// or malformed.
Future<Map<String, Object?>?> readJsonBody(
  Request request, {
  int max = kMaxJsonBodyBytes,
}) async {
  final declared = request.contentLength;
  if (declared != null && declared > max) return null;
  final bytes = <int>[];
  await for (final chunk in request.read()) {
    bytes.addAll(chunk);
    if (bytes.length > max) return null;
  }
  try {
    final v = jsonDecode(utf8.decode(bytes));
    return v is Map<String, Object?> ? v : null;
  } on FormatException {
    return null;
  }
}

/// TASK-N12 push routes (`kNoFileAccessRoutes`: they touch no file; the
/// bytes go through the guarded upload routes into `offer:<id>`).
/// - `POST /v1/offers`: create (201) or the idempotent repeat (200).
/// - `GET /v1/offers/<id>`: status; another owner's id is 404.
/// - `DELETE /v1/offers/<id>`: the sender cancels.
List<ServerRoute> offerRoutes(OfferService Function() service) => [
  ServerRoute('POST', ApiRoutes.offers, (request) async {
    final session = sessionOf(request);
    if (session == null) return apiError(ApiErrorCode.unauthorized);
    final json = await readJsonBody(request, max: kMaxOfferBodyBytes);
    if (json == null) return apiError(ApiErrorCode.tooLarge);
    final CreateOfferDto dto;
    try {
      dto = CreateOfferDto.fromJson(json);
    } on FormatException {
      return apiError(ApiErrorCode.invalidName, 'bad offer');
    }
    final r = await service().create(session, dto);
    if (r.error case final e?) return apiError(e);
    return Response(
      r.status,
      body: jsonEncode(r.offer!.toJson()),
      headers: const {
        'content-type': 'application/json; charset=utf-8',
        'cache-control': 'no-store',
      },
    );
  }),
  ServerRoute('GET', ApiRoutes.offerIdPattern, (request) async {
    final session = sessionOf(request);
    if (session == null) return apiError(ApiErrorCode.unauthorized);
    final String id;
    try {
      id = routeParam(request, 'id');
    } on FormatException {
      return apiError(ApiErrorCode.notFound);
    }
    final dto = await service().status(session.clientFingerprint, id);
    if (dto == null) return apiError(ApiErrorCode.notFound);
    return jsonOk(dto.toJson());
  }),
  ServerRoute('DELETE', ApiRoutes.offerIdPattern, (request) async {
    final session = sessionOf(request);
    if (session == null) return apiError(ApiErrorCode.unauthorized);
    final String id;
    try {
      id = routeParam(request, 'id');
    } on FormatException {
      return apiError(ApiErrorCode.notFound);
    }
    final dto = await service().cancelBySender(session.clientFingerprint, id);
    if (dto == null) return apiError(ApiErrorCode.notFound);
    return jsonOk(dto.toJson());
  }),
];
