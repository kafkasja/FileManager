import 'dart:async';
import 'dart:developer' as developer;

import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/platform/volumes/volumes_channel.dart';
import 'package:kfm/core/platform/volumes/volumes_providers.dart';
import 'package:kfm/features/external_storage/data/eject_watch.dart';
import 'package:kfm/features/external_storage/data/places_repository.dart';
import 'package:kfm/features/external_storage/data/saf_grants.dart';
import 'package:kfm/features/external_storage/data/volume_activity_tracker.dart';
import 'package:kfm/features/external_storage/domain/storage_place.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'places_watcher.g.dart';

/// Something the user should hear about (TASK-U1).
@immutable
sealed class ExternalNotice {
  const new();
}

/// A removable place was mounted / a camera was plugged in.
class PlaceAttached extends ExternalNotice {
  const new(this.place);

  final StoragePlace place;
}

/// A place went away; [place] is how it looked while it was there.
class PlaceRemoved extends ExternalNotice {
  const new(this.place);

  final StoragePlace place;
}

/// U3: a place that was being ejected went away: safe to unplug.
class PlaceEjected extends ExternalNotice {
  const new(this.place);

  final StoragePlace place;
}

/// A USB stick was plugged in but no volume mounted (NTFS, broken).
class UsbFormatHelp extends ExternalNotice {
  const new();
}

/// Reacts to place changes: notices, an index scan of each newly mounted
/// root (now and once more after [rescanDelay], when the system media
/// scanner has caught up), and re-validation of the SAF grant of a
/// remounted volume.
class PlacesWatcher {
  new({
    required this._scanRoot,
    this._validateGrant,
    this._dropGrant,
    this._isEjecting,
    this._onEjected,
    this.formatHelpDelay = const Duration(seconds: 5),
    this.rescanDelay = const Duration(seconds: 30),
  });

  final Future<void> Function(String rootPath) _scanRoot;
  final Future<bool> Function(String treeUri)? _validateGrant;
  final Future<void> Function(String uuid)? _dropGrant;

  /// U3: whether a place is being ejected, and what to do once it's gone.
  final bool Function(String placeId)? _isEjecting;
  final void Function(String placeId)? _onEjected;
  final Duration formatHelpDelay;
  final Duration rescanDelay;

  final _notices = StreamController<ExternalNotice>.broadcast();
  final _timers = <Timer>{};
  Map<String, StoragePlace>? _present;
  int _attachCount = 0;

  Stream<ExternalNotice> get notices => _notices.stream;

  /// The first list is the baseline (no notices for what was already
  /// there).
  void onPlaces(List<StoragePlace> places) {
    final now = {
      for (final p in places)
        if (p.isMounted && p.isRemovable) p.id: p,
    };
    final before = _present;
    _present = now;
    if (before == null) return;
    for (final p in now.values) {
      if (before.containsKey(p.id)) continue;
      _attachCount++;
      _emit(PlaceAttached(p));
      final root = p.rootPath;
      if (root != null) {
        _scan(root);
        _later(rescanDelay, () => _scan(root));
      }
      final uuid = p.volumeUuid;
      final tree = p.treeUri;
      if (uuid != null && tree != null) unawaited(_revalidate(uuid, tree));
    }
    for (final p in before.values) {
      if (now.containsKey(p.id)) continue;
      if (_isEjecting?.call(p.id) ?? false) {
        _onEjected?.call(p.id);
        _emit(PlaceEjected(p));
      } else {
        _onEjected?.call(p.id); // unplugged: forget any count
        _emit(PlaceRemoved(p));
      }
    }
  }

  /// A USB mass-storage device was attached: help when no place mounts
  /// within [formatHelpDelay].
  void onUsbMassStorage() {
    final count = _attachCount;
    _later(formatHelpDelay, () {
      if (_attachCount == count) _emit(const UsbFormatHelp());
    });
  }

  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    unawaited(_notices.close());
  }

  void _scan(String root) => unawaited(_scanRoot(root));

  Future<void> _revalidate(String uuid, String tree) async {
    final validate = _validateGrant;
    final drop = _dropGrant;
    if (validate == null || drop == null) return;
    try {
      if (!await validate(tree)) await drop(uuid);
    } on Object catch (e, st) {
      // Checked again when the place is opened (the grant flow).
      developer.log(
        'grant check failed',
        name: 'kfm.external',
        error: e,
        stackTrace: st,
      );
    }
  }

  void _later(Duration after, void Function() run) {
    late final Timer timer;
    timer = Timer(after, () {
      _timers.remove(timer);
      run();
    });
    _timers.add(timer);
  }

  void _emit(ExternalNotice n) {
    if (!_notices.isClosed) _notices.add(n);
  }
}

/// Lives as long as the app (the shell watches it): hides the index rows
/// of detached volumes, scans mounted ones, and publishes [ExternalNotice]s.
@Riverpod(keepAlive: true)
PlacesWatcher placesWatcher(Ref ref) {
  final indexer = ref.watch(mediaIndexerProvider);
  final dao = ref.watch(mediaIndexDaoProvider);
  final grants = ref.watch(safGrantsProvider);
  final tracker = ref.watch(volumeActivityTrackerProvider.notifier);
  final watcher = PlacesWatcher(
    // Failures land on the indexer's status (IndexFailed).
    scanRoot: indexer.scanRoot,
    validateGrant: grants?.isValid,
    dropGrant: grants?.drop,
    isEjecting: (id) => ref.read(volumeActivityTrackerProvider).isEjecting(id),
    onEjected: (id) {
      tracker.completeEject(id);
      ref.read(ejectWatchProvider).stop(id);
    },
  );
  ref
    ..onDispose(watcher.dispose)
    ..listen(placesProvider, (_, next) {
      if (next case AsyncData(:final value)) watcher.onPlaces(value);
    }, fireImmediately: true)
    ..listen(unmountedRootsProvider, (_, next) {
      if (next case AsyncData(:final value)) dao.setExcludedRoots(value);
    }, fireImmediately: true);
  final volumes = ref.watch(volumesPlatformProvider);
  if (volumes != null) {
    final sub = volumes.events().listen((e) {
      if (e is UsbMassStorageAttached) watcher.onUsbMassStorage();
      // Event errors already surface through deviceStorageProvider.
    }, onError: (_) {});
    ref.onDispose(sub.cancel);
  }
  return watcher;
}
