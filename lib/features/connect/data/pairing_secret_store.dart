import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';

import 'package:kfm/core/utils/random_id.dart';
import 'package:kfm/features/connect/data/crypto/constant_time.dart';
import 'package:kfm/features/connect/domain/pairing.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:meta/meta.dart';

/// Lifetime of a QR secret and of a short code (server clock only).
const Duration kPairSecretLifetime = Duration(minutes: 5);

/// Failed QR `POST /v1/pair` calls before the QR secret rotates.
const int kQrMaxFailures = 5;

/// `/v1/pair/code/start` calls per code before it rotates.
const int kCodeMaxAttempts = 5;

/// After a code lock, `/v1/pair/code/start` answers 429 for this long.
const Duration kCodeLockCooldown = Duration(seconds: 30);

/// Code locks per sharing run before typed codes turn off.
const int kMaxCodeLocks = 3;

/// SPAKE2 attempt state lifetime.
const Duration kSpakeAttemptLifetime = Duration(seconds: 30);

/// Outstanding SPAKE2 attempts in total (one per remote IP).
const int kSpakeAttemptsTotal = 4;

/// How a presented QR secret compares with what this run issued.
enum QrSecretMatch { active, used, expired, none }

/// Result of [PairingSecretStore.beginCodeAttempt].
sealed class CodeStartDecision {
  const new();
}

/// Go ahead with SPAKE2 using [code]; the attempt is already counted.
final class CodeStartGranted extends CodeStartDecision {
  const new(this.code);

  final ShortCode code;
}

/// Answer with [error] (`too_many_attempts` or `busy`).
final class CodeStartRefused extends CodeStartDecision {
  const new(this.error);

  final ApiErrorCode error;
}

/// One SPAKE2 run between `/code/start` and `/pair` (memory only).
@immutable
class SpakeAttempt {
  const new({
    required this.remoteIp,
    required this.clientCertPem,
    required this.transcript,
    required this.expectedConfirmA,
    required this.expiresAt,
  });

  final String remoteIp;
  final String clientCertPem;
  final Uint8List transcript;
  final Uint8List expectedConfirmA;
  final DateTime expiresAt;
}

/// The QR secret + short-code lifecycle of one sharing run (TASK-N2 →
/// "Secret and code rules"). Everything lives in memory only and is never
/// logged; [clear] wipes it when sharing stops.
class PairingSecretStore {
  /// [codeLength] is 8 in the app; tests use 2 (1024 codes) for the
  /// offline-guessing check. [_autoRefresh] schedules timers for expiry and
  /// the end of a cooldown (tests drive [refresh] with a fake clock).
  new({
    DateTime Function()? clock,
    Random? random,
    this.codeLength = kShortCodeLength,
    this._autoRefresh = true,
  }) : _clock = clock ?? DateTime.now,
       _random = random ?? Random.secure();

  final DateTime Function() _clock;
  final Random _random;
  final bool _autoRefresh;
  final int codeLength;

  final StreamController<PairingSecretState> _changes =
      StreamController.broadcast();

  // Offer template (set by start).
  List<ShareAddress>? _addresses;
  String? _fingerprint;
  String _deviceName = '';

  Uint8List? _secret;
  DateTime _secretExpires = DateTime.fromMillisecondsSinceEpoch(0);
  int _qrFailures = 0;

  ShortCode? _code;
  DateTime _codeExpires = DateTime.fromMillisecondsSinceEpoch(0);
  int _codeAttempts = 0;
  int _codeLocks = 0;
  DateTime? _cooldownUntil;

  /// Earlier secrets of this run, newest last, for `secret_used`/`expired`.
  final List<({Uint8List secret, QrSecretMatch fate})> _previous = [];

  final LinkedHashMap<String, SpakeAttempt> _attempts = LinkedHashMap();
  Timer? _timer;

  /// Every state change (broadcast).
  Stream<PairingSecretState> get changes => _changes.stream;

  bool get isActive => _secret != null;

  /// The server clock all expiries use (the share screen's countdown too).
  DateTime now() => _clock();

