import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';
import 'package:kfm/app/app_info.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/diagnostics/error_log.dart';
import 'package:kfm/core/diagnostics/error_log_providers.dart';
import 'package:kfm/features/updates/data/github_release_client.dart';
import 'package:kfm/features/updates/domain/app_version.dart';
import 'package:kfm/features/updates/domain/release_info.dart';
import 'package:kfm/features/updates/domain/update_status.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'update_checker.g.dart';

/// The installed version (overridden in tests).
@Riverpod(keepAlive: true)
AppVersion currentAppVersion(Ref ref) => AppVersion.tryParse(appVersion)!;

/// Wall clock for the daily rule (overridden in tests).
@Riverpod(keepAlive: true)
DateTime Function() updateClock(Ref ref) => DateTime.now;

/// "Check for updates" (off by default; rule 7).
@Riverpod(keepAlive: true)
Stream<bool> updateCheckEnabled(Ref ref) =>
    ref.watch(settingsRepositoryProvider).watch(AppSettings.updateCheckEnabled);

/// The version whose banner the user closed ('' = none).
@riverpod
Stream<String> updateDismissedVersion(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watch(AppSettings.updateDismissedVersion);

/// TASK-X7: asks GitHub for the latest release. Automatic checks run at most
/// once a day and only while the switch is on; "Check now" always runs.
/// State: null until something is known.
@Riverpod(keepAlive: true)
class UpdateChecker extends _$UpdateChecker {
  static const interval = Duration(hours: 24);

  @override
  UpdateStatus? build() {
    unawaited(_restoreCached());
    return null;
  }

  /// The last newer release survives restarts without a request.
  Future<void> _restoreCached() async {
    final json = await ref
        .read(settingsRepositoryProvider)
        .read(AppSettings.updateLatestJson);
    final cached = ReleaseInfo.tryDecode(json);
    if (!ref.mounted || state != null || cached == null) return;
    if (cached.version > ref.read(currentAppVersionProvider)) {
      state = UpdateAvailable(cached);
    }
  }

  /// Runs a check. Automatic ([manual] false) checks return null without a
  /// request when the switch is off or the last one is under a day old.
  /// Never throws: failures become [UpdateCheckFailed].
  Future<UpdateStatus?> checkNow({required bool manual}) =>
      _inFlight ??= _check(manual: manual).whenComplete(() => _inFlight = null);

  /// One check at a time (start + resume + switch can fire together).
  Future<UpdateStatus?>? _inFlight;

  Future<UpdateStatus?> _check({required bool manual}) async {
    final settings = ref.read(settingsRepositoryProvider);
    if (!manual) {
      if (!await settings.read(AppSettings.updateCheckEnabled)) return null;
      final now = ref.read(updateClockProvider)().toUtc();
      final last = DateTime.tryParse(
        await settings.read(AppSettings.updateLastCheckAt),
      );
      // A last check in the future means the clock moved: stale.
      if (last != null &&
          !last.isAfter(now) &&
          now.difference(last) < interval) {
        return null;
      }
      // Written first: a failing request still counts (no retry storm).
      await settings.write(
        AppSettings.updateLastCheckAt,
        now.toIso8601String(),
      );
    }
    if (!ref.mounted) return null;
    state = const UpdateChecking();
    UpdateStatus result;
    try {
      final release = await ref.read(releaseClientProvider).latest();
      if (release == null) {
        result = const UpToDate(noReleases: true);
      } else if (release.version > ref.read(currentAppVersionProvider)) {
        result = UpdateAvailable(release);
      } else {
        result = const UpToDate();
      }
      settings
          .write(
            AppSettings.updateLatestJson,
            result is UpdateAvailable ? result.release.encode() : '',
          )
          .fireAndForget();
    } on ReleaseCheckException catch (e, st) {
      if (e.failure == ReleaseCheckFailure.unparsableTag) {
        developer.log('release tag ignored', name: 'kfm.updates', error: e);
        result = const UpToDate();
      } else {
        result = _failed(e, st, manual: manual);
      }
    } on Object catch (e, st) {
      result = _failed(e, st, manual: manual);
    }
    if (ref.mounted) state = result;
    return result;
  }

  UpdateStatus _failed(Object e, StackTrace st, {required bool manual}) {
    if (!manual) {
      ref
          .read(errorLogProvider)
          .record(
            ErrorLogEntry(
              at: DateTime.now().toUtc(),
              source: ErrorSource.bg,
              error: 'update check: $e',
              stack: st,
            ),
          )
          .ignore();
    }
    return UpdateCheckFailed(e, manual: manual);
  }
}

/// Watched by `App`: the automatic check on start, on resume and when the
/// switch turns on. Does nothing (no request) while the switch is off.
@Riverpod(keepAlive: true)
void updateAutoCheck(Ref ref) {
  void run() {
    unawaited(ref.read(updateCheckerProvider.notifier).checkNow(manual: false));
  }

  final listener = AppLifecycleListener(onResume: run);
  ref
    ..onDispose(listener.dispose)
    ..listen(updateCheckEnabledProvider, (prev, next) {
      if (next.value ?? false) run();
    });
  run();
}
