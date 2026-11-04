import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:kfm/app/notification_l10n.dart';
import 'package:kfm/core/diagnostics/error_log.dart';
import 'package:kfm/core/diagnostics/error_log_providers.dart';
import 'package:kfm/core/platform/windows/desktop_shell_provider.dart';
import 'package:kfm/core/platform/windows/index_roots.dart';
import 'package:kfm/features/background_jobs/data/android_presence_port.dart';
import 'package:kfm/features/background_jobs/data/background_presence.dart';
import 'package:kfm/features/background_jobs/data/incoming_uploads_tracker.dart';
import 'package:kfm/features/background_jobs/data/job_progress_aggregator.dart';
import 'package:kfm/features/background_jobs/data/job_sources.dart';
import 'package:kfm/features/background_jobs/data/windows_presence_port.dart';
import 'package:kfm/features/background_jobs/domain/job_notice.dart';
import 'package:kfm/features/background_jobs/domain/job_progress.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/external_storage/data/places_repository.dart';
import 'package:kfm/features/external_storage/ui/place_labels.dart';
import 'package:kfm/features/folders/data/local_job_providers.dart';
import 'package:kfm/features/folders/data/local_job_runner.dart';
import 'package:kfm/features/folders/data/local_jobs_dao.dart';
import 'package:kfm/features/transfers/data/transfer_engine.dart';
import 'package:kfm/features/transfers/data/transfer_providers.dart';
import 'package:kfm/features/transfers/domain/transfer_job.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'background_jobs_providers.g.dart';

/// Every job source merged (TASK-X8): Wi-Fi transfers, U2 local jobs and
/// uploads other devices make into this one. Lives with the app.
@Riverpod(keepAlive: true)
JobProgressAggregator jobProgressAggregator(Ref ref) {
  final agg = JobProgressAggregator();
  final subs = <StreamSubscription<Object?>>[];

  // Transfers: DB rows + the engine's live bytes.
  final engine = ref.watch(transferEngineProvider);
  var transfers = const <TransferJob>[];
  var live = engine.currentLive;
  void pushTransfers() =>
      agg.update('t', [for (final j in transfers) transferProgressOf(j, live)]);
  subs
    ..add(
      ref.watch(transfersRepositoryProvider).watchJobs().listen((j) {
        transfers = j;
        pushTransfers();
      }),
    )
    ..add(
      engine.live.listen((l) {
        live = l;
        pushTransfers();
      }),
    );

  // U2 local jobs: DB rows + the copying file's bytes.
  final runner = ref.watch(localJobRunnerProvider);
  if (runner != null) {
    var views = const <LocalJobView>[];
    var bytes = runner.currentLive;
    void pushLocal() => agg.update('l', [
      for (final v in views) localProgressOf(v, bytes[v.job.id]),
    ]);
    subs
      ..add(
        ref
            .watch(localJobsDaoProvider)
            .watchRecent(
              since: DateTime.now().subtract(const Duration(days: 1)),
            )
            .listen((v) {
              views = v;
              pushLocal();
            }),
      )
      ..add(
        runner.live.listen((b) {
          bytes = b;
          pushLocal();
        }),
      );
  }

  // Incoming uploads (this device shares, another one sends).
  final sessions = ref.watch(clientSessionStoreProvider);
  final names = <String, String>{};
  final incoming = IncomingUploadsTracker(
    activity: ref.watch(uploadStoreProvider).activity,
    nameOf: (fp) {
      for (final s in sessions.sessions) {
        if (s.clientFingerprint == fp) return names[fp] = s.clientName;
      }
      return names[fp] ?? fp.substring(0, fp.length.clamp(0, 8));
    },
  );
  subs.add(incoming.jobs.listen((j) => agg.update('i', j)));

  ref.onDispose(() {
    for (final s in subs) {
      unawaited(s.cancel());
    }
    unawaited(incoming.dispose());
    unawaited(agg.dispose());
  });
  return agg;
}

/// Running and paused jobs (in-app indicator, desktop status bar).
@Riverpod(keepAlive: true)
Stream<JobsSnapshot> jobsSnapshot(Ref ref) async* {
  final agg = ref.watch(jobProgressAggregatorProvider);
  yield agg.current;
  yield* agg.snapshots;
}

