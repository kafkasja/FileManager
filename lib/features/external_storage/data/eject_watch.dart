import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:kfm/features/external_storage/data/volume_activity_tracker.dart';
import 'package:kfm/features/external_storage/domain/storage_place.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'eject_watch.g.dart';

/// U3: back in KFM while the place being ejected is still mounted.
@immutable
class EjectNotYet {
  const new(this.place);

  final StoragePlace place;
}

/// Watches the hand-off to the system's Eject (TASK-U3): back in the app
/// with the place still mounted → [EjectNotYet]; after [timeout] spent in
/// the foreground the eject is cancelled and the place is usable again.
/// The timer runs only while the app is in the foreground, in memory.
class EjectWatch {
  new({
    required this._cancelEject,
    this.timeout = const Duration(seconds: 30),
    this.notYetDelay = const Duration(milliseconds: 1500),
  });

  final void Function(String placeId) _cancelEject;
  final Duration timeout;

  /// Unmount events may land just after the app is back: wait this long
  /// before saying "not ejected yet".
  final Duration notYetDelay;
  Timer? _notYet;

  final _notices = StreamController<EjectNotYet>.broadcast();
  StoragePlace? _place;
  Timer? _timer;
  Duration _left = Duration.zero;
  DateTime? _runningSince;
  bool _inBackground = false;

  Stream<EjectNotYet> get notices => _notices.stream;

  /// The place whose eject is being waited for, if any.
  String? get waitingFor => _place?.id;

  /// Settings are about to open for [place].
  void start(StoragePlace place) {
    _stopTimer();
    _place = place;
    _left = timeout;
    if (!_inBackground) _runTimer();
  }

  /// The app went to the background (the settings screen opened).
  void onBackground() {
    _inBackground = true;
    _notYet?.cancel();
    _notYet = null;
    _pauseTimer();
  }

  /// Back in the app: still mounted (no unmount event yet) → not yet.
  void onForeground() {
    _inBackground = false;
    final place = _place;
    if (place == null) return;
    _notYet?.cancel();
    _notYet = Timer(notYetDelay, () {
      _notYet = null;
      if (_place == place && !_notices.isClosed) {
        _notices.add(EjectNotYet(place));
      }
    });
    _runTimer();
  }

  /// The place went away (or the eject was cancelled).
  void stop(String placeId) {
    if (_place?.id != placeId) return;
    _stopTimer();
    _place = null;
  }

  void dispose() {
    _stopTimer();
    unawaited(_notices.close());
  }

  void _runTimer() {
    if (_timer != null || _place == null) return;
    _runningSince = DateTime.now();
    _timer = Timer(_left, _expired);
  }

  void _pauseTimer() {
    final since = _runningSince;
    if (_timer == null || since == null) return;
    _timer!.cancel();
    _timer = null;
    _left -= DateTime.now().difference(since);
    if (_left < Duration.zero) _left = Duration.zero;
    _runningSince = null;
  }

  void _stopTimer() {
    _notYet?.cancel();
    _notYet = null;
    _timer?.cancel();
    _timer = null;
    _runningSince = null;
  }

  void _expired() {
    _timer = null;
    final place = _place;
    _place = null;
    if (place != null) _cancelEject(place.id);
  }
}

@Riverpod(keepAlive: true)
EjectWatch ejectWatch(Ref ref) {
  final tracker = ref.watch(volumeActivityTrackerProvider.notifier);
  final watch = EjectWatch(cancelEject: tracker.cancelEject);
  final lifecycle = AppLifecycleListener(
    onHide: watch.onBackground,
    onShow: watch.onForeground,
  );
  ref.onDispose(() {
    lifecycle.dispose();
    watch.dispose();
  });
  return watch;
}
