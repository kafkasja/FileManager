import 'package:kfm/features/connect/data/pinned_client.dart';
import 'package:kfm/features/connect/domain/offer_protocol.dart';
import 'package:kfm/features/connect/domain/protocol.dart';

/// The sender's calls for send-files offers (TASK-N12), over the pinned
/// [RemoteHttp] of the live connection. Errors are thrown as they come
/// (`RemoteApiException`, `RemoteUnavailableException`).
class OfferClient {
  const new(this._http);

  final RemoteHttp _http;

  /// `POST /v1/offers` (idempotent: a repeat answers the current state).
  Future<OfferDto> create(String offerId, List<OfferFileDto> files) =>
      _http.postJson(
        ApiRoutes.offers,
        CreateOfferDto(offerId: offerId, files: files).toJson(),
        decode: OfferDto.fromJson,
      );

  Future<OfferDto> status(String offerId) =>
      _http.getJson(ApiRoutes.offer(offerId), decode: OfferDto.fromJson);

  /// The sender cancels (or ends a job with files it gave up on).
  Future<OfferDto> cancel(String offerId) =>
      _http.deleteJson(ApiRoutes.offer(offerId), decode: OfferDto.fromJson);

  // ---- N12b: offers the other device makes to us ----

  Future<InboxDto> inbox() =>
      _http.getJson(ApiRoutes.inbox, decode: InboxDto.fromJson);

  Future<void> accept(String offerId) => _http.postJson<void>(
    ApiRoutes.inboxAccept(offerId),
    const <String, Object?>{},
    decode: (_) {},
  );

  Future<void> decline(String offerId) => _http.postJson<void>(
    ApiRoutes.inboxDecline(offerId),
    const <String, Object?>{},
    decode: (_) {},
  );

  Future<void> finished(String offerId, InboxFinishedDto report) =>
      _http.postJson<void>(
        ApiRoutes.inboxFinished(offerId),
        report.toJson(),
        decode: (_) {},
      );
}
