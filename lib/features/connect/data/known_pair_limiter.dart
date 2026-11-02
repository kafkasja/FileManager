/// Failed `/v1/pair/known` calls allowed per remote IP within the window.
const int kKnownPairMaxFailures = 5;

/// The limiter's sliding window.
const Duration kKnownPairWindow = Duration(minutes: 1);

/// Counts failed `/v1/pair/known` calls per remote IP (TASK-N6): after
/// [maxFailures] failures within [window] the IP gets `429
/// too_many_attempts`. Separate from N2's QR/code counters, so a broken or
/// removed device retrying never rotates the QR. Memory only; cleared when
/// sharing stops.
class KnownPairLimiter {
  new({
    DateTime Function()? clock,
    this.maxFailures = kKnownPairMaxFailures,
    this.window = kKnownPairWindow,
  }) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final int maxFailures;
  final Duration window;

  /// Failure times per IP, oldest first.
  final Map<String, List<DateTime>> _failures = {};

  /// Max IPs tracked (the route is unauthenticated); the oldest is dropped.
  static const int _maxIps = 256;

  /// True when [remoteIp] has used up its failures in the window.
  bool isLocked(String remoteIp) => _recent(remoteIp).length >= maxFailures;

  void recordFailure(String remoteIp) {
    final list = _recent(remoteIp)..add(_clock());
    _failures.remove(remoteIp);
    _failures[remoteIp] = list;
    while (_failures.length > _maxIps) {
      _failures.remove(_failures.keys.first);
    }
  }

  /// Stop sharing.
  void clear() => _failures.clear();

  List<DateTime> _recent(String ip) {
    final list = _failures[ip];
    if (list == null) return [];
    final from = _clock().subtract(window);
    list.removeWhere((t) => !t.isAfter(from));
    return list;
  }
}