  /// This device's fingerprint while active.
  String? get serverFingerprint => _fingerprint;

  @visibleForTesting
  int get qrFailures => _qrFailures;
  @visibleForTesting
  int get codeAttempts => _codeAttempts;
  @visibleForTesting
  int get codeLocks => _codeLocks;
  @visibleForTesting
  int get attemptCount => _attempts.length;

  PairingSecretState get state {
    final secret = _secret;
    final code = _code;
    final addresses = _addresses;
    final fp = _fingerprint;
    if (secret == null || code == null || addresses == null || fp == null) {
      return const SecretIdle();
    }
    final now = _clock();
    final cooldown = _cooldownUntil;
    return SecretActive(
      offer: PairingOffer(
        addresses: addresses,
        serverFingerprint: fp,
        secret: secret,
        deviceName: _deviceName,
      ),
      code: code,
      expiresAt: _secretExpires,
      codeExpiresAt: _codeExpires,
      typedCodesEnabled: _codeLocks < kMaxCodeLocks,
      codeCooldownUntil: cooldown != null && now.isBefore(cooldown)
          ? cooldown
          : null,
    );
  }

  /// Starts a sharing run: a new QR secret and an independent new code.
  void start({
    required List<ShareAddress> addresses,
    required String serverFingerprint,
    required String deviceName,
  }) {
    _wipe();
    _addresses = List.unmodifiable(addresses.take(kMaxOfferAddresses));
    _fingerprint = serverFingerprint;
    _deviceName = deviceName;
    _newSecret();
    _newCode();
    _emit(null);
  }

  /// Sharing stopped: forgets everything.
  void clear() {
    if (!isActive) return;
    _wipe();
    _emit(null);
  }

  /// Rotates whatever expired; ends a finished cooldown. Called on every
  /// request and by the timer.
  void refresh() {
    if (!isActive) return;
    final now = _clock();
    var rotated = false;
    if (!now.isBefore(_secretExpires)) {
      _retireSecret(QrSecretMatch.expired);
      _newSecret();
      rotated = true;
    }
    if (!now.isBefore(_codeExpires)) {
      _newCode();
      _attempts.clear();
      rotated = true;
    }
    final cooldown = _cooldownUntil;
    var cooled = false;
    if (cooldown != null && !now.isBefore(cooldown)) {
      _cooldownUntil = null;
      cooled = true;
    }
    _purgeAttempts(now);
    if (rotated) {
      _emit(RotationReason.expired);
    } else if (cooled) {
      _emit(null);
    } else if (_timer == null || !_timer!.isActive) {
      _schedule();
    }
  }

  // ---- QR path ----

  /// Constant-time comparison against the active and earlier secrets.
  QrSecretMatch matchQrSecret(Uint8List secret) {
    refresh();
    var result = QrSecretMatch.none;
    final active = _secret;
    // Compare against every candidate (no early exit).
    if (active != null && constantTimeEquals(active, secret)) {
      result = QrSecretMatch.active;
    }
    for (final p in _previous) {
      if (constantTimeEquals(p.secret, secret) &&
          result == QrSecretMatch.none) {
        result = p.fate;
      }
    }
    return result;
  }

  /// Counts a failed QR `POST /v1/pair`. True when this failure locked the
  /// QR secret (it rotated; answer 429).
  bool recordQrFailure() {
    if (!isActive) return false;
    _qrFailures++;
    if (_qrFailures < kQrMaxFailures) return false;
    _retireSecret(QrSecretMatch.none);
    _newSecret();
    _emit(RotationReason.qrLocked);
    return true;
  }

  /// A fully valid QR pairing: one pairing per offer, so both rotate.
  void consumeQr() => _consume();

  // ---- Short-code path ----

