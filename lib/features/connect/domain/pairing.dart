import 'dart:convert';
import 'dart:typed_data';

import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:meta/meta.dart';

/// One `host:port` the sharing device listens on.
typedef ShareAddress = ({String host, int port});

/// A `kfm1://` QR code from a newer KFM (`v` != 1).
class UnsupportedVersionException implements Exception {
  const new(this.version);

  final String version;

  @override
  String toString() => 'UnsupportedVersionException($version)';
}

/// Max addresses kept from a QR payload.
const int kMaxOfferAddresses = 3;

/// Max display name kept from a QR payload (UI only, never trusted).
const int kMaxOfferNameLength = 64;

/// The QR payload of "Share this device" (TASK-N2):
/// `kfm1://pair?v=1&a=<host:port,...>&f=<64 hex>&k=<b64url 32 B>&n=<name>`.
@immutable
class PairingOffer {
  const new({
    required this.addresses,
    required this.serverFingerprint,
    required this.secret,
    required this.deviceName,
  });

  /// Throws [FormatException] on a foreign scheme, a missing/oversized
  /// field, bad hex, a secret that isn't exactly 32 bytes or no address;
  /// [UnsupportedVersionException] when `v` != 1. Keeps only the first 3
  /// addresses.
  factory parse(String uri) {
    if (uri.length > 1024) throw const FormatException('too long');
    final Uri u;
    try {
      u = Uri.parse(uri.trim());
    } on FormatException {
      throw const FormatException('not a URI');
    }
    if (u.scheme != DiscoveryIds.qrScheme || u.host != 'pair') {
      throw const FormatException('not a KFM pairing code');
    }
    final Map<String, String> q;
    try {
      q = u.queryParameters;
    } on FormatException {
      throw const FormatException('bad query');
    }
    final v = q['v'];
    if (v == null) throw const FormatException('missing v');
    if (v != '$kProtocolVersion') throw UnsupportedVersionException(v);

    final f = q['f'];
    if (f == null || !_fp.hasMatch(f)) {
      throw const FormatException('bad f');
    }
    final k = q['k'];
    if (k == null || k.length > 64 || k.contains('=')) {
      throw const FormatException('bad k');
    }
    final Uint8List secret;
    try {
      secret = base64Url.decode(base64Url.normalize(k));
    } on FormatException {
      throw const FormatException('bad k');
    }
    if (secret.length != 32) throw const FormatException('bad k length');

    final a = q['a'];
    if (a == null || a.isEmpty) throw const FormatException('missing a');
    final addresses = <ShareAddress>[];
    for (final part in a.split(',').take(kMaxOfferAddresses)) {
      final i = part.lastIndexOf(':');
      if (i <= 0) throw const FormatException('bad address');
      final host = part.substring(0, i);
      final port = int.tryParse(part.substring(i + 1));
      if (!_host.hasMatch(host) || port == null || port < 1 || port > 65535) {
        throw const FormatException('bad address');
      }
      addresses.add((host: host, port: port));
    }
    if (addresses.isEmpty) throw const FormatException('no address');

    var name = q['n'] ?? '';
    if (name.length > kMaxOfferNameLength) {
      name = name.substring(0, kMaxOfferNameLength);
    }
    return PairingOffer(
      addresses: List.unmodifiable(addresses),
      serverFingerprint: f,
      secret: secret,
      deviceName: name,
    );
  }

  /// 1..3 candidates, tried in order.
  final List<ShareAddress> addresses;

  /// 64 lowercase hex; the client pins it.
  final String serverFingerprint;

  /// One-time secret, 32 bytes.
  final Uint8List secret;

  /// Display only.
  final String deviceName;

  static final RegExp _fp = RegExp(r'^[0-9a-f]{64}$');
  static final RegExp _host = RegExp(r'^[0-9A-Za-z.\-]{1,253}$');

  String toUri() {
    final a = addresses
        .take(kMaxOfferAddresses)
        .map((e) => '${e.host}:${e.port}')
        .join(',');
    final k = base64Url.encode(secret).replaceAll('=', '');
    // Hand-built: `a` keeps its literal ':' and ',' so the QR stays short.
    return '${DiscoveryIds.qrScheme}://pair?v=$kProtocolVersion'
        '&a=$a&f=$serverFingerprint&k=$k'
        '&n=${Uri.encodeQueryComponent(deviceName)}';
  }
}

/// Crockford base32 alphabet (no I, L, O, U).
const String kCrockfordAlphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

/// Length of a typed short code (8 chars = 40 bits).
const int kShortCodeLength = 8;

/// The typed short code (SPAKE2 password), canonical without the dash.
@immutable
class ShortCode {
  const new(this.value);

  final String value;

  /// `XXXX-XXXX`.
  String get display => value.length <= 4
      ? value
      : '${value.substring(0, 4)}-${value.substring(4)}';

  /// Uppercase, strips spaces and '-', maps O→0, I/L→1; null if not
  /// [length] valid characters.
  static ShortCode? normalize(String input, {int length = kShortCodeLength}) {
    final v = canonicalChars(input);
    if (v == null || v.length != length) return null;
    return ShortCode(v);
  }

  /// The canonical characters typed so far (any length); null when one of
  /// them isn't valid. Used for live normalisation in the text field.
  static String? canonicalChars(String input) {
    final out = StringBuffer();
    for (final ch in input.toUpperCase().split('')) {
      if (ch == ' ' || ch == '-') continue;
      final c = switch (ch) {
        'O' => '0',
        'I' || 'L' => '1',
        _ => ch,
      };
      if (!kCrockfordAlphabet.contains(c)) return null;
      out.write(c);
    }
    return out.toString();
  }

  @override
  bool operator ==(Object other) => other is ShortCode && other.value == value;

  @override
  int get hashCode => value.hashCode;

  /// Never prints the code (logs).
  @override
  String toString() => 'ShortCode(…)';
}

/// Why the share screen's QR/code changed.
enum RotationReason { consumed, expired, qrLocked, codeLocked }

/// What the share screen shows about pairing (TASK-N2).
sealed class PairingSecretState {
  const new();
}

/// Not sharing: nothing to show.
final class SecretIdle extends PairingSecretState {
  const new();
}

/// The current QR offer and short code.
final class SecretActive extends PairingSecretState {
  const new({
    required this.offer,
    required this.code,
    required this.expiresAt,
    required this.codeExpiresAt,
    required this.typedCodesEnabled,
    this.codeCooldownUntil,
  });

  final PairingOffer offer;
  final ShortCode code;

  /// When the QR secret rotates (server clock).
  final DateTime expiresAt;

  /// When the code rotates; differs from [expiresAt] after a code lock.
  final DateTime codeExpiresAt;

  /// False after 3 code locks in this sharing run.
  final bool typedCodesEnabled;

  /// Set during the 30 s cooldown after a code lock.
  final DateTime? codeCooldownUntil;
}

/// UI hint, followed by [SecretActive] again.
final class SecretRotated extends PairingSecretState {
  const new(this.reason);

  final RotationReason reason;
}