/// [jobsSnapshot] as a value (empty while loading).
@riverpod
JobsSnapshot currentJobs(Ref ref) =>
    ref.watch(jobsSnapshotProvider).value ?? JobsSnapshot.empty;

/// Language-dependent formatting for notices: KFM's language, place names
/// from U1.
@riverpod
NoticeFormat noticeFormat(Ref ref) => _noticeFormat(ref);

NoticeFormat _noticeFormat(Ref ref) {
  final l10n = ref.read(notificationL10nProvider);
  final places = ref.read(placesProvider).value ?? const [];
  return NoticeFormat(
    l10n: l10n,
    locale: ref.read(notificationLocaleProvider).toLanguageTag(),
    placeName: (t) {
      final p = places.where((p) => p.id == t.placeId).firstOrNull;
      return p == null ? t.folder : placeLabel(l10n, p);
    },
  );
}

/// The platform side of [backgroundPresence].
@Riverpod(keepAlive: true)
PresencePort presencePort(Ref ref) {
  if (Platform.isAndroid) return AndroidPresencePort();
  final shell = ref.watch(desktopShellProvider);
  if (shell != null) {
    final channel = ref.watch(windowsChannelProvider);
    return WindowsPresencePort(
      shell: shell,
      taskbar: channel.setTaskbarProgress,
      l10n: () => ref.read(notificationL10nProvider),
    );
  }
  return const NoPresencePort();
}

class _Controls implements JobControls {
  new(this._engine, this._runner);

  final TransferEngine _engine;
  final LocalJobRunner? _runner;

  @override
  Future<void> pause(String key) async {
    if (key.startsWith(transferKeyPrefix)) {
      await _engine.pauseJob(key.substring(transferKeyPrefix.length));
    } else if (key.startsWith(localKeyPrefix)) {
      await _runner?.pause(key.substring(localKeyPrefix.length));
    }
  }

  @override
  Future<void> resume(String key) async {
    if (key.startsWith(transferKeyPrefix)) {
      await _engine.resumeJob(key.substring(transferKeyPrefix.length));
    } else if (key.startsWith(localKeyPrefix)) {
      await _runner?.resume(key.substring(localKeyPrefix.length));
    }
  }

  @override
  Future<void> cancel(String key) async {
    if (key.startsWith(transferKeyPrefix)) {
      await _engine.cancelJob(key.substring(transferKeyPrefix.length));
    } else if (key.startsWith(localKeyPrefix)) {
      await _runner?.cancel(key.substring(localKeyPrefix.length));
    }
  }
}

/// TASK-X8: what keeps KFM alive in the background and the notification /
/// tray / taskbar that shows it. Watched by `App`; re-renders when KFM's
/// language changes; jobs paused by Android's time limit continue when KFM
/// is back in front.
@Riverpod(keepAlive: true)
BackgroundPresence backgroundPresence(Ref ref) {
  final agg = ref.watch(jobProgressAggregatorProvider);
  final log = ref.watch(errorLogProvider);
  final presence = BackgroundPresence(
    port: ref.watch(presencePortProvider),
    controls: _Controls(
      ref.watch(transferEngineProvider),
      ref.watch(localJobRunnerProvider),
    ),
    format: () => _noticeFormat(ref),
    snapshots: agg.snapshots,
    ends: agg.ends,
    initial: agg.current,
    onError: (e, st) => log
        .record(
          ErrorLogEntry(
            at: DateTime.now().toUtc(),
            source: ErrorSource.bg,
            error: 'background jobs: $e',
            stack: st,
          ),
        )
        .ignore(),
  );
  ref
    ..listen(notificationLocaleProvider, (_, _) => presence.refresh())
    ..listen(placesProvider, (_, _) => presence.refresh());
  final lifecycle = AppLifecycleListener(
    onResume: () => unawaited(presence.onForeground()),
  );
  ref.onDispose(() {
    lifecycle.dispose();
    unawaited(presence.dispose());
  });
  return presence;
}
