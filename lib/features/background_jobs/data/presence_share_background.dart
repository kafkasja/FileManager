import 'package:kfm/features/background_jobs/data/background_presence.dart';
import 'package:kfm/features/connect/data/share_background.dart';

/// N5b/PL1 sharing through [BackgroundPresence] (TASK-X8): sharing and
/// jobs share one service / tray. Offers keep their own notification.
class PresenceShareBackground implements ShareBackground {
  new(
    this._presence, {
    required this._showOffer,
    required this._cancelOffer,
    required this._notificationsAllowed,
  });

  final BackgroundPresence _presence;
  final Future<void> Function(OfferNotificationTexts texts) _showOffer;
  final Future<void> Function() _cancelOffer;
  final Future<bool> Function() _notificationsAllowed;

  @override
  bool get supported => true;

  @override
  Future<void> show(ShareNotificationTexts texts) =>
      _presence.setSharing(texts);

  @override
  Future<void> stop() => _presence.setSharing(null);

  @override
  Stream<void> get stopRequests => _presence.stopSharingRequests;

  @override
  Future<void> showOffer(OfferNotificationTexts texts) => _showOffer(texts);

  @override
  Future<void> cancelOffer() => _cancelOffer();

  @override
  Future<bool> notificationsAllowed() => _notificationsAllowed();
}
