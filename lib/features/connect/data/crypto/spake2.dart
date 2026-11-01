import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:kfm/features/connect/data/crypto/identity_proof.dart';
import 'package:meta/meta.dart';
import 'package:pointycastle/export.dart';

// SPAKE2-P256-SHA256-HKDF-HMAC exactly as RFC 9382 (TASK-N2). A (the
// connecting client) uses M, B (the sharing server) uses N; cofactor h = 1.
// The core takes w, x, y, A, B and AAD as parameters so the RFC Appendix B
// vectors can be fed in directly. pointycastle's EC arithmetic isn't
// constant-time; accepted (single-use 5-minute code, one guess per run,
// LAN only).

final ECDomainParameters _p256 = ECCurve_secp256r1();

/// The group order n.
BigInt get spake2Order => _p256.n;

/// RFC 9382 §6 P-256 point M (compressed SEC1).
final ECPoint _m = _p256.curve.decodePoint(
  _hex('02886e2f97ace46e55ba9dd7242579f2993b64e16ef3dcab95afd497333d8fa12f'),
)!;

/// RFC 9382 §6 P-256 point N (compressed SEC1).
final ECPoint _n = _p256.curve.decodePoint(
  _hex('03d8bbd6c639c62937b04d997f38c3770719c629d7014d49a24b4f98baa1292b49'),
)!;

/// Domain-separation prefix of the password scalar.
const String kSpake2WLabel = 'kfm-v1/spake2-w';

/// AAD of the confirmation-key KDF.
const String kSpake2Aad = 'kfm-v1/pair-code';

/// `w = OS2IP(SHA-256("kfm-v1/spake2-w" ‖ code)) mod n`. The code is
/// ephemeral and never stored, so a plain hash is enough (no MHF).
BigInt spake2PasswordScalar(String code) =>
    _os2ip(crypto.sha256.convert(utf8.encode('$kSpake2WLabel$code')).bytes) %
    _p256.n;

/// A uniform scalar in [1, n) from [random] (rejection sampling).
BigInt spake2RandomScalar([Random? random]) {
  final r = random ?? Random.secure();
  while (true) {
    final bytes = List<int>.generate(32, (_) => r.nextInt(256));
    final k = _os2ip(bytes);
    if (k > BigInt.zero && k < _p256.n) return k;
  }
}

/// Keys and confirmations of one finished SPAKE2 run.
@immutable
class Spake2Keys {
  const new({
    required this.tt,
    required this.ke,
    required this.ka,
    required this.kcA,
    required this.kcB,
    required this.confirmA,
    required this.confirmB,
  });

  /// The transcript (RFC 9382 §3.3).
  final Uint8List tt;

  /// Shared secret; unused by KFM (TLS already encrypts), discarded.
  final Uint8List ke;
  final Uint8List ka;
  final Uint8List kcA;
  final Uint8List kcB;

  /// `MAC(KcA, TT)`: sent by A (client) only after it verified [confirmB].
  final Uint8List confirmA;

  /// `MAC(KcB, TT)`: sent by B (server) with `pB`.
  final Uint8List confirmB;
}

/// The client (A) side: holds the secret scalar `x` for one run.
class Spake2Client {
  /// [x] only for test vectors; otherwise random.
  new({
    required this._w,
    required this._idA,
    required this._idB,
    Uint8List? aad,
    BigInt? x,
    Random? random,
  }) : _aad = aad ?? Uint8List(0),
       _x = x ?? spake2RandomScalar(random) {
    pA = _encode((_p256.G * _x)! + (_m * _w))!;
  }

  final BigInt _w;
  final Uint8List _idA;
  final Uint8List _idB;
  final Uint8List _aad;
  final BigInt _x;

  /// `x·G + w·M`, uncompressed SEC1 (65 bytes).
  late final Uint8List pA;

  /// Null when [pB] isn't a valid point (or K is the identity).
  Spake2Keys? finish(Uint8List pB) {
    final kBytes = spake2ClientSecret(x: _x, w: _w, pB: pB);
    if (kBytes == null) return null;
    return spake2DeriveKeys(
      idA: _idA,
      idB: _idB,
      pA: pA,
      pB: pB,
      k: kBytes,
      w: _w,
      aad: _aad,
    );
  }
}

