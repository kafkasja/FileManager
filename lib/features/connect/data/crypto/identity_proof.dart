import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:pointycastle/asn1.dart';
import 'package:pointycastle/export.dart';

// Identity-proof helpers (TASK-N1 → Protocol v1 → Signed messages). Pure
// functions, no I/O. Every parser here returns null on malformed input and
// never throws: peers control these bytes.

/// Canonical signed message: `utf8(label)` followed by, for each field, a
/// 4-byte big-endian length and the raw bytes.
Uint8List signedMessage(String label, List<Uint8List> fields) {
  final out = BytesBuilder(copy: false)..add(utf8.encode(label));
  for (final f in fields) {
    final len = ByteData(4)..setUint32(0, f.length);
    out
      ..add(len.buffer.asUint8List())
      ..add(f);
  }
  return out.toBytes();
}

/// Parses [certPem] (max 4 KiB), requires an EC P-256 public key, verifies
/// [sig] (DER ECDSA/SHA-256) over [message]. Returns the cert fingerprint on
/// success, null otherwise. Never throws on malformed input.
String? verifyIdentityProof({
  required String certPem,
  required Uint8List message,
  required Uint8List sig,
}) {
  try {
    final der = certDerFromPem(certPem);
    if (der == null) return null;
    final key = p256PublicKeyFromCertDer(der);
    if (key == null) return null;
    final signature = ecdsaSignatureFromDer(sig);
    if (signature == null) return null;
    final verifier = ECDSASigner(SHA256Digest())
      ..init(false, PublicKeyParameter<ECPublicKey>(key));
    if (!verifier.verifySignature(message, signature)) return null;
    return fingerprintOfDer(der);
    // A peer-controlled parse can fail in any way; all of them mean "invalid".
    // ignore: avoid_catches_without_on_clauses
  } catch (_) {
    return null;
  }
}

/// `sha256(cert DER)`, lowercase hex (64 chars).
String fingerprintOfDer(List<int> der) => crypto.sha256.convert(der).toString();

/// [fingerprintOfDer] of a PEM cert; null when it isn't one.
String? certFingerprint(String certPem) {
  final der = certDerFromPem(certPem);
  return der == null ? null : fingerprintOfDer(der);
}

/// The DER bytes of a single `CERTIFICATE` PEM block; null for anything else
/// (oversized, several blocks, bad base64).
Uint8List? certDerFromPem(String pem) {
  if (pem.length > kMaxCertPemBytes) return null;
  const begin = '-----BEGIN CERTIFICATE-----';
  const end = '-----END CERTIFICATE-----';
  final text = pem.trim();
  if (!text.startsWith(begin) || !text.endsWith(end)) return null;
  final body = text.substring(begin.length, text.length - end.length);
  if (body.contains('-----')) return null;
  try {
    final der = base64.decode(body.replaceAll(RegExp(r'\s'), ''));
    return der.isEmpty ? null : der;
  } on FormatException {
    return null;
  }
}

final ECDomainParameters _p256 = ECCurve_secp256r1();

/// The P-256 field prime 2^256 − 2^224 + 2^192 + 2^96 − 1.
final BigInt _p256Prime = BigInt.parse(
  'ffffffff00000001000000000000000000000000ffffffffffffffffffffffff',
  radix: 16,
);
const _oidEcPublicKey = '1.2.840.10045.2.1';
const _oidP256 = '1.2.840.10045.3.1.7';

/// The P-256 public key of an X.509 cert; null if it isn't one (other curve,
/// RSA, point not on the curve, garbage).
ECPublicKey? p256PublicKeyFromCertDer(Uint8List der) {
  try {
    final cert = ASN1Parser(der).nextObject();
    if (cert is! ASN1Sequence) return null;
    final tbs = cert.elements?.firstOrNull;
    if (tbs is! ASN1Sequence) return null;
    final items = tbs.elements ?? const <ASN1Object>[];
    // Optional [0] version, then serial, signature, issuer, validity, subject.
    final offset = items.isNotEmpty && items.first.tag == 0xA0 ? 1 : 0;
    if (items.length <= offset + 5) return null;
    final spki = items[offset + 5];
    if (spki is! ASN1Sequence) return null;
    return _p256FromSpki(spki);
    // Peer-controlled bytes can fail any parser in any way.
    // ignore: avoid_catches_without_on_clauses
  } catch (_) {
    return null;
  }
}

