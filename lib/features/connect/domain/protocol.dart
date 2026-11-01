import 'package:meta/meta.dart';

/// Protocol v1 code mirror (TASK-N1 → "Protocol v1" is the source of truth).
/// Any new route or error code goes into the N1 plan first, then here.
const int kProtocolVersion = 1;

/// Route path prefix of protocol v1.
const String kProtocolPrefix = '/v1';

/// One route as "METHOD /path" (exact match, no trailing slash).
typedef RouteKey = String;

/// Builds a [RouteKey].
RouteKey routeKey(String method, String path) =>
    '${method.toUpperCase()} $path';

/// Routes and their keys.
abstract final class ApiRoutes {
  static const info = '/v1/info';
  static const pairNonce = '/v1/pair/nonce';
  static const pairCodeStart = '/v1/pair/code/start';
  static const pair = '/v1/pair';
  static const pairKnown = '/v1/pair/known';
  static const pairCancel = '/v1/pair/cancel';
  static const session = '/v1/session';
  static const sessionClose = '/v1/session/close';
  static const roots = '/v1/roots';
  static const files = '/v1/files';
  static const uploads = '/v1/uploads';
}

/// Routes that skip `authenticate` (exact method + path).
const Set<RouteKey> kUnauthenticatedRoutes = {
  'GET /v1/info',
  'POST /v1/pair/nonce',
  'POST /v1/pair/code/start',
  'POST /v1/pair',
  'POST /v1/pair/known',
  'POST /v1/pair/cancel',
};

/// Max JSON request body (`requestSizeLimit`); N10's chunk route has its own.
const int kMaxJsonBodyBytes = 64 * 1024;

/// Max certificate PEM accepted from a peer.
const int kMaxCertPemBytes = 4 * 1024;

/// Pair nonce lifetime and caps (N1).
const Duration kPairNonceLifetime = Duration(seconds: 60);
const int kPairNoncesPerIp = 8;
const int kPairNoncesTotal = 64;

/// Labels of signed identity proofs (domain separation).
abstract final class ProofLabels {
  static const pairQr = 'kfm-v1/pair-qr';
  static const pairCode = 'kfm-v1/pair-code';
  static const pairKnown = 'kfm-v1/pair-known';
}

/// Discovery identifiers (can't change after release).
abstract final class DiscoveryIds {
  static const qrScheme = 'kfm1';
  static const mdnsType = '_kfmshare._tcp';
}

/// `ApiErrorDto.code` values (complete list) with their HTTP status.
enum ApiErrorCode {
  unauthorized(401),
  forbidden(403),
  forbiddenPath(403, 'forbidden_path'),
  notFound(404, 'not_found'),
  conflict(409),
  busy(409),
  pairingFailed(401, 'pairing_failed'),
  secretUsed(401, 'secret_used'),
  expired(401),
  tooManyAttempts(429, 'too_many_attempts'),
  declined(403),
  timedOut(403, 'timed_out'),
  cancelled(410),
  unsupportedVersion(400, 'unsupported_version'),
  insufficientStorage(507, 'insufficient_storage'),
  tooLarge(413, 'too_large'),
  pendingFolderUnavailable(409, 'pending_folder_unavailable'),
  invalidName(400, 'invalid_name'),
  verificationFailed(409, 'verification_failed'),
  internal(500)
  ;

  new(this.status, [this._wire]);

  final int status;
  final String? _wire;

  /// The code on the wire (snake_case).
  String get wire => _wire ?? name;

  /// Null for an unknown code (a newer peer).
  static ApiErrorCode? fromWire(String code) {
    for (final c in values) {
      if (c.wire == code) return c;
    }
    return null;
  }
}

String _str(Map<String, Object?> json, String key) {
  final v = json[key];
  if (v is String) return v;
  throw FormatException('missing or non-string "$key"');
}

int _int(Map<String, Object?> json, String key) {
  final v = json[key];
  if (v is int) return v;
  throw FormatException('missing or non-int "$key"');
}

bool _bool(Map<String, Object?> json, String key) {
  final v = json[key];
  if (v is bool) return v;
  throw FormatException('missing or non-bool "$key"');
}

Map<String, Object?> _map(Map<String, Object?> json, String key) {
  final v = json[key];
  if (v is Map<String, Object?>) return v;
  throw FormatException('missing or non-object "$key"');
}

