import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:kfm/core/utils/random_id.dart';
import 'package:kfm/features/connect/data/accept_gate.dart';
import 'package:kfm/features/connect/data/client_session_store.dart';
import 'package:kfm/features/connect/data/crypto/constant_time.dart';
import 'package:kfm/features/connect/data/crypto/identity_proof.dart';
import 'package:kfm/features/connect/data/crypto/spake2.dart';
import 'package:kfm/features/connect/data/known_pair_limiter.dart';
import 'package:kfm/features/connect/data/pair_nonce_store.dart';
import 'package:kfm/features/connect/data/pairing_secret_store.dart';
import 'package:kfm/features/connect/data/server_pipeline.dart';
import 'package:kfm/features/connect/domain/connection_request.dart';
import 'package:kfm/features/connect/domain/fingerprint_words.dart';
import 'package:kfm/features/connect/domain/known_device.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';

/// How a client proved it may ask to pair. `known` = a remembered device's
/// `/v1/pair/known` (N6); it still gets the accept prompt.
enum PairMethod { qr, code, known }

/// A pairing request that passed every N2 check: the secret/code is already
/// consumed and the identity proof verified. N3 decides (accept prompt).
@immutable
class PairCandidate {
  const new({
    required this.hello,
    required this.clientFingerprint,
    required this.remoteIp,
    required this.method,
    required this.serverFingerprint,
    this.autoAccept = false,
  });

  final ClientHelloDto hello;

  /// `sha256(cert DER)`, derived by the server from the verified cert.
  final String clientFingerprint;
  final String remoteIp;
  final PairMethod method;

  /// This device's fingerprint (for the 4-word phrase).
  final String serverFingerprint;

  /// N6 "Always allow": only ever set by `/v1/pair/known` for a verified,
  /// remembered device whose row allows it. QR/code pairings never skip
  /// the prompt.
  final bool autoAccept;
}

/// Hands a verified request to the accept prompt ([promptHandOff]); the
/// returned response answers the held `POST /v1/pair` (200
/// `PairAcceptedDto`, 403 `declined`/`timed_out`, 409 `busy`, 410).
typedef PairHandOff = Future<Response> Function(PairCandidate candidate);

/// How long the accept prompt waits for a decision (N3).
const Duration kPairDecisionTimeout = Duration(seconds: 60);

/// The accept prompt (TASK-N3): every verified request (QR, code and N6's
/// remembered path) waits here for the person holding this device.
/// One prompt at a time (`409 busy`); accept issues a bearer token
/// (`200 PairAcceptedDto`), decline/timeout answer `403`, a client cancel
/// `410`. [roots] gives the client's current roots (N4; empty until then).
/// [beforeIssue] runs on accept before the token and roots are read (N6
/// seeds a remembered device's stored folders there; keep it fast, it runs
/// inside the client's 75 s timeout). A remembered device with "Always
/// allow" skips the prompt but not the busy check (N6).
PairHandOff promptHandOff({
  required AcceptGate gate,
  required ClientSessionStore sessions,
  required Future<String> Function() serverDeviceId,
  List<RootDto> Function(String clientFingerprint)? roots,
  Future<void> Function(PairCandidate candidate)? beforeIssue,
  DateTime Function()? clock,
}) => (candidate) async {
  final hello = candidate.hello;
  // N12: a send-only pairing skips the accept prompt, the folder seeding
  // and the picker: its session reaches no folder (empty scope), so the
  // offer prompt is the one decision. QR/code still needed the code on
  // this screen; `/known` a verified remembered key.
  if (hello.sendOnly) {
    final issued = sessions.issue(
      clientFingerprint: candidate.clientFingerprint,
      clientDeviceId: hello.clientDeviceId,
      clientName: hello.clientName,
      purpose: SessionPurpose.send,
    );
    return jsonOk(
      PairAcceptedDto(
        token: issued.token,
        serverDeviceId: await serverDeviceId(),
        roots: const [],
      ).toJson(),
    );
  }
  final request = ConnectionRequest(
    requestId: randomHexId(),
    pairAttemptId: hello.pairAttemptId,
    remoteIp: candidate.remoteIp,
    clientDeviceId: hello.clientDeviceId,
    clientName: hello.clientName,
    clientPlatform: hello.clientPlatform,
    clientFingerprint: candidate.clientFingerprint,
    remembered: candidate.method == PairMethod.known,
    receivedAt: (clock ?? DateTime.now)(),
    words: fingerprintWords(
      candidate.serverFingerprint,
      candidate.clientFingerprint,
    ),
  );
  final Future<ConnectionDecision> decision;
  if (candidate.method == PairMethod.known && candidate.autoAccept) {
    if (!gate.autoAccept(request)) return apiError(ApiErrorCode.busy);
    decision = Future.value(ConnectionDecision.accepted);
  } else {
    final open = gate.open(request);
    if (open == null) return apiError(ApiErrorCode.busy);
    decision = open;
  }
  switch (await decision) {
    case ConnectionDecision.accepted:
      await beforeIssue?.call(candidate);
      final issued = sessions.issue(
        clientFingerprint: candidate.clientFingerprint,
        clientDeviceId: hello.clientDeviceId,
        clientName: hello.clientName,
      );
      return jsonOk(
        PairAcceptedDto(
          token: issued.token,
          serverDeviceId: await serverDeviceId(),
          roots: roots?.call(candidate.clientFingerprint) ?? const [],
        ).toJson(),
      );
    case ConnectionDecision.declined:
      return apiError(ApiErrorCode.declined);
    case ConnectionDecision.timedOut:
      return apiError(ApiErrorCode.timedOut);
    case ConnectionDecision.cancelled:
      return apiError(ApiErrorCode.cancelled);
  }
};

