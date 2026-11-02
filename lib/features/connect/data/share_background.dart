import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// Texts of the ongoing sharing notification (built from l10n in Dart; the
/// Android side only displays them).
@immutable
class ShareNotificationTexts {
  const new({
    required this.channel,
    required this.title,
    required this.text,
    required this.stop,
  });

  final String channel;
  final String title;
  final String text;
  final String stop;

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
      other.stop == stop;

  @override
  int get hashCode => Object.hash(channel, title, text, stop);
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
}

/// `kfm/share_service` (`ShareServiceChannel.kt`).
class AndroidShareBackground implements ShareBackground {
  new({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('kfm/share_service') {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'stopRequested') _stops.add(null);
    });
  }

  final MethodChannel _channel;
  final StreamController<void> _stops = StreamController.broadcast();
  bool _askedNotifications = false;

  @override
  bool get supported => Platform.isAndroid;

  @override
  Future<void> show(ShareNotificationTexts texts) async {
    if (!_askedNotifications) {
      _askedNotifications = true;
      // API 33+: without it the service still runs, but the notification
      // (and its Stop) only shows in the system's active-apps list.
      await ph.Permission.notification.request();
    }
    await _channel.invokeMethod<void>('show', texts.toMap());
  }

  @override
  Future<void> stop() => _channel.invokeMethod<void>('stop');

  @override
  Stream<void> get stopRequests => _stops.stream;
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
}
