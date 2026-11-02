import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:kfm/core/utils/random_id.dart';
import 'package:kfm/features/connect/data/crypto/constant_time.dart';
import 'package:kfm/features/connect/data/crypto/identity_proof.dart';
import 'package:kfm/features/connect/data/crypto/spake2.dart';
import 'package:kfm/features/connect/data/pinned_client.dart';
import 'package:kfm/features/connect/data/remote_errors.dart';
import 'package:kfm/features/connect/domain/device_identity.dart';
import 'package:kfm/features/connect/domain/fingerprint_words.dart';
import 'package:kfm/features/connect/domain/pairing.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:meta/meta.dart';

/// Why pairing failed; each maps to one message on the Connect screen.
enum PairingFailure {
  /// No address answered (AP isolation, guest Wi-Fi, device gone).
  unreachable,

  /// The server's certificate isn't the one in the QR / the nearby hint.
  wrongDevice,

  /// SPAKE2 confirmation failed: wrong code, or not the device chosen.
  wrongCode,
  secretUsed,
  expired,
  tooManyAttempts,
  busy,
  declined,
  timedOut,
  cancelled,
  unsupportedVersion,
  pairingFailed,

  /// The connection broke mid-way.
  network,

  /// The other device didn't speak protocol v1.
  badResponse,

  /// N6: a remembered device presented another key (reinstall, reset or an
  /// impostor). The stored fingerprint is never updated: scan again.
  keyChanged,

  /// N6: the other device doesn't know us any more (removed, or our
  /// identity was reset): scan again.
  notAllowed,

  /// N6: no stored or nearby address of a remembered device answered (it
  /// isn't sharing).
  offline,
}

/// A typed pairing error the UI shows (rule 8).
class PairingException implements Exception {
  const new(this.failure, {this.cause});

  final PairingFailure failure;

  /// For logs only.
  final Object? cause;

  @override
  String toString() => 'PairingException(${failure.name})';
}

/// A finished pairing: the pinned client and N3's answer. Until N5 lands the
/// Connect screen keeps them and shows "Connected".
@immutable
class PairingSuccess {
  const new({
    required this.http,
    required this.accepted,
    required this.peerName,
    required this.peerFingerprint,
  });

  /// Pinned to [peerFingerprint]; the token is set as its bearer.
  final RemoteHttp http;
  final PairAcceptedDto accepted;
  final String peerName;
  final String peerFingerprint;
}

/// Cancels a running pairing: closes the current client (the in-flight
/// request fails), withdraws a request that waits for the accept prompt
/// (`POST /v1/pair/cancel`, N3) and makes the pairing throw `cancelled`.
class PairingCancel {
  bool _cancelled = false;
  RemoteHttp? _current;
  Future<void> Function()? _withdraw;

  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _current?.close();
    final w = _withdraw;
    _withdraw = null;
    // Best effort: a vanished client is covered by the 60 s timeout.
    if (w != null) unawaited(w().catchError((Object _) {}));
  }

  void _attach(RemoteHttp http) {
    _current = http;
    if (_cancelled) http.close();
  }

  void _check() {
    if (_cancelled) {
      throw const PairingException(PairingFailure.cancelled);
    }
  }
}

typedef PinnedFactory = RemoteHttp Function(Uri base, String fingerprint);
typedef FirstContactFactory = FirstContactHttp Function(Uri base);

/// Reports the waiting state: the peer's name and the 4-word phrase both
/// devices show (N3).
typedef PairingWaiting = void Function(String peerName, List<String> words);

/// Timeout of the best-effort `POST /v1/pair/cancel`.
const Duration kPairCancelTimeout = Duration(seconds: 3);

/// Per-address probe timeout on the QR path.
const Duration kPairProbeTimeout = Duration(seconds: 2);

/// Client timeout of `POST /v1/pair` (the server holds up to 60 s, N3).
const Duration kPairRequestTimeout = Duration(seconds: 75);

/// The connecting side of both pairing paths (TASK-N2).
class PairingClient {
  new({
    required this._identity,
    PinnedFactory? pinned,
    FirstContactFactory? firstContact,
    this.probeTimeout = kPairProbeTimeout,
  }) : _pinned = pinned ?? PinnedClient.pinned,
       _firstContact = firstContact ?? PinnedClient.firstContact;