/// `K = x·(pB − w·N)` (uncompressed); null for an invalid [pB] or an
/// identity K. Visible so the offline-guessing test can run exactly the
/// attacker's computation.
@visibleForTesting
Uint8List? spake2ClientSecret({
  required BigInt x,
  required BigInt w,
  required Uint8List pB,
}) {
  final b = spake2DecodePoint(pB);
  if (b == null) return null;
  return _encode((b - (_n * w)!)! * x);
}

/// The server (B) answer to one `pA`.
typedef Spake2ServerResult = ({Uint8List pB, Spake2Keys keys});

/// The server (B) side: answers [pA] with `pB = y·G + w·N` and the keys.
/// Null when [pA] isn't a valid point (off curve, wrong encoding, or K is the
/// identity). [y] only for test vectors.
Spake2ServerResult? spake2Respond({
  required BigInt w,
  required Uint8List idA,
  required Uint8List idB,
  required Uint8List pA,
  Uint8List? aad,
  BigInt? y,
  Random? random,
}) {
  final a = spake2DecodePoint(pA);
  if (a == null) return null;
  final ys = y ?? spake2RandomScalar(random);
  final pB = _encode((_p256.G * ys)! + (_n * w))!;
  final k = (a - (_m * w)!)! * ys;
  final kBytes = _encode(k);
  if (kBytes == null) return null;
  return (
    pB: pB,
    keys: spake2DeriveKeys(
      idA: idA,
      idB: idB,
      pA: pA,
      pB: pB,
      k: kBytes,
      w: w,
      aad: aad ?? Uint8List(0),
    ),
  );
}

/// Uncompressed SEC1 point on P-256; null for anything else (compressed,
/// off curve, wrong length). The identity has no 65-byte encoding.
ECPoint? spake2DecodePoint(Uint8List bytes) => p256PublicKeyFromPoint(bytes)?.Q;

/// RFC 9382 §3.3 transcript and §4 key schedule.
@visibleForTesting
Spake2Keys spake2DeriveKeys({
  required Uint8List idA,
  required Uint8List idB,
  required Uint8List pA,
  required Uint8List pB,
  required Uint8List k,
  required BigInt w,
  required Uint8List aad,
}) {
  final tt = BytesBuilder(copy: false);
  for (final part in [idA, idB, pA, pB, k, _i2osp(w, 32)]) {
    final len = ByteData(8)..setUint64(0, part.length, Endian.little);
    tt
      ..add(len.buffer.asUint8List())
      ..add(part);
  }
  final transcript = tt.toBytes();
  final hash = Uint8List.fromList(crypto.sha256.convert(transcript).bytes);
  final ke = hash.sublist(0, 16);
  final ka = hash.sublist(16);
  final kc = _hkdf(
    ka,
    Uint8List.fromList([...utf8.encode('ConfirmationKeys'), ...aad]),
    32,
  );
  final kcA = kc.sublist(0, 16);
  final kcB = kc.sublist(16);
  return Spake2Keys(
    tt: transcript,
    ke: ke,
    ka: ka,
    kcA: kcA,
    kcB: kcB,
    confirmA: _hmac(kcA, transcript),
    confirmB: _hmac(kcB, transcript),
  );
}

/// HKDF-SHA256 (RFC 5869) with no salt (= 32 zero bytes).
Uint8List _hkdf(Uint8List ikm, Uint8List info, int length) {
  final prk = _hmac(Uint8List(32), ikm);
  final out = BytesBuilder(copy: false);
  var t = Uint8List(0);
  for (var i = 1; out.length < length; i++) {
    t = _hmac(prk, Uint8List.fromList([...t, ...info, i]));
    out.add(t);
  }
  return out.toBytes().sublist(0, length);
}

Uint8List _hmac(Uint8List key, Uint8List message) =>
    Uint8List.fromList(crypto.Hmac(crypto.sha256, key).convert(message).bytes);

Uint8List? _encode(ECPoint? p) {
  if (p == null || p.isInfinity) return null;
  return p.getEncoded(false);
}

BigInt _os2ip(List<int> bytes) {
  var r = BigInt.zero;
  for (final b in bytes) {
    r = (r << 8) | BigInt.from(b);
  }
  return r;
}

Uint8List _i2osp(BigInt v, int length) {
  final out = Uint8List(length);
  var x = v;
  for (var i = length - 1; i >= 0; i--) {
    out[i] = (x & BigInt.from(0xff)).toInt();
    x >>= 8;
  }
  return out;
}

Uint8List _hex(String s) => Uint8List.fromList([
  for (var i = 0; i < s.length; i += 2)
    int.parse(s.substring(i, i + 2), radix: 16),
]);
