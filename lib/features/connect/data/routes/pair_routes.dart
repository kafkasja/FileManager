import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:kfm/features/connect/data/crypto/constant_time.dart';
import 'package:kfm/features/connect/data/crypto/identity_proof.dart';
import 'package:kfm/features/connect/data/crypto/spake2.dart';
import 'package:kfm/features/connect/data/pair_nonce_store.dart';
import 'package:kfm/features/connect/data/pairing_secret_store.dart';
import 'package:kfm/features/connect/data/server_pipeline.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';

/// How a client proved it may ask to pair.
enum PairMethod { qr, code }

/// A pairing request that passed every N2 check: the secret/code is already
/// consumed and the identity proof verified. N3 decides (accept prompt).
@immutable
class PairCandidate {
  const new({
    required this.hello,
    required this.clientFingerprint,
    required this.remoteIp,
    required this.method,
  });

  final ClientHelloDto hello;

  /// `sha256(cert DER)`, derived by the server from the verified cert.
  final String clientFingerprint;
  final String remoteIp;
  final PairMethod method;
}

/// Hands a verified request to N3; the returned response answers the held
/// `POST /v1/pair` (200 `PairAcceptedDto`, 403 `declined`/`timed_out`, …).
typedef PairHandOff = Future<Response> Function(PairCandidate candidate);

/// How long N3 holds `/v1/pair` for the decision.
const Duration kPairDecisionTimeout = Duration(seconds: 60);

/// N2 stand-in until N3's accept prompt exists: holds the request for the
/// decision window, then answers `403 timed_out` (nobody can accept yet).
Future<Response> holdUntilTimeout(PairCandidate candidate) async {
  await Future<void>.delayed(kPairDecisionTimeout);
  return apiError(ApiErrorCode.timedOut);
}

/// `POST /v1/pair/code/start` and `POST /v1/pair` (TASK-N2).
List<ServerRoute> pairRoutes({
  required PairingSecretStore secrets,
  required PairNonceStore nonces,
  required PairHandOff handOff,
}) => [
  ServerRoute(
    'POST',
    ApiRoutes.pairCodeStart,
    (request) => _codeStart(request, secrets),
  ),
  ServerRoute(
    'POST',
    ApiRoutes.pair,
    (request) => _pair(request, secrets, nonces, handOff),
  ),
];

Future<Map<String, Object?>?> _body(Request request) async {
  try {
    final json = jsonDecode(await request.readAsString());
    return json is Map<String, Object?> ? json : null;
  } on FormatException {
    return null;
  }
}

Uint8List _utf8(String s) => Uint8List.fromList(utf8.encode(s));

Uint8List _sha256(List<int> b) =>
    Uint8List.fromList(crypto.sha256.convert(b).bytes);

Future<Response> _codeStart(Request request, PairingSecretStore secrets) async {
  final peer = remoteAddressOf(request)?.address;
  if (peer == null) return apiError(ApiErrorCode.forbidden);
  final json = await _body(request);
  final CodeStartRequestDto dto;
  try {
    if (json == null) throw const FormatException();
    dto = CodeStartRequestDto.fromJson(json);
  } on FormatException {
    return apiError(ApiErrorCode.pairingFailed);
  }
  final serverFp = secrets.serverFingerprint;
  if (serverFp == null) return apiError(ApiErrorCode.pairingFailed);

  // Counted the moment it is made (rule 4), before any validation.
  final decision = secrets.beginCodeAttempt(peer);
  final String code;
  switch (decision) {
    case CodeStartRefused(:final error):
      return apiError(error);
    case CodeStartGranted(code: final c):
      code = c.value;
  }

  final clientFp = certFingerprint(dto.hello.clientCertPem);
  final pA = fromB64url(dto.pA);
  if (clientFp == null || pA == null) {
    return apiError(ApiErrorCode.pairingFailed);
  }
  final result = spake2Respond(
    w: spake2PasswordScalar(code),
    idA: _utf8(clientFp),
    idB: _utf8(serverFp),
    pA: pA,
    aad: _utf8(kSpake2Aad),
  );
  if (result == null) return apiError(ApiErrorCode.pairingFailed);
  final attemptId = secrets.addAttempt(
    remoteIp: peer,
    clientCertPem: dto.hello.clientCertPem,
    transcript: result.keys.tt,
    expectedConfirmA: result.keys.confirmA,
  );
  return jsonOk(
    CodeStartResponseDto(
      attemptId: attemptId,
      pB: b64url(result.pB),
      confirmB: b64url(result.keys.confirmB),
    ).toJson(),
  );
}