/// `GET /v1/info`: exactly these fields (no file data).
@immutable
class ServerInfoDto {
  const new({
    required this.deviceId,
    required this.name,
    required this.platform,
    required this.fingerprint,
    required this.protocolVersion,
  });

  /// Unknown fields are ignored; throws [FormatException] on a missing one.
  factory fromJson(Map<String, Object?> json) => ServerInfoDto(
    deviceId: _str(json, 'deviceId'),
    name: _str(json, 'name'),
    platform: _str(json, 'platform'),
    fingerprint: _str(json, 'fingerprint'),
    protocolVersion: _int(json, 'protocolVersion'),
  );

  final String deviceId;
  final String name;
  final String platform;
  final String fingerprint;
  final int protocolVersion;

  Map<String, Object?> toJson() => {
    'deviceId': deviceId,
    'name': name,
    'platform': platform,
    'fingerprint': fingerprint,
    'protocolVersion': protocolVersion,
  };
}

/// `POST /v1/pair/nonce` response.
@immutable
class PairNonceDto {
  const new({required this.nonce, required this.expiresInSeconds});

  factory fromJson(Map<String, Object?> json) => PairNonceDto(
    nonce: _str(json, 'nonce'),
    expiresInSeconds: _int(json, 'expiresInSeconds'),
  );

  /// 32 bytes, base64url without padding.
  final String nonce;
  final int expiresInSeconds;

  Map<String, Object?> toJson() => {
    'nonce': nonce,
    'expiresInSeconds': expiresInSeconds,
  };
}

/// Common part of every pairing request.
@immutable
class ClientHelloDto {
  const new({
    required this.pairAttemptId,
    required this.clientDeviceId,
    required this.clientName,
    required this.clientPlatform,
    required this.clientCertPem,
  });

  factory fromJson(Map<String, Object?> json) => ClientHelloDto(
    pairAttemptId: _str(json, 'pairAttemptId'),
    clientDeviceId: _str(json, 'clientDeviceId'),
    clientName: _str(json, 'clientName'),
    clientPlatform: _str(json, 'clientPlatform'),
    clientCertPem: _str(json, 'clientCertPem'),
  );

  /// Client-generated 128-bit random hex; used by `/pair/cancel`.
  final String pairAttemptId;

  /// Informational only.
  final String clientDeviceId;
  final String clientName;
  final String clientPlatform;

  /// The server derives the client fingerprint (sha256 of the DER) itself.
  final String clientCertPem;

  Map<String, Object?> toJson() => {
    'pairAttemptId': pairAttemptId,
    'clientDeviceId': clientDeviceId,
    'clientName': clientName,
    'clientPlatform': clientPlatform,
    'clientCertPem': clientCertPem,
  };
}

/// The credential of a `POST /v1/pair` request.
sealed class PairCredential {
  const new();

  /// `{type: 'qr'|'code', ...}`.
  factory fromJson(Map<String, Object?> json) =>
      switch (json['type']) {
        'qr' => QrCredential(
          secret: _str(json, 'secret'),
          nonce: _str(json, 'nonce'),
          sig: _str(json, 'sig'),
        ),
        'code' => CodeCredential(
          attemptId: _str(json, 'attemptId'),
          confirmA: _str(json, 'confirmA'),
          sig: _str(json, 'sig'),
        ),
        _ => throw const FormatException('unknown credential type'),
      };

  Map<String, Object?> toJson();
}

/// QR path: sig over [ProofLabels.pairQr].
final class QrCredential extends PairCredential {
  const new({required this.secret, required this.nonce, required this.sig});

  final String secret;
  final String nonce;
  final String sig;

  @override
  Map<String, Object?> toJson() => {
    'type': 'qr',
    'secret': secret,
    'nonce': nonce,
    'sig': sig,
  };
}

/// Short-code path: sig over [ProofLabels.pairCode].
final class CodeCredential extends PairCredential {
  const new({required this.attemptId, required this.confirmA, required this.sig});

  final String attemptId;
  final String confirmA;
  final String sig;

  @override
  Map<String, Object?> toJson() => {
    'type': 'code',
    'attemptId': attemptId,
    'confirmA': confirmA,
    'sig': sig,
  };
}

/// `POST /v1/pair`.
@immutable
class PairRequestDto {
  const new({required this.hello, required this.credential});

  factory fromJson(Map<String, Object?> json) => PairRequestDto(
    hello: ClientHelloDto.fromJson(_map(json, 'hello')),
    credential: PairCredential.fromJson(_map(json, 'credential')),
  );

