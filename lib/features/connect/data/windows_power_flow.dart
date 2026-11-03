import 'dart:async';

import 'package:kfm/core/platform/windows/windows_channel.dart';

/// PL1: what KFM does when the PC sleeps or hibernates and wakes up
/// (`WM_POWERBROADCAST` through the windows channel).
///
/// - Sleep: sharing stops (the plan's rule: the server stops on sleep, like
///   on Stop sharing or Quit; connected phones see "Disconnected" instead of
///   a server that silently stopped answering), then pending DB writes are
///   flushed. Windows gives about two seconds, so nothing slow runs here.
/// - Wake: [onResume] (an incremental index scan: files may have changed
///   while asleep, a drive may have been swapped). Drives are re-read by
///   `WindowsVolumes` on the same event; N10 transfers reconnect and resume
///   by themselves. Sharing isn't restarted on its own: the user starts it
///   again (the tray icon went away with it).
class WindowsPowerFlow {
  new({
    required this._events,
    required this._isSharing,
    required this._stopSharing,
    required this._flushWrites,
    required this._onResume,
    required this._onError,
  });

  final Stream<PowerState> _events;
  final bool Function() _isSharing;
  final Future<void> Function() _stopSharing;
  final Future<void> Function() _flushWrites;
  final Future<void> Function() _onResume;

  /// A step failed (H5's error log: power events have no screen to show
  /// them on).
  final void Function(String what, Object error, StackTrace stack) _onError;

  StreamSubscription<PowerState>? _sub;

  void start() {
    _sub ??= _events.listen(
      (state) => unawaited(switch (state) {
        PowerState.suspend => onSuspend(),
        PowerState.resume => onResume(),
      }),
    );
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<void> onSuspend() async {
    if (_isSharing()) {
      await _guard('stop sharing before sleep', _stopSharing);
    }
    await _guard('flush before sleep', _flushWrites);
  }

  Future<void> onResume() => _guard('work after wake-up', _onResume);

  /// One failing step never stops the next.
  Future<void> _guard(String what, Future<void> Function() run) async {
    try {
      await run();
    } on Object catch (e, st) {
      _onError(what, e, st);
    }
  }
}
