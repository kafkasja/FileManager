import 'dart:async';

/// A mutex for async code: [run] calls execute one at a time, in order.
/// Undo (S2) and delete commits (D2) share one so they never interleave.
class SerialLock {
  Future<void> _tail = Future<void>.value();

  Future<T> run<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    // The next caller waits for this one whether it succeeded or failed.
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }
}