  final DeviceIdentityRepository _identity;
  final PinnedFactory _pinned;
  final FirstContactFactory _firstContact;
  final Duration probeTimeout;

  /// QR path: pins the QR fingerprint, tries each address (2 s each), signs
  /// the server nonce and sends `POST /v1/pair`. [onWaiting] runs when the
  /// request reaches the other device's accept step.
  Future<PairingSuccess> pairWithQr(
    PairingOffer offer, {
    PairingWaiting? onWaiting,
    PairingCancel? cancel,
  }) async {
    final me = await _identity.loadOrCreate();
    RemoteHttp? http;
    Uint8List? nonce;
    var sawPinMismatch = false;
    RemoteApiException? lastApi;
    for (final a in offer.addresses) {
      cancel?._check();
      final c = _pinned(
        Uri(scheme: 'https', host: a.host, port: a.port),
        offer.serverFingerprint,
      );
      cancel?._attach(c);
      try {
        final n = await c.postJson(
          ApiRoutes.pairNonce,
          const <String, Object?>{},
          decode: PairNonceDto.fromJson,
          timeout: probeTimeout,
        );
        final bytes = fromB64url(n.nonce);
        if (bytes == null || bytes.length != 32) {
          c.close();
          continue;
        }
        nonce = bytes;
        http = c;
        break;
      } on RemoteUnavailableException catch (e) {
        c.close();
        if (e.reason == RemoteUnavailableReason.pinMismatch) {
          sawPinMismatch = true;
        }
      } on RemoteApiException catch (e) {
        c.close();
        lastApi = e;
      }
    }
    cancel?._check();
    if (http == null || nonce == null) {
      if (sawPinMismatch) {
        throw const PairingException(PairingFailure.wrongDevice);
      }
      if (lastApi != null) throw _fromApi(lastApi);
      throw const PairingException(PairingFailure.unreachable);
    }
    final peerName = offer.deviceName;
    try {
      final sig = await _identity.sign(
        signedMessage(ProofLabels.pairQr, [
          _utf8(offer.serverFingerprint),
          nonce,
          _sha256(offer.secret),
        ]),
      );
      cancel?._check();
      final hello = _hello(me);
      final base = http.base;
      cancel?._withdraw = () =>
          _sendCancel(base, offer.serverFingerprint, hello.pairAttemptId);
      onWaiting?.call(
        peerName,
        fingerprintWords(offer.serverFingerprint, me.fingerprint),
      );
      final accepted = await http.postJson(
        ApiRoutes.pair,
        PairRequestDto(
          hello: hello,
          credential: QrCredential(
            secret: b64url(offer.secret),
            nonce: b64url(nonce),
            sig: b64url(sig),
          ),
        ).toJson(),
        decode: PairAcceptedDto.fromJson,
        timeout: kPairRequestTimeout,
      );
      cancel?._withdraw = null;
      http.bearerToken = accepted.token;
      return PairingSuccess(
        http: http,
        accepted: accepted,
        peerName: peerName,
        peerFingerprint: offer.serverFingerprint,
      );
    } on Object catch (e) {
      cancel?._withdraw = null;
      http.close();
      throw _map(e, cancel);
    }
  }

