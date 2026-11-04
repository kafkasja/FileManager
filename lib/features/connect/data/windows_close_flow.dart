import 'dart:async';
import 'dart:developer' as developer;

import 'package:kfm/core/platform/windows/desktop_shell.dart';

/// What closing the window does on Windows (TASK-PL1, user decision Q23),
/// UI-agnostic:
/// - not sharing → quit;
/// - sharing and "Stop sharing when the window closes" on → stop, then quit;
/// - sharing (default) → hide; the tray icon stays (the first time after
///   [firstHideNotice], once);
/// - X8: transfers or copies running → hide to the tray too (they go on;
///   "Stop sharing when the window closes" doesn't end them).
///
/// Tray Open → window back; tray Quit → (X8: while jobs run, the window
/// comes back and [confirmQuit] asks first) stop sharing, then quit. A
/// connection request (N3 accept prompt) brings the
/// window to the front; it's never answered from the tray.
class WindowsCloseFlow {
  new({
    required this._shell,
    required this._isSharing,
    required this._stopSharing,
    required this._stopOnClose,
    required this._noticeShown,
    required this._markNoticeShown,
    required this._attentionRequests,
    required this._beforeQuit,
    int Function()? runningJobs,
  }) : _runningJobs = runningJobs ?? _none;

  static int _none() => 0;

  /// X8: transfers / local jobs / incoming uploads running right now.
  final int Function() _runningJobs;

  final DesktopShell _shell;
  final bool Function() _isSharing;
  final Future<void> Function() _stopSharing;
  final Future<bool> Function() _stopOnClose;
  final Future<bool> Function() _noticeShown;
  final Future<void> Function() _markNoticeShown;
  final Stream<void> _attentionRequests;

  /// Lands queued DB writes before the process ends.
  final Future<void> Function() _beforeQuit;

  /// Set by the UI (`WindowsCloseHost`): shows "KFM is still sharing this
  /// PC. Stop it from the tray icon." and completes when dismissed.
  Future<void> Function()? firstHideNotice;

  /// X8: set by the UI: shows "Quit KFM? N transfers are still running"
  /// (with the window in front); true = quit.
  Future<bool> Function(int running)? confirmQuit;

  /// X8: set by the UI: the one-time notice when the window first hides
  /// because jobs run (not sharing).
  Future<void> Function()? firstHideNoticeForJobs;

  final List<StreamSubscription<Object?>> _subs = [];
  bool _closing = false;

  void start() {
    if (_subs.isNotEmpty) return;
    _subs.addAll([
      _shell.closeRequests.listen((_) => unawaited(onCloseRequested())),
      _shell.trayClicks.listen((key) {
        switch (key) {
          case trayOpenKey:
            unawaited(_shell.showAndFocus());
          case trayQuitKey:
            unawaited(quit());
        }
      }),
      _attentionRequests.listen((_) => unawaited(_shell.showAndFocus())),
    ]);
  }

  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
  }

  /// The window's ✕.
  Future<void> onCloseRequested() async {
    if (_closing) return;
    _closing = true;
    try {
      final jobs = _runningJobs() > 0;
      if (!_isSharing() && !jobs) return await _quitNow();
      if (!jobs && await _stopOnClose()) return await quit();
      if (!await _noticeShown()) {
        final forJobs = jobs && !_isSharing();
        await (forJobs ? firstHideNoticeForJobs : firstHideNotice)?.call();
        await _markNoticeShown();
        // Sharing (and the jobs) may have ended while the notice was open.
        if (!_isSharing() && _runningJobs() == 0) return await _quitNow();
      }
      await _shell.hide();
    } finally {
      _closing = false;
    }
  }

  /// Stops sharing (tokens die, devices see "Disconnected"), then quits.
  Future<void> quit() async {
    final running = _runningJobs();
    final ask = confirmQuit;
    if (running > 0 && ask != null) {
      await _shell.showAndFocus();
      if (!await ask(running)) return;
    }
    try {
      await _stopSharing();
    } on Object catch (e) {
      // Quitting anyway: the server dies with the process.
      developer.log('stop sharing on quit failed: $e', name: 'kfm.connect');
    }
    await _quitNow();
  }

  /// The window goes first (closing looks instant), then queued writes
  /// land, then the process ends (the runner skips the engine teardown).
  Future<void> _quitNow() async {
    try {
      await _shell.hide();
    } on Object catch (e) {
      developer.log('hide on quit failed: $e', name: 'kfm.connect');
    }
    try {
      await _beforeQuit();
    } finally {
      await _shell.quit();
    }
  }
}