Future<Response> _pair(
  Request request,
  PairingSecretStore secrets,
  PairNonceStore nonces,
  PairHandOff handOff,
) async {
  final peer = remoteAddressOf(request)?.address;
  if (peer == null) return apiError(ApiErrorCode.forbidden);
  final json = await _body(request);
  final PairRequestDto dto;
  try {
    if (json == null) throw const FormatException();
    dto = PairRequestDto.fromJson(json);
  } on FormatException {
    return apiError(ApiErrorCode.pairingFailed);
  }
  final serverFp = secrets.serverFingerprint;
  if (serverFp == null) return apiError(ApiErrorCode.pairingFailed);

  final hello = dto.hello;
  switch (dto.credential) {
    case QrCredential(:final secret, :final nonce, :final sig):
      final nonceBytes = fromB64url(nonce);
      final secretBytes = fromB64url(secret);
      final sigBytes = fromB64url(sig);
      // Always consume the nonce (single use, success or not).
      final nonceOk = nonceBytes != null && nonces.consume(peer, nonceBytes);
      final match = secretBytes == null
          ? QrSecretMatch.none
          : secrets.matchQrSecret(secretBytes);
      String? clientFp;
      if (nonceOk &&
          match == QrSecretMatch.active &&
          sigBytes != null &&
          secretBytes != null) {
        clientFp = verifyIdentityProof(
          certPem: hello.clientCertPem,
          message: signedMessage(ProofLabels.pairQr, [
            _utf8(serverFp),
            nonceBytes,
            _sha256(secretBytes),
          ]),
          sig: sigBytes,
        );
      }
      if (clientFp == null) {
        if (secrets.recordQrFailure()) {
          return apiError(ApiErrorCode.tooManyAttempts);
        }
        return apiError(switch (match) {
          QrSecretMatch.used => ApiErrorCode.secretUsed,
          QrSecretMatch.expired => ApiErrorCode.expired,
          _ => ApiErrorCode.pairingFailed,
        });
      }
      // Consumed before the accept prompt: a second device gets secret_used.
      secrets.consumeQr();
      return await handOff(
        PairCandidate(
          hello: hello,
          clientFingerprint: clientFp,
          remoteIp: peer,
          method: PairMethod.qr,
        ),
      );
    case CodeCredential(:final attemptId, :final confirmA, :final sig):
      // Deleted either way; failures were already counted at /code/start.
      final attempt = secrets.takeAttempt(attemptId, peer);
      final confirmBytes = fromB64url(confirmA);
      final sigBytes = fromB64url(sig);
      if (attempt == null || confirmBytes == null || sigBytes == null) {
        return apiError(ApiErrorCode.pairingFailed);
      }
      final confirmOk = constantTimeEquals(
        confirmBytes,
        attempt.expectedConfirmA,
      );
      if (!confirmOk || hello.clientCertPem != attempt.clientCertPem) {
        return apiError(ApiErrorCode.pairingFailed);
      }
      final clientFp = verifyIdentityProof(
        certPem: hello.clientCertPem,
        message: signedMessage(ProofLabels.pairCode, [
          _utf8(serverFp),
          _sha256(attempt.transcript),
        ]),
        sig: sigBytes,
      );
      if (clientFp == null) return apiError(ApiErrorCode.pairingFailed);
      secrets.consumeCode();
      return await handOff(
        PairCandidate(
          hello: hello,
          clientFingerprint: clientFp,
          remoteIp: peer,
          method: PairMethod.code,
        ),
      );
  }
}