  /// Short-code path (SPAKE2, RFC 9382). [expectedFingerprint] is the mDNS
  /// TXT hint (null for a typed address); a mismatch stops early. On a
  /// failed `confirmB` the client aborts and sends nothing more.
  Future<PairingSuccess> pairWithCode({
    required Uri base,
    required ShortCode code,
    String? expectedFingerprint,
    PairingWaiting? onWaiting,
    PairingCancel? cancel,
  }) async {
    final me = await _identity.loadOrCreate();
    cancel?._check();
    final first = _firstContact(base);
    cancel?._attach(first);
    RemoteHttp current = first;
    try {
      final info = await first.getJson(
        ApiRoutes.info,
        decode: ServerInfoDto.fromJson,
      );
      if (info.protocolVersion != kProtocolVersion) {
        throw const PairingException(PairingFailure.unsupportedVersion);
      }
      final seen = first.seenFingerprint;
      if (seen == null) {
        throw const PairingException(PairingFailure.badResponse);
      }
      if (expectedFingerprint != null &&
          expectedFingerprint.toLowerCase() != seen) {
        throw const PairingException(PairingFailure.wrongDevice);
      }
      final peerName = info.name;
      final hello = _hello(me);
      final spake = Spake2Client(
        w: spake2PasswordScalar(code.value),
        idA: _utf8(me.fingerprint),
        idB: _utf8(seen),
        aad: _utf8(kSpake2Aad),
      );
      cancel?._check();
      final start = await first.postJson(
        ApiRoutes.pairCodeStart,
        CodeStartRequestDto(hello: hello, pA: b64url(spake.pA)).toJson(),
        decode: CodeStartResponseDto.fromJson,
      );
      final pB = fromB64url(start.pB);
      final confirmB = fromB64url(start.confirmB);
      final keys = pB == null ? null : spake.finish(pB);
      if (keys == null ||
          confirmB == null ||
          !constantTimeEquals(keys.confirmB, confirmB)) {
        // Never reveal confirmA after a failed check (offline test).
        throw const PairingException(PairingFailure.wrongCode);
      }
      cancel?._check();
      final pinned = first.promote();
      current = pinned;
      cancel?._attach(pinned);
      final sig = await _identity.sign(
        signedMessage(ProofLabels.pairCode, [_utf8(seen), _sha256(keys.tt)]),
      );
      cancel?._check();
      cancel?._withdraw = () => _sendCancel(base, seen, hello.pairAttemptId);
      onWaiting?.call(peerName, fingerprintWords(seen, me.fingerprint));
      final accepted = await pinned.postJson(
        ApiRoutes.pair,
        PairRequestDto(
          hello: hello,
          credential: CodeCredential(
            attemptId: start.attemptId,
            confirmA: b64url(keys.confirmA),
            sig: b64url(sig),
          ),
        ).toJson(),
        decode: PairAcceptedDto.fromJson,
        timeout: kPairRequestTimeout,
      );
      cancel?._withdraw = null;
      pinned.bearerToken = accepted.token;
      return PairingSuccess(
        http: pinned,
        accepted: accepted,
        peerName: peerName,
        peerFingerprint: seen,
      );
    } on Object catch (e) {
      cancel?._withdraw = null;
      current.close();
      throw _map(e, cancel);
    }
  }

  /// N6 reconnect of a remembered device: pins [fingerprint], tries each of
  /// [candidates] (2 s each), then on the SAME client signs the nonce and
  /// sends `POST /v1/pair/known`. Every candidate failing the pin →
  /// [PairingFailure.keyChanged]; nothing answering → `offline`;
  /// `pairing_failed` → `notAllowed`. The other device still decides
  /// (accept prompt, unless it set "Always allow").
  Future<PairingSuccess> pairKnown({
    required String fingerprint,
    required String name,
    required List<ShareAddress> candidates,
    PairingWaiting? onWaiting,
    PairingCancel? cancel,
  }) async {
    final me = await _identity.loadOrCreate();
    RemoteHttp? http;
    Uint8List? nonce;
    var sawPinMismatch = false;
    RemoteApiException? lastApi;
    for (final a in candidates) {
      cancel?._check();
      final c = _pinned(
        Uri(scheme: 'https', host: a.host, port: a.port),
        fingerprint,
      );
      cancel?._attach(c);
      try {
        final n = await c.postJson(
          ApiRoutes.pairNonce,
          const <String, Object?>{},
          decode: PairNonceDto.fromJson,
          timeout: probeTimeout,
        );
        final bytes = fromB64url(n.nonce);
        if (bytes == null || bytes.length != 32) {
          c.close();
          continue;
        }
        nonce = bytes;
        http = c;
        break;
      } on RemoteUnavailableException catch (e) {
        c.close();
        if (e.reason == RemoteUnavailableReason.pinMismatch) {
          sawPinMismatch = true;
        }
      } on RemoteApiException catch (e) {
        c.close();
        lastApi = e;
      }
    }
    cancel?._check();
    if (http == null || nonce == null) {
      if (sawPinMismatch) {
        throw const PairingException(PairingFailure.keyChanged);
      }
      if (lastApi != null) throw _fromKnownApi(lastApi);
      throw const PairingException(PairingFailure.offline);
    }
    try {
      final sig = await _identity.sign(
        signedMessage(ProofLabels.pairKnown, [_utf8(fingerprint), nonce]),
      );
      cancel?._check();
      final hello = _hello(me);
      final base = http.base;
      cancel?._withdraw = () =>
          _sendCancel(base, fingerprint, hello.pairAttemptId);
      onWaiting?.call(name, fingerprintWords(fingerprint, me.fingerprint));
      final accepted = await http.postJson(
        ApiRoutes.pairKnown,
        KnownPairRequestDto(
          hello: hello,
          nonce: b64url(nonce),
          sig: b64url(sig),
        ).toJson(),
        decode: PairAcceptedDto.fromJson,
        timeout: kPairRequestTimeout,
      );
      cancel?._withdraw = null;
      http.bearerToken = accepted.token;
      return PairingSuccess(
        http: http,
        accepted: accepted,
        peerName: name,
        peerFingerprint: fingerprint,
      );
    } on Object catch (e) {
      cancel?._withdraw = null;
      http.close();
      if (cancel != null && cancel.isCancelled) {
        throw PairingException(PairingFailure.cancelled, cause: e);
      }
      throw switch (e) {
        RemoteApiException() => _fromKnownApi(e),
        RemoteUnavailableException(
          reason: RemoteUnavailableReason.pinMismatch,
        ) =>
          PairingException(PairingFailure.keyChanged, cause: e),
        _ => _map(e, cancel),
      };
    }
  }

