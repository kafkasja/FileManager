import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/files/staging_dir.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/domain/connection_request.dart';
import 'package:kfm/features/connect/domain/remote_connection_state.dart';
import 'package:kfm/features/connect/ui/known_devices_providers.dart';
import 'package:kfm/features/connect/ui/remote_connection_controller.dart';
import 'package:kfm/features/privacy/data/privacy_providers.dart';
import 'package:kfm/features/privacy/data/privacy_transfer_preprocessor.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/transfers/data/transfer_engine.dart';
import 'package:kfm/features/transfers/data/transfers_dao.dart';
import 'package:kfm/features/transfers/data/verified_move_impl.dart';
import 'package:kfm/features/transfers/domain/transfer_job.dart';
import 'package:kfm/features/transfers/domain/transfer_preprocessor.dart';
import 'package:kfm/features/transfers/domain/verified_move.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transfer_providers.g.dart';

@Riverpod(keepAlive: true)
TransfersRepository transfersRepository(Ref ref) => TransfersRepository(
  TransfersDao(ref.watch(appDatabaseProvider)),
  ref.watch(dbWriteQueueProvider),
);

/// Runs before an upload reads a file: X2 strips location from photos and
/// videos while "Remove location when sharing" is on (read per file, so a
/// change applies to the next file), else the file is sent as it is.
@Riverpod(keepAlive: true)
TransferPreprocessor transferPreprocessor(Ref ref) =>
    PrivacyTransferPreprocessor(
      enabled: () => ref
          .read(settingsRepositoryProvider)
          .read(AppSettings.privacyStripLocation),
      stripper: ref.watch(locationStripperProvider),
    );

/// Where partials are written (tests override it with a temp folder).
@Riverpod(keepAlive: true)
Future<Directory> Function() transferStaging(Ref ref) => transferStagingDir;

/// The folder downloads go under by default: Android
/// `/storage/emulated/0/Download`, elsewhere `~/Downloads` (PL1).
@Riverpod(keepAlive: true)
String downloadsRoot(Ref ref) {
  if (Platform.isAndroid) return '/storage/emulated/0/Download';
  final home =
      Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '';
  return '$home/Downloads'.replaceAll(r'\', '/');
}

/// Deletes the originals of verified moves on this device (TASK-N11; U2
/// and X3 reuse it): under the history lock, deleted files leave the
/// index afterwards.
@Riverpod(keepAlive: true)
VerifiedMove verifiedMove(Ref ref) => LocalVerifiedMove(
  source: ref.watch(fileSourceProvider),
  lock: ref.watch(historyLockProvider),
  removeFromIndex: (ids) async {
    // Waits for indexer jobs queued before it (an empty addFiles is a
    // barrier), so an earlier upsert can't bring the rows back (B4).
    await ref.read(mediaIndexerProvider).addFiles(const []);
    await ref
        .read(dbWriteQueueProvider)
        .enqueue(null, () => ref.read(mediaIndexDaoProvider).deleteIds(ids));
  },
);

/// The Wi-Fi transfer engine (TASK-N9). The app watches it once, so it
/// lives (and follows the connection) as long as the app.
@Riverpod(keepAlive: true)
TransferEngine transferEngine(Ref ref) {
  final controller = ref.read(remoteConnectionControllerProvider.notifier);
  final engine = TransferEngine(
    repo: ref.watch(transfersRepositoryProvider),
    devices: ref.watch(knownDevicesRepositoryProvider),
    local: ref.watch(fileSourceProvider),
    http: (fp) => switch (ref.read(remoteConnectionControllerProvider)) {
      RemoteConnected(peerFingerprint: final p) when p == fp => controller.http,
      _ => null,
    },
    staging: ref.watch(transferStagingProvider),
    preprocessor: ref.watch(transferPreprocessorProvider),
    addToIndex: (files) => ref.read(mediaIndexerProvider).addFiles(files),
    onUnauthorized: controller.reportUnauthorized,
    reconnect: (fp) => ref.read(knownDeviceConnectorProvider).reconnect(fp),
    // N12: sends reconnect without a connection prompt over there.
    reconnectToSend: (fp) => ref
        .read(knownDeviceConnectorProvider)
        .reconnect(fp, purpose: SessionPurpose.send),
    // N12: a send-only connection ends with its last send.
    onOffersIdle: (fp) {
      if (ref.read(remoteConnectionControllerProvider)
          case RemoteConnected(peerFingerprint: final p, sendOnly: true)
          when p == fp) {
        unawaited(controller.disconnect());
      }
    },
    isForeground: _inForeground,
    verifiedMove: ref.watch(verifiedMoveProvider),
  );
  ref
    ..listen(remoteConnectionControllerProvider, (_, next) {
      switch (next) {
        case RemoteConnected(:final peerFingerprint):
          engine.onConnection(peerFingerprint);
        // N10: reconnect by itself after a lost link, the other device
        // stopping, or an app start; never after Disconnect or a revoke.
        case RemoteDisconnected(:final reason):
          engine.onConnection(
            null,
            autoReconnect:
                reason == DisconnectReason.networkLost ||
                reason == DisconnectReason.remoteStopped,
          );
        case RemoteIdle():
          engine.onConnection(null, autoReconnect: true);
      }
    }, fireImmediately: true)
    ..onDispose(() => unawaited(engine.dispose()));
  unawaited(engine.start());
  return engine;
}

bool _inForeground() {
  final s = WidgetsBinding.instance.lifecycleState;
  return s == null ||
      s == AppLifecycleState.resumed ||
      s == AppLifecycleState.inactive;
}

/// Every job, newest first (Transfers page).
@riverpod
Stream<List<TransferJob>> transferJobs(Ref ref) =>
    ref.watch(transfersRepositoryProvider).watchJobs();

/// Live bytes and speeds of running files.
@riverpod
Stream<TransferLive> transferLive(Ref ref) async* {
  final engine = ref.watch(transferEngineProvider);
  yield engine.currentLive;
  yield* engine.live;
}

/// Jobs queued or running (settings row, badge).
@riverpod
int activeTransferCount(Ref ref) =>
    ref.watch(transferJobsProvider).value?.where((j) => j.isActive).length ?? 0;

/// Jobs running right now (the swipe screen's badge shows only then).
@riverpod
int runningTransferCount(Ref ref) =>
    ref
        .watch(transferJobsProvider)
        .value
        ?.where((j) => j.status == TransferStatus.running)
        .length ??
    0;
