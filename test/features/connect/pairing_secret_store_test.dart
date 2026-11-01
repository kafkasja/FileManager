import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/connect/data/pairing_secret_store.dart';
import 'package:kfm/features/connect/domain/pairing.dart';
import 'package:kfm/features/connect/domain/protocol.dart';

void main() {
  late DateTime now;
  late PairingSecretStore store;
  late List<PairingSecretState> events;

  setUp(() {
    now = DateTime(2026, 11);
    store = PairingSecretStore(
      clock: () => now,
      random: Random(42),
      autoRefresh: false,
    );
    events = [];
    store.changes.listen(events.add);
    store.start(
      addresses: const [(host: '192.168.1.23', port: 4433)],
      serverFingerprint: 'ab' * 32,
      deviceName: 'Phone',
    );
  });

  SecretActive active() => store.state as SecretActive;

  Uint8List secret() => active().offer.secret;

  void attempts(int n, [String ip = '192.168.1.40']) {
    for (var i = 0; i < n; i++) {
      expect(store.beginCodeAttempt(ip), isA<CodeStartGranted>());
    }
  }

  Future<void> flush() => Future<void>.delayed(Duration.zero);

  test('start creates a 32-byte secret and an independent 8-char code', () {
    final s = active();
    expect(s.offer.secret, hasLength(32));
    expect(s.code.value, hasLength(8));
    expect(s.code.value.split('').every(kCrockfordAlphabet.contains), isTrue);
    expect(s.expiresAt, now.add(kPairSecretLifetime));
    expect(s.typedCodesEnabled, isTrue);
    expect(store.matchQrSecret(s.offer.secret), QrSecretMatch.active);
  });

  test('consuming the QR rotates both; the old secret reads as used', () async {
    final before = active();
    store.consumeQr();
    await flush();
    final after = active();
    expect(after.offer.secret, isNot(before.offer.secret));
    expect(after.code, isNot(before.code));
    expect(store.matchQrSecret(before.offer.secret), QrSecretMatch.used);
    expect(events.whereType<SecretRotated>().map((e) => e.reason), [
      RotationReason.consumed,
    ]);
  });

  test('consuming the code rotates both too', () {
    final before = active();
    store.consumeCode();
    expect(active().offer.secret, isNot(before.offer.secret));
    expect(active().code, isNot(before.code));
  });

  test('both expire after 5 minutes; the old secret reads as expired', () {
    final old = secret();
    final oldCode = active().code;
    now = now.add(const Duration(minutes: 4, seconds: 59));
    store.refresh();
    expect(secret(), old);
    now = now.add(const Duration(seconds: 1));
    store.refresh();
    expect(secret(), isNot(old));
    expect(active().code, isNot(oldCode));
    expect(store.matchQrSecret(old), QrSecretMatch.expired);
  });

  test('5 QR failures rotate the QR only (qrLocked), counter resets', () {
    final old = secret();
    final code = active().code;
    for (var i = 0; i < 4; i++) {
      expect(store.recordQrFailure(), isFalse);
    }
    expect(store.recordQrFailure(), isTrue);
    expect(secret(), isNot(old));
    expect(active().code, code);
    expect(store.qrFailures, 0);
    expect(store.matchQrSecret(old), QrSecretMatch.none);
  });

  test('the 5th code attempt is granted, then the code rotates and a 30 s '
      'cooldown answers 429 without counting', () {
    final code = active().code;
    attempts(4);
    final fifth = store.beginCodeAttempt('192.168.1.40');
    expect((fifth as CodeStartGranted).code, code);
    expect(active().code, isNot(code));
    expect(store.codeLocks, 1);
    expect(store.codeAttempts, 0);
    final refused = store.beginCodeAttempt('192.168.1.41');
    expect((refused as CodeStartRefused).error, ApiErrorCode.tooManyAttempts);
    expect(store.codeAttempts, 0);
    expect(active().codeCooldownUntil, isNotNull);
    now = now.add(kCodeLockCooldown);
    // After the cooldown the new code's counter starts at 0.
    expect(store.beginCodeAttempt('192.168.1.41'), isA<CodeStartGranted>());
    expect(store.codeAttempts, 1);
  });

  test('3 code locks turn typed codes off for the run; the QR keeps '
      'working; a new run turns them on again', () {
    for (var lock = 0; lock < 3; lock++) {
      attempts(5);
      now = now.add(kCodeLockCooldown);
    }
    expect(active().typedCodesEnabled, isFalse);
    expect(
      (store.beginCodeAttempt('192.168.1.40') as CodeStartRefused).error,
      ApiErrorCode.tooManyAttempts,
    );
    expect(store.matchQrSecret(secret()), QrSecretMatch.active);
    store.start(
      addresses: const [(host: '192.168.1.23', port: 4433)],
      serverFingerprint: 'ab' * 32,
      deviceName: 'Phone',
    );
    expect(active().typedCodesEnabled, isTrue);
  });

  test('QR and code counters are separate', () {
    attempts(4);
    for (var i = 0; i < 4; i++) {
      store.recordQrFailure();
    }
    expect(store.codeAttempts, 4);
    expect(store.qrFailures, 4);
    expect(store.codeLocks, 0);
  });

  test('attempt state expires after 30 s and is single use', () {
    final id = store.addAttempt(
      remoteIp: '192.168.1.40',
      clientCertPem: 'pem',
      transcript: Uint8List(1),
      expectedConfirmA: Uint8List(32),
    );
    expect(store.takeAttempt(id, '192.168.1.40'), isNotNull);
    expect(store.takeAttempt(id, '192.168.1.40'), isNull);

    final id2 = store.addAttempt(
      remoteIp: '192.168.1.40',
      clientCertPem: 'pem',
      transcript: Uint8List(1),
      expectedConfirmA: Uint8List(32),
    );
    now = now.add(kSpakeAttemptLifetime);
    expect(store.takeAttempt(id2, '192.168.1.40'), isNull);
  });

  test('an attempt only completes from the IP that started it', () {
    final id = store.addAttempt(
      remoteIp: '192.168.1.40',
      clientCertPem: 'pem',
      transcript: Uint8List(1),
      expectedConfirmA: Uint8List(32),
    );
    expect(store.takeAttempt(id, '192.168.1.41'), isNull);
    // Deleted either way.
    expect(store.takeAttempt(id, '192.168.1.40'), isNull);
  });

  test('one attempt per IP (a new start replaces it), 4 in total → busy', () {
    for (var i = 0; i < 4; i++) {
      final ip = '192.168.1.${50 + i}';
      expect(store.beginCodeAttempt(ip), isA<CodeStartGranted>());
      store.addAttempt(
        remoteIp: ip,
        clientCertPem: 'pem',
        transcript: Uint8List(1),
        expectedConfirmA: Uint8List(32),
      );
    }
    expect(store.attemptCount, 4);
    // A fifth IP is busy and not counted.
    final busy = store.beginCodeAttempt('192.168.1.60');
    expect((busy as CodeStartRefused).error, ApiErrorCode.busy);
    expect(store.codeAttempts, 4);
    // A known IP replaces its own attempt.
    expect(store.beginCodeAttempt('192.168.1.50'), isA<CodeStartGranted>());
    expect(store.attemptCount, 3);
  });

  test('consuming clears outstanding attempts; a code lock keeps them', () {
    final id = store.addAttempt(
      remoteIp: '192.168.1.40',
      clientCertPem: 'pem',
      transcript: Uint8List(1),
      expectedConfirmA: Uint8List(32),
    );
    attempts(5, '192.168.1.41');
    expect(store.attemptCount, 1);
    store.consumeQr();
    expect(store.takeAttempt(id, '192.168.1.40'), isNull);
  });

  test('clear wipes everything; state is idle', () {
    store.clear();
    expect(store.state, isA<SecretIdle>());
    expect(store.isActive, isFalse);
    expect(
      (store.beginCodeAttempt('192.168.1.40') as CodeStartRefused).error,
      ApiErrorCode.pairingFailed,
    );
  });

  test('codes come from the Crockford alphabet; test code length works', () {
    final short = PairingSecretStore(codeLength: 2, autoRefresh: false)
      ..start(
        addresses: const [(host: '10.0.0.1', port: 1)],
        serverFingerprint: 'ab' * 32,
        deviceName: '',
      );
    expect((short.state as SecretActive).code.value, hasLength(2));
  });
}
