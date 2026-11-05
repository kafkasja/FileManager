import 'dart:async';

import 'package:kfm/core/utils/random_id.dart';
import 'package:kfm/features/connect/domain/link.dart';
import 'package:meta/meta.dart';

/// How long the owner has to answer a shown take prompt; the request is
/// held that long (queued ones wait for their turn first).
const Duration kTakeDecisionTimeout = Duration(seconds: 100);

/// How long a client waits for `POST /v1/take` (its prompt may queue
/// behind [kMaxTakeQueuedPerPeer] others).
const Duration kTakeClientTimeout = Duration(minutes: 6);

/// Max ids in one `POST /v1/take` (one prompt per job).
const int kMaxTakeIds = 500;

/// Max waiting prompts per peer (prompt storms).
const int kMaxTakeQueuedPerPeer = 3;

/// What a take prompt lists for one file (name, size, type).
@immutable
class TakeFile {
  const new({required this.name, required this.sizeBytes, this.mimeType});

  final String name;
  final int sizeBytes;
  final String? mimeType;
}

/// "`peer` wants to take N files": one per `POST /v1/take`.
@immutable
class TakeRequest {
  const new({
    required this.id,
    required this.peerFingerprint,
    required this.peerName,
    required this.files,
    required this.move,
    required this.receivedAt,
  });

  final String id;
  final String peerFingerprint;
  final String peerName;
  final List<TakeFile> files;

  /// N11 download-move: the originals here go to the trash afterwards.
  final bool move;
  final DateTime receivedAt;

  int get totalBytes => files.fold(0, (a, f) => a + f.sizeBytes);
}

enum TakeDecision { allowed, declined, timedOut, busy }

sealed class TakeGateEvent {
  const new(this.request);

  final TakeRequest request;
}

/// The prompt for [request] should show now (one at a time).
final class TakeRequested extends TakeGateEvent {
  const new(super.request);
}

/// [request] ended (answer, timeout, the peer left, stop sharing).
final class TakeClosed extends TakeGateEvent {
  const new(super.request, this.decision);

  final TakeDecision decision;
}

class _Pending {
  new(this.request, this.ids);

  final TakeRequest request;
  final List<String> ids;

  /// Runs while the prompt is shown (queued prompts wait without one).
  Timer? timer;
  final Completer<TakeDecision> done = Completer();
}

/// TASK-E1 take prompt, owner side: while "Let `peer` take files without
/// asking" is off for a linked peer, its content, sha256 and video
/// requests need a grant per file id. `POST /v1/take` asks once per job;
/// Allow grants the ids (with `move` for an N11 download-move) until the
/// link is closed or sharing stops, so a resumed transfer doesn't ask
/// again. Memory only.
class TakeGate {
  new({
    required this._perms,
    this.timeout = kTakeDecisionTimeout,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// This device's own choice for a peer (null: not a link peer).
  final LinkPerms? Function(String fingerprint) _perms;
  final Duration timeout;
  final DateTime Function() _clock;

  /// fp → id → move allowed too.
  final Map<String, Map<String, bool>> _grants = {};
  final List<_Pending> _queue = [];
  final StreamController<TakeGateEvent> _events = StreamController.broadcast();

  Stream<TakeGateEvent> get events => _events.stream;

  /// The prompt to show now; null when none.
  TakeRequest? get current => _queue.firstOrNull?.request;

  /// True when [fingerprint]'s content requests need a grant.
  bool needsApproval(String fingerprint) =>
      _perms(fingerprint)?.takeFreely == false;

  /// Whether [fingerprint] may read [id]'s bytes ([move]: and trash it as
  /// the source of a verified move).
  bool allows(String fingerprint, String id, {bool move = false}) {
    if (!needsApproval(fingerprint)) return true;
    final g = _grants[fingerprint]?[id];
    return g != null && (!move || g);
  }

  /// Asks the owner for [ids] (≤ [kMaxTakeIds]); completes with the
  /// answer. Already granted ids don't ask again.
  Future<TakeDecision> request({
    required String peerFingerprint,
    required String peerName,
    required List<String> ids,
    required List<TakeFile> files,
    required bool move,
  }) {
    if (ids.every((id) => allows(peerFingerprint, id, move: move))) {
      return Future.value(TakeDecision.allowed);
    }
    final queued = _queue
        .where((p) => p.request.peerFingerprint == peerFingerprint)
        .length;
    if (queued >= kMaxTakeQueuedPerPeer) {
      return Future.value(TakeDecision.busy);
    }
    final request = TakeRequest(
      id: randomHexId(),
      peerFingerprint: peerFingerprint,
      peerName: peerName,
      files: List.unmodifiable(files),
      move: move,
      receivedAt: _clock(),
    );
    final p = _Pending(request, List.unmodifiable(ids));
    _queue.add(p);
    if (_queue.length == 1) _show(p);
    return p.done.future;
  }

  /// The prompt's answer. With "Always allow" the caller also turns
  /// "take without asking" on for that peer (its perms live elsewhere).
  bool decide(String requestId, {required bool allow}) {
    final p = _queue.where((p) => p.request.id == requestId).firstOrNull;
    if (p == null) return false;
    if (allow) {
      final g = _grants[p.request.peerFingerprint] ??= {};
      for (final id in p.ids) {
        g[id] = (g[id] ?? false) || p.request.move;
      }
    }
    _finish(p, allow ? TakeDecision.allowed : TakeDecision.declined);
    return true;
  }

  /// The link to [fingerprint] closed: its grants and prompts end.
  void clearPeer(String fingerprint) {
    _grants.remove(fingerprint);
    for (final p in [..._queue]) {
      if (p.request.peerFingerprint == fingerprint) {
        _finish(p, TakeDecision.declined);
      }
    }
  }

  /// Stop sharing.
  void clear() {
    _grants.clear();
    for (final p in [..._queue]) {
      _finish(p, TakeDecision.declined);
    }
  }

  @visibleForTesting
  int get queued => _queue.length;

  /// [p] is shown now: its answer window starts.
  void _show(_Pending p) {
    p.timer = Timer(timeout, () => _finish(p, TakeDecision.timedOut));
    _events.add(TakeRequested(p.request));
  }

  void _finish(_Pending p, TakeDecision decision) {
    final wasHead = _queue.firstOrNull == p;
    if (!_queue.remove(p)) return;
    p.timer?.cancel();
    if (!p.done.isCompleted) p.done.complete(decision);
    _events.add(TakeClosed(p.request, decision));
    if (wasHead && _queue.isNotEmpty) _show(_queue.first);
  }
}