  /// Counts one `/v1/pair/code/start` (rule 4). The 5th attempt is still
  /// granted; then the code rotates and a 30 s cooldown starts. A new
  /// attempt from an IP replaces that IP's outstanding one.
  CodeStartDecision beginCodeAttempt(String remoteIp) {
    refresh();
    final code = _code;
    if (!isActive || code == null) {
      return const CodeStartRefused(ApiErrorCode.pairingFailed);
    }
    if (_codeLocks >= kMaxCodeLocks || _cooldownUntil != null) {
      return const CodeStartRefused(ApiErrorCode.tooManyAttempts);
    }
    _attempts.removeWhere((_, a) => a.remoteIp == remoteIp);
    if (_attempts.length >= kSpakeAttemptsTotal) {
      return const CodeStartRefused(ApiErrorCode.busy);
    }
    _codeAttempts++;
    if (_codeAttempts >= kCodeMaxAttempts) {
      _codeLocks++;
      _newCode();
      _cooldownUntil = _clock().add(kCodeLockCooldown);
      _emit(RotationReason.codeLocked);
    }
    return CodeStartGranted(code);
  }

  /// Stores a SPAKE2 run for 30 s; returns its id.
  String addAttempt({
    required String remoteIp,
    required String clientCertPem,
    required Uint8List transcript,
    required Uint8List expectedConfirmA,
  }) {
    final id = randomHexId(_random);
    _attempts[id] = SpakeAttempt(
      remoteIp: remoteIp,
      clientCertPem: clientCertPem,
      transcript: transcript,
      expectedConfirmA: expectedConfirmA,
      expiresAt: _clock().add(kSpakeAttemptLifetime),
    );
    return id;
  }

  /// Removes and returns the attempt if it exists, hasn't expired and came
  /// from [remoteIp] (single use either way).
  SpakeAttempt? takeAttempt(String attemptId, String remoteIp) {
    refresh();
    final a = _attempts.remove(attemptId);
    if (a == null) return null;
    if (!_clock().isBefore(a.expiresAt)) return null;
    return a.remoteIp == remoteIp ? a : null;
  }

  /// A fully valid code pairing: both rotate.
  void consumeCode() => _consume();

  // ---- internals ----

  void _consume() {
    if (!isActive) return;
    _retireSecret(QrSecretMatch.used);
    _newSecret();
    _newCode();
    _attempts.clear();
    _emit(RotationReason.consumed);
  }

  void _newSecret() {
    _secret = Uint8List.fromList(
      List.generate(32, (_) => _random.nextInt(256)),
    );
    _secretExpires = _clock().add(kPairSecretLifetime);
    _qrFailures = 0;
  }

  /// Independent of the QR secret (typing it reveals nothing about the QR).
  void _newCode() {
    _code = ShortCode(
      List.generate(
        codeLength,
        (_) => kCrockfordAlphabet[_random.nextInt(kCrockfordAlphabet.length)],
      ).join(),
    );
    _codeExpires = _clock().add(kPairSecretLifetime);
    _codeAttempts = 0;
  }

  void _retireSecret(QrSecretMatch fate) {
    final s = _secret;
    if (s == null) return;
    _previous.add((secret: s, fate: fate));
    if (_previous.length > 8) _previous.removeAt(0);
  }

  void _purgeAttempts(DateTime now) =>
      _attempts.removeWhere((_, a) => !now.isBefore(a.expiresAt));

  void _wipe() {
    _timer?.cancel();
    _timer = null;
    _addresses = null;
    _fingerprint = null;
    _deviceName = '';
    _secret = null;
    _code = null;
    _qrFailures = 0;
    _codeAttempts = 0;
    _codeLocks = 0;
    _cooldownUntil = null;
    _previous.clear();
    _attempts.clear();
  }

  void _emit(RotationReason? reason) {
    _schedule();
    if (reason != null) _changes.add(SecretRotated(reason));
    _changes.add(state);
  }

  void _schedule() {
    _timer?.cancel();
    _timer = null;
    if (!_autoRefresh || !isActive) return;
    var next = _secretExpires.isBefore(_codeExpires)
        ? _secretExpires
        : _codeExpires;
    final cooldown = _cooldownUntil;
    if (cooldown != null && cooldown.isBefore(next)) next = cooldown;
    final wait = next.difference(_clock());
    _timer = Timer(
      wait.isNegative ? Duration.zero : wait + const Duration(milliseconds: 50),
      refresh,
    );
  }
}