ECPublicKey? _p256FromSpki(ASN1Sequence spki) {
  final parts = spki.elements ?? const <ASN1Object>[];
  if (parts.length != 2) return null;
  final alg = parts[0];
  final bits = parts[1];
  if (alg is! ASN1Sequence || bits is! ASN1BitString) return null;
  final algParts = alg.elements ?? const <ASN1Object>[];
  if (algParts.length != 2) return null;
  final a = algParts[0];
  final c = algParts[1];
  if (a is! ASN1ObjectIdentifier || c is! ASN1ObjectIdentifier) return null;
  if (a.objectIdentifierAsString != _oidEcPublicKey ||
      c.objectIdentifierAsString != _oidP256) {
    return null;
  }
  final point = bits.stringValues;
  if (point == null) return null;
  return p256PublicKeyFromPoint(Uint8List.fromList(point));
}

/// A P-256 public key from an uncompressed SEC1 point (65 bytes, `04‖X‖Y`);
/// null if the point isn't on the curve.
ECPublicKey? p256PublicKeyFromPoint(Uint8List point) {
  if (point.length != 65 || point[0] != 4) return null;
  final x = _bigInt(point.sublist(1, 33));
  final y = _bigInt(point.sublist(33));
  final p = _p256Prime;
  if (x >= p || y >= p) return null;
  final a = _p256.curve.a!.toBigInteger()!;
  final b = _p256.curve.b!.toBigInteger()!;
  if ((y * y - (x * x * x + a * x + b)) % p != BigInt.zero) return null;
  final q = _p256.curve.createPoint(x, y);
  return ECPublicKey(q, _p256);
}

/// Uncompressed SEC1 bytes of [key]'s point.
Uint8List publicPointBytes(ECPublicKey key) => key.Q!.getEncoded(false);

/// Strict DER `SEQUENCE { r INTEGER, s INTEGER }` with 0 < r, s < n; null for
/// anything else (including non-canonical encodings).
ECSignature? ecdsaSignatureFromDer(Uint8List der) {
  if (der.isEmpty || der.length > 80) return null;
  try {
    final seq = ASN1Parser(der).nextObject();
    if (seq is! ASN1Sequence) return null;
    final els = seq.elements ?? const <ASN1Object>[];
    if (els.length != 2) return null;
    final r = els[0];
    final s = els[1];
    if (r is! ASN1Integer || s is! ASN1Integer) return null;
    final ri = r.integer;
    final si = s.integer;
    if (ri == null || si == null) return null;
    final n = _p256.n;
    if (ri <= BigInt.zero || si <= BigInt.zero || ri >= n || si >= n) {
      return null;
    }
    final canonical = ecdsaSignatureToDer(ECSignature(ri, si));
    if (!_equal(canonical, der)) return null;
    return ECSignature(ri, si);
    // Peer-controlled bytes can fail any parser in any way.
    // ignore: avoid_catches_without_on_clauses
  } catch (_) {
    return null;
  }
}

/// DER encoding of [sig].
Uint8List ecdsaSignatureToDer(ECSignature sig) =>
    (ASN1Sequence()
          ..add(ASN1Integer(sig.r))
          ..add(ASN1Integer(sig.s)))
        .encode();

/// ECDSA P-256 / SHA-256 with deterministic k (RFC 6979), DER-encoded.
Uint8List ecdsaSign(ECPrivateKey key, Uint8List message) {
  final signer = ECDSASigner(SHA256Digest(), HMac(SHA256Digest(), 64))
    ..init(true, PrivateKeyParameter<ECPrivateKey>(key));
  final sig = signer.generateSignature(message) as ECSignature;
  return ecdsaSignatureToDer(sig);
}

/// The public key belonging to [key] (`d·G`).
ECPublicKey publicKeyOf(ECPrivateKey key) =>
    ECPublicKey(_p256.G * key.d, _p256);

/// base64url without padding (binary fields on the wire).
String b64url(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');

/// Decodes [b64url]; null on bad input.
Uint8List? fromB64url(String text) {
  if (text.contains('=')) return null;
  try {
    return base64Url.decode(base64Url.normalize(text));
  } on FormatException {
    return null;
  }
}

BigInt _bigInt(List<int> bytes) {
  var r = BigInt.zero;
  for (final b in bytes) {
    r = (r << 8) | BigInt.from(b);
  }
  return r;
}

bool _equal(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
