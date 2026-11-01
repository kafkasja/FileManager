import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart' as crypto;
import 'package:kfm/core/utils/random_id.dart';
import 'package:kfm/features/connect/data/crypto/identity_proof.dart';
import 'package:kfm/features/connect/domain/connection_request.dart';
import 'package:meta/meta.dart';

/// A session without a request for this long is removed (N5's heartbeat
/// keeps live clients active).
const Duration kSessionIdleTimeout = Duration(minutes: 10);

/// What [ClientSessionStore.issue] returns: the raw token goes to the
/// client once and is never stored.
typedef IssuedSession = ({String token, ClientSession session});

/// Bearer-token sessions of the current sharing run (TASK-N3). Memory only:
/// [clear] (stop sharing) ends them all, so an old token always gets 401.
/// Keyed by `sha256(token)`, so a lookup never compares raw tokens.
class ClientSessionStore {
  new({DateTime Function()? clock, Random? random})
    : _clock = clock ?? DateTime.now,
      _random = random ?? Random.secure();

  final DateTime Function() _clock;
  final Random _random;

  /// By token hash.
  final Map<String, ClientSession> _byHash = {};

  /// In-flight content/upload streams per session id (N7/N10 register).
  final Map<String, List<TrackedStream>> _streams = {};
  final StreamController<List<ClientSession>> _changes =
      StreamController.broadcast();
  Timer? _sweep;

  DateTime now() => _clock();

  /// Live sessions, oldest first.
  List<ClientSession> get sessions {
    _expireIdle();
    return _sorted();
  }

  /// Emits the session list after every add/remove.
  Stream<List<ClientSession>> get changes => _changes.stream;

  /// A new session for an accepted client. A session of the same
  /// [clientFingerprint] is replaced (its streams are cancelled).
  IssuedSession issue({
    required String clientFingerprint,
    required String clientDeviceId,
    required String clientName,
  }) {
    _removeWhere(
      (s) => s.clientFingerprint == clientFingerprint,
      notify: false,
    );
    final token = b64url(List<int>.generate(32, (_) => _random.nextInt(256)));
    final at = _clock();
    final session = ClientSession(
      sessionId: randomHexId(_random),
      clientFingerprint: clientFingerprint,
      clientDeviceId: clientDeviceId,
      clientName: clientName,
      tokenHash: hashToken(token),
      createdAt: at,
      lastUsedAt: at,
    );
    _byHash[session.tokenHash] = session;
    _sweep ??= Timer.periodic(const Duration(minutes: 1), (_) => _expireIdle());
    _emit();
    return (token: token, session: session);
  }

  /// The session for [token], touched; null when unknown, revoked or idle
  /// for [kSessionIdleTimeout].
  ClientSession? verify(String token) {
    final hash = hashToken(token);
    final s = _byHash[hash];
    if (s == null) return null;
    final at = _clock();
    if (at.difference(s.lastUsedAt) >= kSessionIdleTimeout) {
      _remove(hash);
      _emit();
      return null;
    }
    return _byHash[hash] = s.touched(at);
  }

  /// Ends one session (share-screen "Disconnect"); cancels its streams.
  bool revoke(String sessionId) =>
      _removeWhere((s) => s.sessionId == sessionId);

  /// Ends the session of a device (N6 removes a remembered device).
  bool revokeByFingerprint(String fingerprint) =>
      _removeWhere((s) => s.clientFingerprint == fingerprint);

  /// Stop sharing: every session and stream ends.
  void clear() {
    final had = _byHash.isNotEmpty;
    _byHash.keys.toList().forEach(_remove);
    _stopSweep();
    if (had) _emit();
  }

  /// Tracks an in-flight stream of [sessionId] so revoking cancels it.
  /// [canonicalPath] is for N4's scope check. Returns an unregister
  /// callback (call it when the stream ends). If the session is already
  /// gone, the stream is cancelled at once.
  void Function() registerStream(
    String sessionId,
    StreamSubscription<Object?> subscription, {
    String? canonicalPath,
    bool write = false,
  }) {
    final tracked = TrackedStream(subscription, canonicalPath, write: write);
    if (!_byHash.values.any((s) => s.sessionId == sessionId)) {
      unawaited(subscription.cancel());
      return () {};
    }
    (_streams[sessionId] ??= []).add(tracked);
    return () => _streams[sessionId]?.remove(tracked);
  }

  /// Streams currently tracked for [sessionId] (N4 cancels by path).
  List<TrackedStream> streamsOf(String sessionId) =>
      List.unmodifiable(_streams[sessionId] ?? const <TrackedStream>[]);

  /// Cancels the tracked streams of [clientFingerprint]'s sessions whose
  /// path fails [keep] (N4: a scope edit ends streams outside the new
  /// scope). Streams without a path are kept. Returns how many ended.
  int cancelStreamsWhere(
    String clientFingerprint,
    bool Function(String canonicalPath, {required bool write}) keep,
  ) {
    var n = 0;
    for (final s in _byHash.values) {
      if (s.clientFingerprint != clientFingerprint) continue;
      final list = _streams[s.sessionId];
      if (list == null) continue;
      final drop = [
        for (final t in list)
          if (t.canonicalPath case final path? when !keep(path, write: t.write))
            t,
      ];
      for (final t in drop) {
        list.remove(t);
        unawaited(t.subscription.cancel());
      }
      n += drop.length;
    }
    return n;
  }

  @visibleForTesting
  static String hashToken(String token) =>
      crypto.sha256.convert(utf8.encode(token)).toString();

  void _expireIdle() {
    final at = _clock();
    final stale = [
      for (final e in _byHash.entries)
        if (at.difference(e.value.lastUsedAt) >= kSessionIdleTimeout) e.key,
    ]..forEach(_remove);
    if (stale.isNotEmpty) _emit();
  }

  bool _removeWhere(bool Function(ClientSession s) test, {bool notify = true}) {
    final hits = [
      for (final e in _byHash.entries)
        if (test(e.value)) e.key,
    ]..forEach(_remove);
    if (hits.isNotEmpty && notify) _emit();
    return hits.isNotEmpty;
  }

  void _remove(String hash) {
    final s = _byHash.remove(hash);
    if (s == null) return;
    for (final t in _streams.remove(s.sessionId) ?? const <TrackedStream>[]) {
      unawaited(t.subscription.cancel());
    }
  }

  void _emit() {
    if (_byHash.isEmpty) _stopSweep();
    _changes.add(_sorted());
  }

  void _stopSweep() {
    _sweep?.cancel();
    _sweep = null;
  }

  List<ClientSession> _sorted() =>
      _byHash.values.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
}

/// One registered in-flight stream.
@immutable
class TrackedStream {
  const new(this.subscription, this.canonicalPath, {this.write = false});

  final StreamSubscription<Object?> subscription;
  final String? canonicalPath;

  /// An upload or other write: ends when its root turns read-only.
  final bool write;
}
