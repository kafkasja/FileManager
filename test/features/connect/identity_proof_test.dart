import 'dart:convert';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart' show CryptoUtils, X509Utils;
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/connect/data/crypto/identity_proof.dart';
import 'package:kfm/features/connect/data/device_identity_repository_impl.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:pointycastle/export.dart';

Uint8List _b(String s) => Uint8List.fromList(utf8.encode(s));

void main() {
  late IdentityMaterial a;
  late IdentityMaterial b;

  setUpAll(() {
    a = generateIdentityMaterial();
    b = generateIdentityMaterial();
  });

  Uint8List sign(IdentityMaterial m, Uint8List msg) =>
      signWithPem(m.privateKeyPem, msg);

  test('signedMessage is label then length-prefixed fields', () {
    final m = signedMessage('L', [
      Uint8List.fromList([1, 2]),
      Uint8List(0),
    ]);
    expect(m, [76, 0, 0, 0, 2, 1, 2, 0, 0, 0, 0]);
  });

  test('a proof round-trips and returns the cert fingerprint', () {
    final msg = signedMessage(ProofLabels.pairKnown, [_b('fp'), _b('nonce')]);
    final fp = verifyIdentityProof(
      certPem: a.certPem,
      message: msg,
      sig: sign(a, msg),
    );
    expect(fp, a.fingerprint);
    expect(fp, hasLength(64));
    expect(fp, matches(RegExp(r'^[0-9a-f]{64}$')));
  });

  test('signatures are deterministic (RFC 6979)', () {
    final msg = _b('same message');
    expect(sign(a, msg), sign(a, msg));
  });

  test('wrong label, field order, flipped bit and other key all fail', () {
    final f1 = _b('server-fp');
    final f2 = _b('nonce-bytes');
    final msg = signedMessage(ProofLabels.pairQr, [f1, f2]);
    final sig = sign(a, msg);

    expect(
      verifyIdentityProof(
        certPem: a.certPem,
        message: signedMessage(ProofLabels.pairKnown, [f1, f2]),
        sig: sig,
      ),
      isNull,
    );
    expect(
      verifyIdentityProof(
        certPem: a.certPem,
        message: signedMessage(ProofLabels.pairQr, [f2, f1]),
        sig: sig,
      ),
      isNull,
    );
    final flipped = Uint8List.fromList(msg)..[msg.length - 1] ^= 1;
    expect(
      verifyIdentityProof(certPem: a.certPem, message: flipped, sig: sig),
      isNull,
    );
    final badSig = Uint8List.fromList(sig)..[sig.length - 1] ^= 1;
    expect(
      verifyIdentityProof(certPem: a.certPem, message: msg, sig: badSig),
      isNull,
    );
    expect(
      verifyIdentityProof(certPem: b.certPem, message: msg, sig: sig),
      isNull,
    );
  });

  test('length prefixes stop field-boundary shifting', () {
    final x = signedMessage('L', [_b('ab'), _b('c')]);
    final y = signedMessage('L', [_b('a'), _b('bc')]);
    expect(x, isNot(y));
  });

  test('non-P-256 cert, oversized PEM and garbage return null', () {
    final msg = _b('m');
    final sig = sign(a, msg);
    // P-384 cert.
    final pair = CryptoUtils.generateEcKeyPair(curve: 'secp384r1');
    final priv = pair.privateKey as ECPrivateKey;
    final pub = pair.publicKey as ECPublicKey;
    final csr = X509Utils.generateEccCsrPem({'CN': 'x'}, priv, pub);
    final p384 = X509Utils.generateSelfSignedCertificate(priv, csr, 10);
    expect(verifyIdentityProof(certPem: p384, message: msg, sig: sig), isNull);

    final huge = '${a.certPem}\n${'A' * kMaxCertPemBytes}';
    expect(verifyIdentityProof(certPem: huge, message: msg, sig: sig), isNull);

    for (final junk in [
      '',
      'hello',
      '-----BEGIN CERTIFICATE-----\n!!!\n-----END CERTIFICATE-----',
      '-----BEGIN CERTIFICATE-----\nAAAA\n-----END CERTIFICATE-----',
      '${a.certPem}\n${b.certPem}',
      a.privateKeyPem,
    ]) {
      expect(
        verifyIdentityProof(certPem: junk, message: msg, sig: sig),
        isNull,
        reason: junk,
      );
    }
    for (final badSig in [
      Uint8List(0),
      Uint8List.fromList([0x30, 0x00]),
      Uint8List(200),
      Uint8List.fromList(List.filled(70, 0xff)),
    ]) {
      expect(
        verifyIdentityProof(certPem: a.certPem, message: msg, sig: badSig),
        isNull,
      );
    }
  });

  test('a point off the curve is rejected', () {
    final point = Uint8List(65)..[0] = 4;
    point[64] = 1;
    expect(p256PublicKeyFromPoint(point), isNull);
  });

  test('certFingerprint matches the identity fingerprint', () {
    expect(certFingerprint(a.certPem), a.fingerprint);
    expect(certFingerprint('nope'), isNull);
  });

  test('base64url has no padding and round-trips', () {
    final bytes = Uint8List.fromList(List.generate(32, (i) => i * 7));
    final text = b64url(bytes);
    expect(text.contains('='), isFalse);
    expect(fromB64url(text), bytes);
    expect(fromB64url('a=='), isNull);
    expect(fromB64url('***'), isNull);
  });

  test('an OpenSSL-made signature verifies (independent check)', () {
    // `openssl dgst -sha256 -sign key.pem msg.bin` over bytes 0..99, with
    // the key of this KFM-generated cert (N1 spike, 2026-11-01).
    const cert = '''
-----BEGIN CERTIFICATE-----
MIIBTjCB8qADAgECAggO8Mh5I31KtDAMBggqhkjOPQQDAgUAMCsxKTAnBgNVBAMT
IGU2NWNlMjRiOWY5ZjMxMmRjZTBiMTk3YzBjMjM1N2U4MB4XDTI2MTEwMTE4MDcx
MFoXDTM2MTAyOTE4MDcxMFowKzEpMCcGA1UEAxMgZTY1Y2UyNGI5ZjlmMzEyZGNl
MGIxOTdjMGMyMzU3ZTgwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAAQKp3weC/8D
AlnCCvY6O1rJO+FlntbgqU9+ZuQDLhZxSSlTH4scRkqa4NnXMO1d2YiIGOAr/2Th
vgjzF53i9gACMAwGCCqGSM49BAMCBQADSQAwRgIhANqj6Mp7F1YGA8oFhiwD+/Ox
DbBMPYCyvTQE9S+5ZGnbAiEAgdlO0IEDxl3BVeww3rSGiJ8JBX7z83ukEv15SSCr
Yxg=
-----END CERTIFICATE-----''';
    final sig = base64.decode(
      'MEUCIQCCL0SO0bEL3PsLjLj7ty8gDgaLVqA2B4fMG0rwxsY7xwIgbKPnV0skTs65e9y3'
      'nFsyIEOj2qSvDsEAfPf91B8bQ/U=',
    );
    final msg = Uint8List.fromList(List.generate(100, (i) => i));
    expect(
      verifyIdentityProof(certPem: cert, message: msg, sig: sig),
      'eb2f42fa75e772b6580f39a6da340501d7974cb63c9c52b90f83ea513b9d7302',
    );
    msg[0] = 1;
    expect(verifyIdentityProof(certPem: cert, message: msg, sig: sig), isNull);
  });
}
