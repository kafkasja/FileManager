import 'dart:async';

/// Runs only the last action given within [delay] (trailing edge).
class Debouncer {
  new(this.delay);

  final Duration delay;
  Timer? _timer;
  void Function()? _pending;

  bool get hasPending => _pending != null;

  void run(void Function() action) {
    _pending = action;
    _timer?.cancel();
    _timer = Timer(delay, flushNow);
  }

  /// Runs the pending action now (app pause, before clearing a session).
  void flushNow() {
    _timer?.cancel();
    _timer = null;
    final action = _pending;
    _pending = null;
    action?.call();
  }

  /// Drops the pending action.
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _pending = null;
  }
}
