import 'dart:async';

import 'package:kfm/features/connect/domain/connection_request.dart';
import 'package:meta/meta.dart';

/// What the share screen reacts to.
sealed class AcceptGateEvent {
  const new(this.request);

  final ConnectionRequest request;
}

/// A request waits for the accept prompt.
final class AcceptRequested extends AcceptGateEvent {
  const new(super.request);
}

/// The pending request ended (by the dialog, the timeout, the client's
/// cancel or stop sharing).
final class AcceptClosed extends AcceptGateEvent {
  const new(super.request, this.decision);

  final ConnectionDecision decision;
}

/// The single pending accept decision of the sharing device (TASK-N3).
/// Prompts are serialised: while one is open, [open] returns null (the
/// route answers `409 busy`). Memory only.
class AcceptGate {
  new({this.timeout = const Duration(seconds: 60)});

  /// The decision window (60 s); only the decision, not the pairing.
  final Duration timeout;

  ConnectionRequest? _pending;
  Completer<ConnectionDecision>? _decision;
  Timer? _timer;
  /// Async: listeners may call [decide] from their handler.
  final StreamController<AcceptGateEvent> _events =
      StreamController.broadcast();

  /// The request the dialog shows; null when none.
  ConnectionRequest? get pending => _pending;

  Stream<AcceptGateEvent> get events => _events.stream;

  /// Starts the prompt for [request]; completes with the decision.
  /// Null when another prompt is open (busy).
  Future<ConnectionDecision>? open(ConnectionRequest request) {
    if (_pending != null) return null;
    final completer = Completer<ConnectionDecision>();
    _pending = request;
    _decision = completer;
    _timer = Timer(timeout, () => _finish(ConnectionDecision.timedOut));
    _events.add(AcceptRequested(request));
    return completer.future;
  }

  /// The dialog's answer for [requestId]; false if that request is gone.
  bool decide(String requestId, ConnectionDecision decision) {
    if (_pending?.requestId != requestId) return false;
    _finish(decision);
    return true;
  }

  /// `POST /v1/pair/cancel`: only the same attempt id from the same IP.
  bool cancel(String pairAttemptId, String remoteIp) {
    final p = _pending;
    if (p == null ||
        p.pairAttemptId != pairAttemptId ||
        p.remoteIp != remoteIp) {
      return false;
    }
    _finish(ConnectionDecision.cancelled);
    return true;
  }

  /// Stop sharing: the pending request (if any) ends as `cancelled`.
  void cancelAll() {
    if (_pending != null) _finish(ConnectionDecision.cancelled);
  }

  @visibleForTesting
  bool get hasTimer => _timer?.isActive ?? false;

  void _finish(ConnectionDecision decision) {
    final request = _pending;
    final completer = _decision;
    if (request == null || completer == null) return;
    _timer?.cancel();
    _timer = null;
    _pending = null;
    _decision = null;
    completer.complete(decision);
    _events.add(AcceptClosed(request, decision));
  }
}
