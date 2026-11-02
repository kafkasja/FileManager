import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/features/external_storage/domain/storage_place.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'volume_activity_tracker.g.dart';

/// What KFM itself is doing on each removable place (TASK-U3).
@immutable
class VolumeActivity {
  const new({this.open = const {}, this.ejecting = const {}});

  /// placeId → running ops (entries removed at 0).
  final Map<String, int> open;

  /// Places being ejected: new work on them is refused.
  final Set<String> ejecting;

  int activeCount(String placeId) => open[placeId] ?? 0;

  bool isEjecting(String placeId) => ejecting.contains(placeId);

  VolumeActivity copyWith({Map<String, int>? open, Set<String>? ejecting}) =>
      VolumeActivity(
        open: open ?? this.open,
        ejecting: ejecting ?? this.ejecting,
      );

  @override
  bool operator ==(Object other) =>
      other is VolumeActivity &&
      mapEquals(other.open, open) &&
      setEquals(other.ejecting, ejecting);

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(
      open.entries.map((e) => Object.hash(e.key, e.value)),
    ),
    Object.hashAllUnordered(ejecting),
  );

  @override
  String toString() => 'VolumeActivity(open: $open, ejecting: $ejecting)';
}

/// One counted unit of work on a place; [release] is idempotent.
class VolumeLease {
  new _(this._tracker, this.placeId, this._onEject);

  final VolumeActivityTracker _tracker;
  final String placeId;
  final void Function()? _onEject;
  bool _released = false;

  void release() {
    if (_released) return;
    _released = true;
    _tracker._release(this);
  }
}

/// Zone key: the places the current zone already holds (nested calls of a
/// running op are counted but never refused, so a batch never half-runs).
const Symbol _heldKey = #kfmVolumeHeld;

Set<String> _held() => switch (Zone.current[_heldKey]) {
  final Set<String> s => s,
  _ => const {},
};

/// Counts KFM's own work per removable place and refuses new work while a
/// place is being ejected (TASK-U3). Internal storage is never tracked.
@Riverpod(keepAlive: true)
class VolumeActivityTracker extends _$VolumeActivityTracker {
  final Map<String, Set<VolumeLease>> _leases = {};
  final Map<String, Completer<void>> _idle = {};

  @override
  VolumeActivity build() => const VolumeActivity();

  /// Whether [placeId] is tracked at all.
  static bool tracks(String placeId) => placeId != kInternalPlaceId;

  /// Counts [placeId] as busy. Throws
  /// `FileOpException(FileOpFailure.volumeEjecting)` while it's ejecting
  /// (unless the current zone already holds it). [onEject] is called when
  /// an eject starts while the lease is held by top-level work (streams:
  /// cancel themselves).
  VolumeLease acquire(String placeId, {void Function()? onEject}) {
    final nested = _held().contains(placeId);
    if (!nested && state.ejecting.contains(placeId)) {
      throw FileOpException(FileOpFailure.volumeEjecting, 'ejecting: $placeId');
    }
    final lease = VolumeLease._(this, placeId, nested ? null : onEject);
    (_leases[placeId] ??= {}).add(lease);
    _add(placeId, 1);
    return lease;
  }

  /// Runs [op] with [placeId] counted (see [acquire]); released in
  /// `finally`.
  Future<T> run<T>(String placeId, Future<T> Function() op) =>
      runAll([placeId], op);

  /// [run] for several places at once (a move between two places).
  Future<T> runAll<T>(
    Iterable<String> placeIds,
    Future<T> Function() op,
  ) async {
    final ids = {
      for (final id in placeIds)
        if (tracks(id)) id,
    };
    if (ids.isEmpty) return await op();
    final leases = <VolumeLease>[];
    try {
      for (final id in ids) {
        leases.add(acquire(id));
      }
      return await runZoned(
        op,
        zoneValues: {
          _heldKey: {..._held(), ...ids},
        },
      );
    } finally {
      for (final l in leases) {
        l.release();
      }
    }
  }

  /// New ops on [placeId] are refused; open top-level streams on it end.
  void beginEject(String placeId) {
    if (!tracks(placeId) || state.ejecting.contains(placeId)) return;
    state = state.copyWith(ejecting: {...state.ejecting, placeId});
    for (final l in [...?_leases[placeId]]) {
      l._onEject?.call();
    }
  }

  /// The place is usable again.
  void cancelEject(String placeId) {
    if (!state.ejecting.contains(placeId)) return;
    state = state.copyWith(ejecting: {...state.ejecting}..remove(placeId));
  }

  /// The volume is gone: forget it.
  void completeEject(String placeId) {
    _leases.remove(placeId);
    _completeIdle(placeId);
    state = state.copyWith(
      ejecting: {...state.ejecting}..remove(placeId),
      open: {...state.open}..remove(placeId),
    );
  }

  /// Completes once nothing runs on [placeId].
  Future<void> whenIdle(String placeId) {
    if (state.activeCount(placeId) == 0) return Future.value();
    return (_idle[placeId] ??= Completer<void>()).future;
  }

  void _release(VolumeLease lease) {
    final set = _leases[lease.placeId];
    if (set == null || !set.remove(lease)) return;
    if (set.isEmpty) _leases.remove(lease.placeId);
    _add(lease.placeId, -1);
  }

  void _add(String placeId, int delta) {
    final next = (state.open[placeId] ?? 0) + delta;
    state = state.copyWith(
      open: {
        for (final e in state.open.entries)
          if (e.key != placeId) e.key: e.value,
        if (next > 0) placeId: next,
      },
    );
    if (next <= 0) _completeIdle(placeId);
  }

  void _completeIdle(String placeId) {
    final c = _idle.remove(placeId);
    if (c != null && !c.isCompleted) c.complete();
  }
}