/// `POST /v1/pair/cancel {pairAttemptId}` (TASK-N3): best effort and
/// unauthenticated; the random attempt id is the capability and must come
/// from the same IP. Always `204` for a well-formed body (an unknown id or
/// another IP is ignored without telling).
ServerRoute pairCancelRoute(AcceptGate gate) =>
    ServerRoute('POST', ApiRoutes.pairCancel, (request) async {
      final peer = remoteAddressOf(request)?.address;
      if (peer == null) return apiError(ApiErrorCode.forbidden);
      final json = await _body(request);
      final id = json?['pairAttemptId'];
      if (id is! String || id.isEmpty || id.length > 64) {
        return apiError(ApiErrorCode.pairingFailed);
      }
      gate.cancel(id, peer);
      return Response(204);
    });

/// `POST /v1/pair/known` (TASK-N6): a remembered device reconnects without
/// a QR. Checked in order: the [limiter] (`429`), the body, the nonce
/// (single use, same IP), the identity proof over
/// `[utf8(serverFp), nonce]`, and that the proven key is a known device.
/// Every failure is counted and answers `401 pairing_failed` (no hint which
/// check failed). Never touches N2's QR secret or code counters.
ServerRoute knownPairRoute({
  required PairNonceStore nonces,
  required KnownPairLimiter limiter,
  required Future<String> Function() serverFingerprint,
  required Future<KnownDevice?> Function(String clientFingerprint) lookup,
  required PairHandOff handOff,
}) => ServerRoute('POST', ApiRoutes.pairKnown, (request) async {
  final peer = remoteAddressOf(request)?.address;
  if (peer == null) return apiError(ApiErrorCode.forbidden);
  if (limiter.isLocked(peer)) return apiError(ApiErrorCode.tooManyAttempts);
  Response fail() {
    limiter.recordFailure(peer);
    return apiError(ApiErrorCode.pairingFailed);
  }

  final json = await _body(request);
  final KnownPairRequestDto dto;
  try {
    if (json == null) throw const FormatException();
    dto = KnownPairRequestDto.fromJson(json);
  } on FormatException {
    return fail();
  }
  final nonceBytes = fromB64url(dto.nonce);
  final sigBytes = fromB64url(dto.sig);
  // Always consume the nonce (single use, success or not).
  final nonceOk = nonceBytes != null && nonces.consume(peer, nonceBytes);
  if (!nonceOk || sigBytes == null) return fail();
  final serverFp = await serverFingerprint();
  final clientFp = verifyIdentityProof(
    certPem: dto.hello.clientCertPem,
    message: signedMessage(ProofLabels.pairKnown, [
      _utf8(serverFp),
      nonceBytes,
    ]),
    sig: sigBytes,
  );
  if (clientFp == null) return fail();
  final known = await lookup(clientFp);
  if (known == null) return fail();
  return await handOff(
    PairCandidate(
      hello: dto.hello,
      clientFingerprint: clientFp,
      remoteIp: peer,
      method: PairMethod.known,
      serverFingerprint: serverFp,
      autoAccept: known.autoAccept,
    ),
  );
});

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
          serverFingerprint: serverFp,
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
          serverFingerprint: serverFp,
        ),
      );
  }
}
