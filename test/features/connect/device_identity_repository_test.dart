import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/connect/data/crypto/identity_proof.dart';
import 'package:kfm/features/connect/data/device_identity_repository_impl.dart';
import 'package:kfm/features/connect/data/secret_store.dart';

void main() {
  late InMemorySecretStore store;
  var generated = 0;

  DeviceIdentityRepositoryImpl repo({bool isolate = false}) =>
      DeviceIdentityRepositoryImpl(
        store: store,
        displayName: () async => 'Test phone',
        platform: 'android',
        run: isolate ? null : <R>(R Function() fn) async => fn(),
        generate: () {
          generated++;
          return generateIdentityMaterial();
        },
      );

  setUp(() {
    store = InMemorySecretStore();
    generated = 0;
  });

  test('first call generates (in an isolate) and persists one blob', () async {
    final id = await repo(isolate: true).loadOrCreate();
    expect(id.deviceId, matches(RegExp(r'^[0-9a-f]{32}$')));
    expect(id.displayName, 'Test phone');
    expect(id.platform, 'android');
    expect(id.fingerprint, certFingerprint(id.certPem));
    expect(store.values.keys, [kIdentityStorageKey]);
    final blob = jsonDecode(store.values[kIdentityStorageKey]!) as Map;
    expect(blob.keys, {
      'v',
      'deviceId',
      'certPem',
      'privateKeyPem',
      'rootIdSalt',
    });
  });

  test('a second repository (app restart) returns the same identity', () async {
    final first = await repo().loadOrCreate();
    final second = await repo().loadOrCreate();
    expect(second.fingerprint, first.fingerprint);
    expect(second.deviceId, first.deviceId);
    expect(generated, 1);
    expect(await repo().rootIdSalt(), hasLength(32));
  });

  test('concurrent calls generate only once', () async {
    final r = repo();
    final ids = await Future.wait([r.loadOrCreate(), r.loadOrCreate()]);
    expect(ids[0].fingerprint, ids[1].fingerprint);
    expect(generated, 1);
  });

  test('a deleted value regenerates everything without a crash', () async {
    final first = await repo().loadOrCreate();
    final salt = await repo().rootIdSalt();
    store.values.clear();
    final r = repo();
    final second = await r.loadOrCreate();
    expect(second.fingerprint, isNot(first.fingerprint));
    expect(second.deviceId, isNot(first.deviceId));
    expect(await r.rootIdSalt(), isNot(salt));
  });

  test('a corrupt blob regenerates', () async {
    for (final junk in [
      'not json',
      '{}',
      '{"v":1}',
      '[]',
      jsonEncode({'v': 2}),
    ]) {
      store.values[kIdentityStorageKey] = junk;
      final id = await repo().loadOrCreate();
      expect(id.fingerprint, hasLength(64), reason: junk);
      expect(store.values[kIdentityStorageKey], isNot(junk));
    }
  });

  test('a key that does not match the cert regenerates', () async {
    final a = generateIdentityMaterial();
    final b = generateIdentityMaterial();
    final mixed = IdentityMaterial(
      deviceId: a.deviceId,
      certPem: a.certPem,
      privateKeyPem: b.privateKeyPem,
      rootIdSalt: a.rootIdSalt,
      fingerprint: a.fingerprint,
    );
    expect(parseIdentityBlob(a.toBlob()), isNotNull);
    expect(parseIdentityBlob(mixed.toBlob()), isNull);
    store.values[kIdentityStorageKey] = mixed.toBlob();
    final id = await repo().loadOrCreate();
    expect(id.fingerprint, isNot(a.fingerprint));
    expect(generated, 1);
  });

  test('sign produces a proof that verifies against the cert', () async {
    final r = repo(isolate: true);
    final id = await r.loadOrCreate();
    final msg = Uint8List.fromList(utf8.encode('hello'));
    final sig = await r.sign(msg);
    expect(
      verifyIdentityProof(certPem: id.certPem, message: msg, sig: sig),
      id.fingerprint,
    );
  });

  test('reset creates a new identity', () async {
    final r = repo();
    final first = await r.loadOrCreate();
    final second = await r.reset();
    expect(second.fingerprint, isNot(first.fingerprint));
    expect((await repo().loadOrCreate()).fingerprint, second.fingerprint);
  });

  test('a failing store surfaces the error and retries next time', () async {
    final failing = _FailOnceStore();
    final r = DeviceIdentityRepositoryImpl(
      store: failing,
      displayName: () async => 'x',
      platform: 'android',
      run: <R>(R Function() fn) async => fn(),
    );
    await expectLater(r.loadOrCreate(), throwsA(isA<StateError>()));
    expect((await r.loadOrCreate()).fingerprint, hasLength(64));
  });
}

class _FailOnceStore extends InMemorySecretStore {
  bool _failed = false;

  @override
  Future<String?> read(String key) async {
    if (!_failed) {
      _failed = true;
      throw StateError('keystore unavailable');
    }
    return await super.read(key);
  }
}
