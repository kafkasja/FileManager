import 'dart:async';

import 'package:flutter/services.dart';
import 'package:kfm/features/background_jobs/data/background_presence.dart';
import 'package:kfm/features/connect/data/share_background.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

Map<String, Object?> _channelMap(PresenceChannelTexts c) => {
  'channelId': switch (c.channel) {
    PresenceChannel.sharing => 'sharing',
    PresenceChannel.progress => 'transfers',
    PresenceChannel.results => 'transfer_results',
  },
  'channelName': c.name,
  'channelDescription': c.description,
};

List<Map<String, String>> _actionList(List<(String, String)> actions) => [
  for (final (key, label) in actions) {'key': key, 'label': label},
];

/// `kfm/share_service` (`ShareServiceChannel.kt`, TASK-N5b + X8): one
/// foreground service (`connectedDevice` while sharing, `dataSync` while
/// jobs run) with one ongoing notification, plus the dismissible paused /
/// end notices and the N12 offer heads-up. Every text arrives from Dart.
class AndroidPresencePort implements PresencePort {
  new({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('kfm/share_service') {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'stopRequested':
          _actions.add('stopSharing');
        case 'action':
          if (call.arguments case final String key) _actions.add(key);
      }
    });
    // A tap on a notification that started KFM (no Dart listener then).
    unawaited(
      _channel
          .invokeMethod<bool>('takeOpen')
          .then((open) {
            if (open ?? false) _actions.add(PresenceKeys.open);
          })
          .catchError((Object _) {}),
    );
  }

  final MethodChannel _channel;
  final StreamController<String> _actions = StreamController.broadcast();
  bool _asked = false;

  @override
  Stream<String> get actions => _actions.stream;

  @override
  Future<void> showOngoing(OngoingPresence p) =>
      _channel.invokeMethod<void>('presence', {
        ..._channelMap(p.channel),
        'sharing': p.sharing,
        'jobs': p.jobs,
        'title': p.title,
        'text': p.text,
        'percent': p.percent ?? -1,
        'actions': _actionList(p.actions),
      });

  @override
  Future<void> stopOngoing() => _channel.invokeMethod<void>('stop');

  @override
  Future<void> showNotice(NoticeSlot slot, NoticePresence n) =>
      _channel.invokeMethod<void>('notice', {
        ..._channelMap(n.channel),
        'slot': slot.name,
        'title': n.title,
        'text': n.text,
        'percent': n.percent ?? -1,
        'actions': _actionList(n.actions),
      });

  @override
  Future<void> cancelNotice(NoticeSlot slot) =>
      _channel.invokeMethod<void>('cancelNotice', {'slot': slot.name});

  @override
  Future<void> askNotificationsOnce() async {
    if (_asked) return;
    _asked = true;
    try {
      // API 33+: without it jobs still run; only the notification is
      // missing (the Transfers screen says so).
      await ph.Permission.notification.request();
    } on Object {
      // A request already showing, or no activity: asked next start.
      _asked = false;
    }
  }

  /// N12: "<S> wants to send you files" (high importance).
  Future<void> showOffer(OfferNotificationTexts texts) =>
      _channel.invokeMethod<void>('showOffer', texts.toMap());

  Future<void> cancelOffer() => _channel.invokeMethod<void>('cancelOffer');

  /// False on Android 13+ when notifications are denied.
  Future<bool> notificationsAllowed() async {
    try {
      return await ph.Permission.notification.isGranted;
    } on Object {
      return true;
    }
  }
}
