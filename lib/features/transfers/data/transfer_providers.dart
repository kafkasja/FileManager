import 'dart:async';
import 'dart:io';

import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/files/staging_dir.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/domain/remote_connection_state.dart';
import 'package:kfm/features/connect/ui/remote_connection_controller.dart';
import 'package:kfm/features/transfers/data/transfer_engine.dart';
import 'package:kfm/features/transfers/data/transfers_dao.dart';
import 'package:kfm/features/transfers/domain/transfer_job.dart';
import 'package:kfm/features/transfers/domain/transfer_preprocessor.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transfer_providers.g.dart';

@Riverpod(keepAlive: true)
TransfersRepository transfersRepository(Ref ref) => TransfersRepository(
  TransfersDao(ref.watch(appDatabaseProvider)),
  ref.watch(dbWriteQueueProvider),
);

/// Runs before an upload reads a file (identity; X2 overrides it to strip
/// location).
@Riverpod(keepAlive: true)
TransferPreprocessor transferPreprocessor(Ref ref) =>
    const IdentityPreprocessor();

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
  );
  ref
    ..listen(remoteConnectionControllerProvider, (_, next) {
      engine.onConnection(switch (next) {
        RemoteConnected(:final peerFingerprint) => peerFingerprint,
        _ => null,
      });
    }, fireImmediately: true)
    ..onDispose(() => unawaited(engine.dispose()));
  unawaited(engine.start());
  return engine;
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
