/// Offers one client may make within [kOfferWindow].
const int kOffersPerWindow = 5;

/// The limiter's sliding window.
const Duration kOfferWindow = Duration(minutes: 1);

/// Declines in a row after which a client must wait [kOfferCooldown].
const int kOfferDeclineStreak = 3;
const Duration kOfferCooldown = Duration(minutes: 10);

/// Offers waiting for a prompt across all clients (more → 409 `busy`).
const int kMaxQueuedOfferPrompts = 3;

/// Send-files spam limits per client fingerprint (TASK-N12): at most
/// [kOffersPerWindow] new offers per [kOfferWindow], and after
/// [kOfferDeclineStreak] declines in a row a [kOfferCooldown] (→ 429).
/// One pending offer per client and the global prompt cap are checked by
/// the service (they need its state). Memory only.
class OfferLimiter {
  new({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final Map<String, List<DateTime>> _made = {};
  final Map<String, int> _declines = {};
  final Map<String, DateTime> _cooldownUntil = {};

  /// Max fingerprints tracked; the oldest is dropped.
  static const int _maxKeys = 256;

  /// True when [fp] may not make an offer right now.
  bool isLimited(String fp) {
    final until = _cooldownUntil[fp];
    if (until != null) {
      if (_clock().isBefore(until)) return true;
      _cooldownUntil.remove(fp);
      _declines.remove(fp);
    }
    return _recent(fp).length >= kOffersPerWindow;
  }

  void recordOffer(String fp) {
    final list = _recent(fp)..add(_clock());
    _made.remove(fp);
    _made[fp] = list;
    while (_made.length > _maxKeys) {
      _made.remove(_made.keys.first);
    }
  }

  /// The receiver declined (by hand) an offer of [fp].
  void recordDecline(String fp) {
    final n = (_declines[fp] ?? 0) + 1;
    _declines[fp] = n;
    if (n >= kOfferDeclineStreak) {
      _cooldownUntil[fp] = _clock().add(kOfferCooldown);
    }
    while (_declines.length > _maxKeys) {
      _declines.remove(_declines.keys.first);
    }
  }

  /// An accept ends the decline streak.
  void recordAccept(String fp) => _declines.remove(fp);

  void clear() {
    _made.clear();
    _declines.clear();
    _cooldownUntil.clear();
  }

  List<DateTime> _recent(String fp) {
    final list = _made[fp];
    if (list == null) return [];
    final from = _clock().subtract(kOfferWindow);
    list.removeWhere((t) => !t.isAfter(from));
    return list;
  }
}
