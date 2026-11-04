import 'dart:async';

import 'package:kfm/core/platform/windows/desktop_shell.dart';
import 'package:meta/meta.dart';

/// Texts of the ongoing sharing notification (built from l10n in Dart; the
/// Android side only displays them).
@immutable
class ShareNotificationTexts {
  const new({
    required this.channel,
    required this.title,
    required this.text,
    required this.stop,
    this.open = '',
    this.quit = '',
  });

  final String channel;
  final String title;
  final String text;
  final String stop;

  /// PL1 tray menu only (not sent to Android): "Open KFM", "Quit".
  final String open;
  final String quit;

  Map<String, String> toMap() => {
    'channel': channel,
    'title': title,
    'text': text,
    'stop': stop,
  };

  @override
  bool operator ==(Object other) =>
      other is ShareNotificationTexts &&
      other.channel == channel &&
      other.title == title &&
      other.text == text &&
      other.stop == stop &&
      other.open == open &&
      other.quit == quit;

  @override
  int get hashCode => Object.hash(channel, title, text, stop, open, quit);
}

/// Texts of the N12 "Incoming files" notification.
@immutable
class OfferNotificationTexts {
  const new({required this.channel, required this.title, required this.text});

  final String channel;
  final String title;
  final String text;

  Map<String, String> toMap() => {
    'channel': channel,
    'title': title,
    'text': text,
  };
}

/// Keeps sharing alive while KFM is in the background (TASK-N5b): an
/// Android foreground service with an ongoing "Sharing with … · Stop"
/// notification. Other platforms don't support it ([supported] false).
abstract interface class ShareBackground {
  bool get supported;

  /// Starts the service, or updates its notification while it runs.
  /// Throws when the system refuses to start it.
  Future<void> show(ShareNotificationTexts texts);

  /// Ends the service and removes the notification. Safe when not running.
  Future<void> stop();

  /// The notification's Stop was tapped, or KFM was swiped away.
  Stream<void> get stopRequests;

  /// N12: "<S> wants to send you files" (high importance; a tap opens
  /// KFM, where the offer dialog shows).
  Future<void> showOffer(OfferNotificationTexts texts);

  /// N12: removes that notification.
  Future<void> cancelOffer();

  /// Whether the sharing notification (and its Stop) is visible: false on
  /// Android 13+ when notifications are denied (Q8: the share screen then
  /// doesn't promise one).
  Future<bool> notificationsAllowed();
}

/// Desktop, iOS and tests.
class NoShareBackground implements ShareBackground {
  const new();

  @override
  bool get supported => false;

  @override
  Future<void> show(ShareNotificationTexts texts) async {}

  @override
  Future<void> stop() async {}

  @override
  Stream<void> get stopRequests => const Stream.empty();

  @override
  Future<void> showOffer(OfferNotificationTexts texts) async {}

  @override
  Future<void> cancelOffer() async {}

  @override
  Future<bool> notificationsAllowed() async => true;
}

/// PL1: on Windows sharing keeps running while the window is hidden, behind
/// a tray icon (tooltip = who is connected; menu Stop sharing / Open KFM /
/// Quit). Open and Quit are the close flow's (`WindowsCloseFlow`); Stop
/// comes back here as [stopRequests]. An incoming offer (N12) brings the
/// window to the front: offers are never answered from the tray.
class TrayShareBackground implements ShareBackground {
  new(this._shell);

  final DesktopShell _shell;

  @override
  bool get supported => true;

  @override
  Future<void> show(ShareNotificationTexts texts) => _shell.showTray(
    tooltip: texts.title,
    menu: [
      TrayMenuEntry(trayStopSharingKey, texts.stop),
      TrayMenuEntry(trayOpenKey, texts.open),
      TrayMenuEntry(trayQuitKey, texts.quit),
    ],
  );

  @override
  Future<void> stop() => _shell.removeTray();

  @override
  Stream<void> get stopRequests =>
      _shell.trayClicks.where((k) => k == trayStopSharingKey);

  @override
  Future<void> showOffer(OfferNotificationTexts texts) => _shell.showAndFocus();

  @override
  Future<void> cancelOffer() async {}

  /// The tray icon needs no permission.
  @override
  Future<bool> notificationsAllowed() async => true;
}