  final ClientHelloDto hello;
  final PairCredential credential;

  Map<String, Object?> toJson() => {
    'hello': hello.toJson(),
    'credential': credential.toJson(),
  };
}

/// `POST /v1/pair/known`: sig over [ProofLabels.pairKnown].
@immutable
class KnownPairRequestDto {
  const new({required this.hello, required this.nonce, required this.sig});

  factory fromJson(Map<String, Object?> json) =>
      KnownPairRequestDto(
        hello: ClientHelloDto.fromJson(_map(json, 'hello')),
        nonce: _str(json, 'nonce'),
        sig: _str(json, 'sig'),
      );

  final ClientHelloDto hello;
  final String nonce;
  final String sig;

  Map<String, Object?> toJson() => {
    'hello': hello.toJson(),
    'nonce': nonce,
    'sig': sig,
  };
}

/// 200 from `/v1/pair` and `/v1/pair/known`.
@immutable
class PairAcceptedDto {
  const new({
    required this.token,
    required this.serverDeviceId,
    required this.roots,
  });

  factory fromJson(Map<String, Object?> json) {
    final roots = json['roots'];
    if (roots is! List<Object?>) {
      throw const FormatException('missing or non-list "roots"');
    }
    return PairAcceptedDto(
      token: _str(json, 'token'),
      serverDeviceId: _str(json, 'serverDeviceId'),
      roots: [
        for (final r in roots)
          if (r is Map<String, Object?>)
            RootDto.fromJson(r)
          else
            throw const FormatException('non-object root'),
      ],
    );
  }

  /// 32 bytes base64url; memory only on the client (N3).
  final String token;
  final String serverDeviceId;

  /// May be empty (N4).
  final List<RootDto> roots;

  Map<String, Object?> toJson() => {
    'token': token,
    'serverDeviceId': serverDeviceId,
    'roots': [for (final r in roots) r.toJson()],
  };
}

/// `GET /v1/roots` item (N4).
@immutable
class RootDto {
  const new({required this.id, required this.label, required this.readOnly});

  factory fromJson(Map<String, Object?> json) => RootDto(
    id: _str(json, 'id'),
    label: _str(json, 'label'),
    readOnly: _bool(json, 'readOnly'),
  );

  /// Stable opaque root id (N4).
  final String id;
  final String label;
  final bool readOnly;

  Map<String, Object?> toJson() => {
    'id': id,
    'label': label,
    'readOnly': readOnly,
  };
}

/// Error body of every non-2xx response: `{code, message}`.
@immutable
class ApiErrorDto {
  const new(this.code, this.message);

  /// Never throws: a malformed body becomes `internal`.
  factory fromJson(Map<String, Object?> json) {
    final code = json['code'];
    final message = json['message'];
    return ApiErrorDto(
      code is String ? code : ApiErrorCode.internal.wire,
      message is String ? message : '',
    );
  }

  /// One of [ApiErrorCode.wire].
  final String code;

  /// Short English text for logs; never shown to the user as is.
  final String message;

  Map<String, Object?> toJson() => {'code': code, 'message': message};
}

/// `POST /v1/pair/code/start` request (N2, SPAKE2 message 1).
@immutable
class CodeStartRequestDto {
  const new({required this.hello, required this.pA});

  factory fromJson(Map<String, Object?> json) => CodeStartRequestDto(
    hello: ClientHelloDto.fromJson(_map(json, 'hello')),
    pA: _str(json, 'pA'),
  );

  final ClientHelloDto hello;

  /// Uncompressed SEC1 point (65 bytes), base64url.
  final String pA;

  Map<String, Object?> toJson() => {'hello': hello.toJson(), 'pA': pA};
}

/// `POST /v1/pair/code/start` response (N2, SPAKE2 message 2).
@immutable
class CodeStartResponseDto {
  const new({
    required this.attemptId,
    required this.pB,
    required this.confirmB,
  });

  factory fromJson(Map<String, Object?> json) => CodeStartResponseDto(
    attemptId: _str(json, 'attemptId'),
    pB: _str(json, 'pB'),
    confirmB: _str(json, 'confirmB'),
  );

  /// 128-bit hex, valid 30 s, same remote IP only.
  final String attemptId;

  /// base64url.
  final String pB;
  final String confirmB;

  Map<String, Object?> toJson() => {
    'attemptId': attemptId,
    'pB': pB,
    'confirmB': confirmB,
  };
}
