import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:kfm/features/connect/data/crypto/identity_proof.dart';
import 'package:kfm/features/connect/data/known_pair_limiter.dart';
import 'package:kfm/features/connect/data/link_invite_store.dart';
import 'package:kfm/features/connect/data/middleware/authenticate.dart';
import 'package:kfm/features/connect/data/pair_nonce_store.dart';
import 'package:kfm/features/connect/data/server_pipeline.dart';
import 'package:kfm/features/connect/domain/connection_request.dart';
import 'package:kfm/features/connect/domain/link.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:shelf/shelf.dart';

/// B's side of `POST /v1/link`: connect back to the caller (A) at
/// [remoteIp]:`dto.port`, pinned to the session's fingerprint. Returns the
/// answer (reverse reached or not).
typedef LinkRequestHandler = Future<LinkResponseDto> Function(
  ClientSession session,
  LinkRequestDto dto,
  String remoteIp,
);

/// A's side of a verified `/v1/link/join`: issue B's session (scope from
/// A's own perms) and answer with its token and roots.
typedef LinkJoinHandler = Future<PairAcceptedDto> Function(
  ClientHelloDto hello,
  LinkInvite invite,
  String remoteIp,
);

/// The bytes a join's identity proof signs: the server fingerprint, the
/// server nonce and `sha256(invite)` (the invite itself never travels
/// twice).
Uint8List linkJoinMessage(
  String serverFingerprint,
  Uint8List nonce,
  Uint8List invite,
) => signedMessage(ProofLabels.linkJoin, [
  Uint8List.fromList(utf8.encode(serverFingerprint)),
  nonce,
  Uint8List.fromList(crypto.sha256.convert(invite).bytes),
]);

Future<Map<String, Object?>?> _body(Request request) async {
  try {
    final json = jsonDecode(await request.readAsString());
    return json is Map<String, Object?> ? json : null;
  } on FormatException {
    return null;
  }
}

/// TASK-E1 two-way link routes:
/// - `POST /v1/link` (authenticated, no file access): the paired client
///   asks this device to connect back ([onLink]). Send-only sessions get
///   403.
/// - `POST /v1/link/join` (unauthenticated: it issues the token): checked
///   in order: [limiter] (429), body, nonce (single use, same IP), the
///   identity proof over [linkJoinMessage], and the invite (single use,
///   60 s, issued for exactly the proven key and the caller's IP). Every
///   failure counts and answers `401 pairing_failed`.
/// - `POST /v1/link/close` (authenticated, no file access): the peer ends
///   the link; both halves go ([onClose]).
List<ServerRoute> linkRoutes({
  required LinkInviteStore invites,
  required PairNonceStore nonces,
  required KnownPairLimiter limiter,
  required Future<String> Function() serverFingerprint,
  required LinkRequestHandler onLink,
  required LinkJoinHandler onJoin,
  required Future<void> Function(ClientSession session) onClose,
}) => [
  ServerRoute('POST', ApiRoutes.link, (request) async {
    final session = sessionOf(request);
    if (session == null) return apiError(ApiErrorCode.unauthorized);
    if (session.sendOnly) return apiError(ApiErrorCode.forbidden);
    final peer = remoteAddressOf(request)?.address;
    if (peer == null) return apiError(ApiErrorCode.forbidden);
    final json = await _body(request);
    final LinkRequestDto dto;
    try {
      if (json == null) throw const FormatException();
      dto = LinkRequestDto.fromJson(json);
      final invite = fromB64url(dto.invite);
      if (invite == null || invite.length != kLinkInviteBytes) {
        throw const FormatException('bad invite');
      }
    } on FormatException {
      return apiError(ApiErrorCode.pairingFailed);
    }
    return jsonOk((await onLink(session, dto, peer)).toJson());
  }),
  ServerRoute('POST', ApiRoutes.linkJoin, (request) async {
    final peer = remoteAddressOf(request)?.address;
    if (peer == null) return apiError(ApiErrorCode.forbidden);
    if (limiter.isLocked(peer)) return apiError(ApiErrorCode.tooManyAttempts);
    Response fail() {
      limiter.recordFailure(peer);
      return apiError(ApiErrorCode.pairingFailed);
    }

    final json = await _body(request);
    final LinkJoinRequestDto dto;
    try {
      if (json == null) throw const FormatException();
      dto = LinkJoinRequestDto.fromJson(json);
    } on FormatException {
      return fail();
    }
    final nonce = fromB64url(dto.nonce);
    final invite = fromB64url(dto.invite);
    final sig = fromB64url(dto.sig);
    // Always consume the nonce (single use, success or not).
    final nonceOk = nonce != null && nonces.consume(peer, nonce);
    if (!nonceOk || invite == null || sig == null) return fail();
    final serverFp = await serverFingerprint();
    final provenFp = verifyIdentityProof(
      certPem: dto.hello.clientCertPem,
      message: linkJoinMessage(serverFp, nonce, invite),
      sig: sig,
    );
    if (provenFp == null) return fail();
    final hit = invites.consume(
      invite,
      provenFingerprint: provenFp,
      remoteIp: peer,
    );
    if (hit == null) return fail();
    return jsonOk((await onJoin(dto.hello, hit, peer)).toJson());
  }),
  ServerRoute('POST', ApiRoutes.linkClose, (request) async {
    final session = sessionOf(request);
    if (session == null) return apiError(ApiErrorCode.unauthorized);
    await onClose(session);
    return Response(204);
  }),
];

/// `POST /v1/link/join` body: like `/v1/pair/known` plus the invite.
final class LinkJoinRequestDto {
  const new({
    required this.hello,
    required this.invite,
    required this.nonce,
    required this.sig,
  });

  factory fromJson(Map<String, Object?> json) {
    final hello = json['hello'];
    final invite = json['invite'];
    final nonce = json['nonce'];
    final sig = json['sig'];
    if (hello is! Map<String, Object?> ||
        invite is! String ||
        nonce is! String ||
        sig is! String) {
      throw const FormatException('bad join body');
    }
    return LinkJoinRequestDto(
      hello: ClientHelloDto.fromJson(hello),
      invite: invite,
      nonce: nonce,
      sig: sig,
    );
  }

  final ClientHelloDto hello;
  final String invite;
  final String nonce;
  final String sig;

  Map<String, Object?> toJson() => {
    'hello': hello.toJson(),
    'invite': invite,
    'nonce': nonce,
    'sig': sig,
  };
}