  /// `/v1/pair/known` answers: `pairing_failed` means "not a known device".
  static PairingException _fromKnownApi(RemoteApiException e) =>
      e.code == ApiErrorCode.pairingFailed
      ? PairingException(PairingFailure.notAllowed, cause: e)
      : _fromApi(e);

  /// `POST /v1/pair/cancel` on a fresh pinned client (the waiting one is
  /// already closed).
  Future<void> _sendCancel(
    Uri base,
    String fingerprint,
    String attemptId,
  ) async {
    final c = _pinned(base, fingerprint);
    try {
      await c.postJson(
        ApiRoutes.pairCancel,
        {'pairAttemptId': attemptId},
        decode: (_) => null,
        timeout: kPairCancelTimeout,
      );
    } finally {
      c.close();
    }
  }

  ClientHelloDto _hello(DeviceIdentity me) => ClientHelloDto(
    pairAttemptId: randomHexId(),
    clientDeviceId: me.deviceId,
    clientName: me.displayName,
    clientPlatform: me.platform,
    clientCertPem: me.certPem,
  );

  static PairingException _map(Object e, PairingCancel? cancel) {
    if (cancel != null && cancel.isCancelled) {
      return PairingException(PairingFailure.cancelled, cause: e);
    }
    return switch (e) {
      PairingException() => e,
      RemoteApiException() => _fromApi(e),
      RemoteUnavailableException(reason: RemoteUnavailableReason.pinMismatch) =>
        PairingException(PairingFailure.wrongDevice, cause: e),
      RemoteUnavailableException(reason: RemoteUnavailableReason.badResponse) =>
        PairingException(PairingFailure.badResponse, cause: e),
      RemoteUnavailableException() => PairingException(
        PairingFailure.network,
        cause: e,
      ),
      _ => PairingException(PairingFailure.pairingFailed, cause: e),
    };
  }

  static PairingException _fromApi(RemoteApiException e) =>
      PairingException(switch (e.code) {
        ApiErrorCode.secretUsed => PairingFailure.secretUsed,
        ApiErrorCode.expired => PairingFailure.expired,
        ApiErrorCode.tooManyAttempts => PairingFailure.tooManyAttempts,
        ApiErrorCode.busy => PairingFailure.busy,
        ApiErrorCode.declined => PairingFailure.declined,
        ApiErrorCode.timedOut => PairingFailure.timedOut,
        ApiErrorCode.cancelled => PairingFailure.cancelled,
        ApiErrorCode.unsupportedVersion => PairingFailure.unsupportedVersion,
        ApiErrorCode.forbidden => PairingFailure.unreachable,
        _ => PairingFailure.pairingFailed,
      }, cause: e);
}

Uint8List _utf8(String s) => Uint8List.fromList(utf8.encode(s));

Uint8List _sha256(List<int> b) =>
    Uint8List.fromList(crypto.sha256.convert(b).bytes);
