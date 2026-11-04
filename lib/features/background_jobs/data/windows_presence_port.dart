import 'dart:async';
import 'dart:developer' as developer;

import 'package:kfm/core/platform/windows/desktop_shell.dart';
import 'package:kfm/core/platform/windows/windows_channel.dart';
import 'package:kfm/features/background_jobs/data/background_presence.dart';
import 'package:kfm/features/background_jobs/domain/job_notice.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// Windows tooltips are cut at 127 characters.
const int kTrayTooltipMax = 127;

/// TASK-X8 on Windows: the tray icon (sharing and/or jobs; tooltip shows
/// the progress, the menu has the job buttons) and the taskbar button's
/// progress (`ITaskbarList3` through the windows channel). Open and Quit in
/// the tray menu stay `WindowsCloseFlow`'s. End notices only clear the
/// taskbar (a Windows toast is optional and skipped).
class WindowsPresencePort implements PresencePort {
  new({required this._shell, required this._taskbar, required this._l10n});

  final DesktopShell _shell;
  final Future<void> Function(TaskbarProgress state, int value) _taskbar;
  final AppLocalizations Function() _l10n;

  bool _jobsShown = false;
  bool _pausedShown = false;

  static final Set<String> _keys = {
    trayStopSharingKey,
    for (final a in NoticeAction.values) a.name,
  };

  @override
  Stream<String> get actions => _shell.trayClicks.where(_keys.contains);

  /// "Title\nText", cut to what Windows shows.
  static String tooltip(String title, String text) {
    final full = text.isEmpty ? title : '$title\n$text';
    return full.length <= kTrayTooltipMax
        ? full
        : '${full.substring(0, kTrayTooltipMax - 1)}…';
  }

  @override
  Future<void> showOngoing(OngoingPresence p) async {
    final l = _l10n();
    await _shell.showTray(
      tooltip: tooltip(p.title, p.jobs ? p.text : ''),
      menu: [
        for (final (key, label) in p.actions) TrayMenuEntry(key, label),
        TrayMenuEntry(trayOpenKey, l.shareNotificationOpen),
        TrayMenuEntry(trayQuitKey, l.shareNotificationQuit),
      ],
    );
    _jobsShown = p.jobs;
    await _setTaskbar(
      p.jobs ? TaskbarProgress.normal : TaskbarProgress.none,
      p.percent ?? 0,
    );
  }

  @override
  Future<void> stopOngoing() async {
    _jobsShown = false;
    await _shell.removeTray();
    if (!_pausedShown) await _setTaskbar(TaskbarProgress.none, 0);
  }

  @override
  Future<void> showNotice(NoticeSlot slot, NoticePresence n) async {
    switch (slot) {
      case NoticeSlot.paused:
        _pausedShown = true;
        await _setTaskbar(TaskbarProgress.paused, n.percent ?? 0);
      case NoticeSlot.ended:
        if (!_jobsShown && !_pausedShown) {
          await _setTaskbar(TaskbarProgress.none, 0);
        }
    }
  }

  @override
  Future<void> cancelNotice(NoticeSlot slot) async {
    if (slot != NoticeSlot.paused || !_pausedShown) return;
    _pausedShown = false;
    if (!_jobsShown) await _setTaskbar(TaskbarProgress.none, 0);
  }

  /// The tray needs no permission.
  @override
  Future<void> askNotificationsOnce() async {}

  Future<void> _setTaskbar(TaskbarProgress state, int value) async {
    try {
      await _taskbar(state, value);
    } on Object catch (e) {
      // Cosmetic: the tray and the in-app indicator still show progress.
      developer.log('taskbar progress failed: $e', name: 'kfm.jobs');
    }
  }
}

/// Tests and platforms without a keep-alive.
class NoPresencePort implements PresencePort {
  const new();

  @override
  Stream<String> get actions => const Stream.empty();

  @override
  Future<void> askNotificationsOnce() async {}

  @override
  Future<void> cancelNotice(NoticeSlot slot) async {}

  @override
  Future<void> showNotice(NoticeSlot slot, NoticePresence n) async {}

  @override
  Future<void> showOngoing(OngoingPresence p) async {}

  @override
  Future<void> stopOngoing() async {}
}
