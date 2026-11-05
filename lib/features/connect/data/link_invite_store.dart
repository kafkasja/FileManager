import 'dart:math';
import 'dart:typed_data';

import 'package:kfm/features/connect/data/crypto/constant_time.dart';
import 'package:meta/meta.dart';

/// How long a back-link invite stays valid (TASK-E1).
const Duration kLinkInviteLifetime = Duration(seconds: 60);

/// Invite length in bytes.
const int kLinkInviteBytes = 32;

/// One issued invite: for exactly [peerFingerprint], from [remoteIp].
@immutable
class LinkInvite {
  const new({
    required this.bytes,
    required this.peerFingerprint,
    required this.remoteIp,
    required this.expiresAt,
  });

  final Uint8List bytes;

  /// The peer this device paired with (its server cert fingerprint from the
  /// pairing): the join's identity proof must verify for this key.
  final String peerFingerprint;

  /// The peer's address as this device reached it: joins from elsewhere
  /// are refused.
  final String remoteIp;
  final DateTime expiresAt;
}

/// Single-use back-link invites (TASK-E1 `/v1/link` → `/v1/link/join`).
/// The device that scanned (A) issues one per pairing and hands it to the
/// peer (B) over the pinned, authenticated connection; B presents it to
/// A's server with an identity proof. Memory only; [clear] on stop
/// sharing.
class LinkInviteStore {
  new({DateTime Function()? clock, Random? random})
    : _clock = clock ?? DateTime.now,
      _random = random ?? Random.secure();

  final DateTime Function() _clock;
  final Random _random;
  final List<LinkInvite> _open = [];

  /// At most this many open invites (one per pairing; older ones drop).
  static const int _max = 4;

  /// A fresh invite for [peerFingerprint] joining from [remoteIp].
  Uint8List issue({required String peerFingerprint, required String remoteIp}) {
    _expire();
    final bytes = Uint8List.fromList(
      List<int>.generate(kLinkInviteBytes, (_) => _random.nextInt(256)),
    );
    _open
      ..removeWhere((i) => i.peerFingerprint == peerFingerprint)
      ..add(
        LinkInvite(
          bytes: bytes,
          peerFingerprint: peerFingerprint,
          remoteIp: remoteIp,
          expiresAt: _clock().add(kLinkInviteLifetime),
        ),
      );
    while (_open.length > _max) {
      _open.removeAt(0);
    }
    return bytes;
  }

  /// Consumes the invite matching [bytes] (constant-time compare) when it
  /// is unexpired, issued for [provenFingerprint] and used from
  /// [remoteIp]. A matching invite is removed even when another check
  /// fails (single use). Returns the invite, or null.
  LinkInvite? consume(
    List<int> bytes, {
    required String provenFingerprint,
    required String remoteIp,
  }) {
    _expire();
    if (bytes.length != kLinkInviteBytes) return null;
    LinkInvite? hit;
    for (final i in _open) {
      // No early exit: every open invite is compared.
      if (constantTimeEquals(i.bytes, bytes)) hit = i;
    }
    if (hit == null) return null;
    _open.remove(hit);
    if (hit.peerFingerprint != provenFingerprint || hit.remoteIp != remoteIp) {
      return null;
    }
    return hit;
  }

  /// Stop sharing.
  void clear() => _open.clear();

  @visibleForTesting
  int get openCount {
    _expire();
    return _open.length;
  }

  void _expire() {
    final now = _clock();
    _open.removeWhere((i) => !i.expiresAt.isAfter(now));
  }
}
