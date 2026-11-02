import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';

import 'package:kfm/features/connect/domain/protocol.dart';

/// Single-use pair nonces (TASK-N1; consumed by N2's QR path and N6's
/// remembered-device path). In memory only; cleared when sharing stops.
///
/// Each nonce is valid for [kPairNonceLifetime] and is removed by [consume]
/// whether the proof then succeeds or not. At most [kPairNoncesPerIp]
/// outstanding per remote IP and [kPairNoncesTotal] in total (oldest
/// evicted), so the unauthenticated route can't exhaust memory.
class PairNonceStore {
  new({DateTime Function()? clock, Random? random})
    : _clock = clock ?? DateTime.now,
      _random = random ?? Random.secure();

  final DateTime Function() _clock;
  final Random _random;

  /// Insertion order = age (first = oldest). Keyed by the nonce bytes.
  final LinkedHashMap<String, _Entry> _entries = LinkedHashMap();

  /// Outstanding (not expired, not consumed) nonces.
  int get length {
    _purgeExpired();
    return _entries.length;
  }

  /// A fresh 32-byte nonce for [remoteIp].
  Uint8List issue(String remoteIp) {
    _purgeExpired();
    final forIp = _entries.entries
        .where((e) => e.value.remoteIp == remoteIp)
        .map((e) => e.key)
        .toList();
    if (forIp.length >= kPairNoncesPerIp) {
      _entries.remove(forIp.first);
    }
    while (_entries.length >= kPairNoncesTotal) {
      _entries.remove(_entries.keys.first);
    }
    final nonce = Uint8List.fromList(
      List.generate(32, (_) => _random.nextInt(256)),
    );
    _entries[_key(nonce)] = _Entry(remoteIp, _clock().add(kPairNonceLifetime));
    return nonce;
  }

  /// True only for a nonce issued to [remoteIp] that hasn't expired or been
  /// used. Always removes it (single use, success or not).
  bool consume(String remoteIp, Uint8List nonce) {
    final entry = _entries.remove(_key(nonce));
    if (entry == null) return false;
    if (!_clock().isBefore(entry.expiresAt)) return false;
    return entry.remoteIp == remoteIp;
  }

  /// Forgets every nonce (sharing stopped).
  void clear() => _entries.clear();

  void _purgeExpired() {
    final now = _clock();
    _entries.removeWhere((_, e) => !now.isBefore(e.expiresAt));
  }

  static String _key(Uint8List nonce) =>
      String.fromCharCodes(nonce); // exact bytes; never logged
}

class _Entry {
  new(this.remoteIp, this.expiresAt);

  final String remoteIp;
  final DateTime expiresAt;
}
