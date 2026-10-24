import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:workmanager/workmanager.dart';

part 'background_scheduler.g.dart';

/// Unique WorkManager names (keep stable: renaming registers a second job).
abstract final class BackgroundJobs {
  static const pendingPurgeUnique = 'kfm.pendingPurge.daily';
  static const pendingPurgeTask = 'pendingPurge';
}

abstract interface class BackgroundScheduler {
  /// Registers the daily pending-folder purge once; keeps an existing one.
  Future<void> ensureDailyPurge();
}

/// H2: Android WorkManager. Offline only (no network constraint).
class WorkmanagerScheduler implements BackgroundScheduler {
  new(this._dispatcher);

  /// Top-level `@pragma('vm:entry-point')` function (pending_purge_worker).
  final void Function() _dispatcher;
  bool _initialized = false;

  @override
  Future<void> ensureDailyPurge() async {
    if (!_initialized) {
      await Workmanager().initialize(_dispatcher);
      _initialized = true;
    }
    await Workmanager().registerPeriodicTask(
      BackgroundJobs.pendingPurgeUnique,
      BackgroundJobs.pendingPurgeTask,
      frequency: const Duration(hours: 24),
      initialDelay: const Duration(hours: 1),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: true,
      ),
    );
  }
}

/// Null off Android (no job needed); `main.dart` overrides it on Android.
/// Tests override with a fake.
@Riverpod(keepAlive: true)
BackgroundScheduler? backgroundScheduler(Ref ref) => null;
