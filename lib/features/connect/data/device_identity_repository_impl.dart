import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart'
    show CryptoUtils, ECPrivateKey, ECPublicKey, X509Utils;
import 'package:kfm/core/utils/random_id.dart';
import 'package:kfm/features/connect/data/crypto/identity_proof.dart';
import 'package:kfm/features/connect/data/secret_store.dart';
import 'package:kfm/features/connect/domain/device_identity.dart';
import 'package:meta/meta.dart';

/// Secure-storage key of the identity blob (one JSON value, so its parts can
/// never get out of sync).
const String kIdentityStorageKey = 'kfm.identity.v1';

/// The parts of the identity blob.
@immutable
class IdentityMaterial {
  const new({
    required this.deviceId,
    required this.certPem,
    required this.privateKeyPem,
    required this.rootIdSalt,
    required this.fingerprint,
  });

  final String deviceId;
  final String certPem;

  /// PKCS#8.
  final String privateKeyPem;
  final Uint8List rootIdSalt;
  final String fingerprint;

  String toBlob() => jsonEncode({
    'v': 1,
    'deviceId': deviceId,
    'certPem': certPem,
    'privateKeyPem': privateKeyPem,
    'rootIdSalt': b64url(rootIdSalt),
  });
}

/// Creates a new P-256 key, a self-signed cert (CN = deviceId, 10 years,
/// random serial) and a salt. CPU-heavy: run it in an isolate.
IdentityMaterial generateIdentityMaterial() {
  final random = Random.secure();
  final deviceId = randomHexId(random);
  final pair = CryptoUtils.generateEcKeyPair();
  final priv = pair.privateKey as ECPrivateKey;
  final pub = pair.publicKey as ECPublicKey;
  final csr = X509Utils.generateEccCsrPem({'CN': deviceId}, priv, pub);
  // Positive 62-bit serial; the fingerprint, not the serial, is the identity.
  final serial =
      (BigInt.from(random.nextInt(1 << 31)) << 31) |
      BigInt.from(random.nextInt(1 << 31) + 1);
  final certPem = X509Utils.generateSelfSignedCertificate(
    priv,
    csr,
    3650,
    serialNumber: serial.toString(),
  ).replaceAll('\r\n', '\n');
  final keyPem = CryptoUtils.encodePrivateEcdsaKeyToPkcs8(priv);
  final salt = Uint8List.fromList(
    List.generate(32, (_) => random.nextInt(256)),
  );
  return IdentityMaterial(
    deviceId: deviceId,
    certPem: certPem,
    privateKeyPem: keyPem,
    rootIdSalt: salt,
    fingerprint: certFingerprint(certPem)!,
  );
}

/// Parses a stored blob and checks that the private key belongs to the
/// cert's public key. Null on any problem (missing field, parse error,
/// mismatch).
IdentityMaterial? parseIdentityBlob(String blob) {
  try {
    final json = jsonDecode(blob);
    if (json is! Map<String, Object?> || json['v'] != 1) return null;
    final deviceId = json['deviceId'];
    final certPem = json['certPem'];
    final keyPem = json['privateKeyPem'];
    final saltText = json['rootIdSalt'];
    if (deviceId is! String ||
        certPem is! String ||
        keyPem is! String ||
        saltText is! String) {
      return null;
    }
    if (!RegExp(r'^[0-9a-f]{32}$').hasMatch(deviceId)) return null;
    final salt = fromB64url(saltText);
    if (salt == null || salt.length != 32) return null;
    final der = certDerFromPem(certPem);
    if (der == null) return null;
    final certKey = p256PublicKeyFromCertDer(der);
    if (certKey == null) return null;
    final priv = _privateKeyFromPem(keyPem);
    if (priv == null) return null;
    final derived = publicPointBytes(publicKeyOf(priv));
    final expected = publicPointBytes(certKey);
    if (!_equal(derived, expected)) return null;
    return IdentityMaterial(
      deviceId: deviceId,
      certPem: certPem,
      privateKeyPem: keyPem,
      rootIdSalt: salt,
      fingerprint: fingerprintOfDer(der),
    );
    // A corrupt blob can fail in any parser; every failure means "regenerate".
    // ignore: avoid_catches_without_on_clauses
  } catch (_) {
    return null;
  }
}

ECPrivateKey? _privateKeyFromPem(String pem) {
  if (!pem.trim().startsWith('-----BEGIN PRIVATE KEY-----')) return null;
  try {
    final key = CryptoUtils.ecPrivateKeyFromPem(pem.trim());
    final d = key.d;
    if (d == null || d <= BigInt.zero) return null;
    if (key.parameters?.domainName != 'prime256v1') return null;
    return key;
    // A corrupt stored key can fail the parser in any way.
    // ignore: avoid_catches_without_on_clauses
  } catch (_) {
    return null;
  }
}

bool _equal(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Signs [message] with [keyPem] (top-level so it can run in an isolate).
Uint8List signWithPem(String keyPem, Uint8List message) =>
    ecdsaSign(_privateKeyFromPem(keyPem)!, message);

/// Runs [fn] in a background isolate (tests may run it inline).
typedef IsolateRunner = Future<R> Function<R>(R Function() fn);

Future<R> _isolateRun<R>(R Function() fn) => Isolate.run(fn);

/// [DeviceIdentityRepository] over [SecretStore] (TASK-N1).
class DeviceIdentityRepositoryImpl implements DeviceIdentityRepository {
  new({
    required this._store,
    required this._displayName,
    required this._platform,
    IsolateRunner? run,
    IdentityMaterial Function()? generate,
  }) : _run = run ?? _isolateRun,
       _generate = generate ?? generateIdentityMaterial;

  final SecretStore _store;
  final Future<String> Function() _displayName;
  final String _platform;
  final IsolateRunner _run;
  final IdentityMaterial Function() _generate;

  Future<IdentityMaterial>? _material;

  @override
  Future<DeviceIdentity> loadOrCreate() async {
    final m = await _loadMaterial();
    return DeviceIdentity(
      deviceId: m.deviceId,
      displayName: await _displayName(),
      platform: _platform,
      certPem: m.certPem,
      fingerprint: m.fingerprint,
    );
  }

  @override
  Future<String> privateKeyPem() async => (await _loadMaterial()).privateKeyPem;

  @override
  Future<Uint8List> rootIdSalt() async =>
      Uint8List.fromList((await _loadMaterial()).rootIdSalt);

  @override
  Future<Uint8List> sign(Uint8List message) async {
    final pem = (await _loadMaterial()).privateKeyPem;
    return await _run(() => signWithPem(pem, message));
  }

  @override
  Future<DeviceIdentity> reset() async {
    _material = null;
    await _store.delete(kIdentityStorageKey);
    return await loadOrCreate();
  }

  /// One load at a time; a failed load is retried on the next call.
  Future<IdentityMaterial> _loadMaterial() {
    final pending = _material ??= _readOrCreate();
    return pending.catchError((Object e, StackTrace st) {
      if (identical(_material, pending)) _material = null;
      Error.throwWithStackTrace(e, st);
    });
  }

  Future<IdentityMaterial> _readOrCreate() async {
    final blob = await _store.read(kIdentityStorageKey);
    if (blob != null) {
      final parsed = await _run(() => parseIdentityBlob(blob));
      if (parsed != null) return parsed;
      // Never log the blob itself.
      developer.log(
        'stored device identity is unreadable; creating a new one',
        name: 'kfm.connect',
      );
    }
    final gen = _generate;
    final fresh = await _run(gen);
    await _store.write(kIdentityStorageKey, fresh.toBlob());
    return fresh;
  }
}
