import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/features/cloud/data/cloud_providers.dart';
import 'package:kfm/features/cloud/ui/cloud_transfers_section.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/data/pairing_client.dart';
import 'package:kfm/features/connect/domain/remote_connection_state.dart';
import 'package:kfm/features/connect/ui/connect_screen.dart'
    show pairingFailureMessage;
import 'package:kfm/features/connect/ui/remote_connection_controller.dart';
import 'package:kfm/features/folders/ui/local_jobs_section.dart';
import 'package:kfm/features/transfers/data/transfer_providers.dart';
import 'package:kfm/features/transfers/domain/transfer_job.dart';
import 'package:kfm/features/transfers/ui/received_section.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transfers_screen.g.dart';

/// An extra tab on the Transfers page: U2 adds "On this phone" (local
/// copy/move jobs), X3 "Cloud". N9 only provides the slot.
@immutable
class TransferSection {
  const new({required this.id, required this.label, required this.builder});

  final String id;
  final String Function(BuildContext context) label;
  final WidgetBuilder builder;
}

@Riverpod(keepAlive: true)
List<TransferSection> transferSections(Ref ref) => [
  ..._always,
  // X3: only when something went to a cloud folder in the last 7 days.
  if (ref.watch(
    cloudRecentItemsProvider.select((v) => v.value?.isNotEmpty ?? false),
  ))
    TransferSection(
      id: 'cloud',
      label: (context) => context.l10n.cloudTransfersSection,
      builder: (_) => const CloudTransfersSection(),
    ),
];

final List<TransferSection> _always = [
  // U2: copies and moves between places on this device.
  TransferSection(
    id: 'local',
    label: (context) => context.l10n.transfersLocalSection,
    builder: (_) => const LocalJobsSection(),
  ),
  // N12: files other devices sent here (and N12b offers made from here).
  TransferSection(
    id: 'received',
    label: (context) => context.l10n.transferReceivedSection,
    builder: (_) => const ReceivedOffersSection(),
  ),
];

/// Q8: the job's active files all have every byte and are being checked.
bool _onlyChecking(TransferJob job) {
  final active = job.files.where(
    (f) =>
        f.status == TransferFileStatus.running ||
        f.status == TransferFileStatus.verifying,
  );
  return active.isNotEmpty &&
      active.every((f) => f.status == TransferFileStatus.verifying);
}

bool _isOfferError(String? code) => switch (code) {
  TransferErrors.offerDeclined ||
  TransferErrors.offerExpired ||
  TransferErrors.offerNoSpace ||
  TransferErrors.offerCancelled => true,
  _ => false,
};

/// What a stored error code shows (TASK-N9 messages).
String transferErrorText(AppLocalizations l10n, String? code, TransferJob job) {
  final device = job.deviceName;
  return switch (code) {
    'insufficient_storage' => l10n.transferNoSpaceOn(device),
    TransferErrors.noSpaceHere || 'noSpace' => l10n.transferNoSpaceHere,
    // A swipe send's folder is the one picked in the action editor.
    'forbidden_path' || 'forbidden' when job.swipeSessionId != null =>
      l10n.transferNoWritableFolder(device),
    'forbidden_path' || 'forbidden' => l10n.transferNotAllowedOn(device),
    'invalid_name' || 'invalidName' => l10n.transferInvalidName,
    TransferErrors.unavailable ||
    'unauthorized' => l10n.transferLostConnection(device),
    TransferErrors.interrupted => l10n.transferInterrupted,
    TransferErrors.sourceGone ||
    'not_found' ||
    'notFound' => l10n.transferSourceGone,
    TransferErrors.incomplete || 'cancelled' => l10n.transferIncomplete,
    TransferErrors.sourceChanged => l10n.transferSourceChanged,
    TransferErrors.verificationFailed => l10n.transferVerifyFailed,
    TransferErrors.alreadyMoved => l10n.transferAlreadyMoved,
    TransferErrors.locationNotRemoved => l10n.privacyTransferNotRemoved,
    TransferErrors.offerDeclined => l10n.sendDeclined(device),
    TransferErrors.offerExpired => l10n.sendNoAnswer(device),
    TransferErrors.offerNoSpace => l10n.sendNoSpace(device),
    TransferErrors.offerCancelled => l10n.sendStopped(device),
    'busy' || 'too_many_attempts' => l10n.connectErrorBusy(device),
    _ => l10n.transferFailedGeneric,
  };
}

/// N11: a move job's file line once its copy is verified: where the
/// original went (on [job]'s device for a download-move).
String transferOutcomeText(
  AppLocalizations l10n,
  TransferJob job,
  TransferFile f,
) {
  final remote = job.direction == TransferDirection.download;
  final device = job.deviceName;
  return switch (f.sourceOutcome) {
    null => l10n.transferOriginalPending,
    SourceOutcome.trashed =>
      remote
          ? l10n.transferOriginalTrashedOn(device)
          : l10n.transferOriginalTrashed,
    SourceOutcome.deletedPermanently => l10n.transferOriginalDeleted,
    SourceOutcome.alreadyGone => l10n.transferOriginalGone,
    SourceOutcome.keptDeclined =>
      remote
          ? l10n.transferOriginalKeptDeclinedOn(device)
          : l10n.transferOriginalKeptDeclined,
    SourceOutcome.keptCancelled => l10n.transferOriginalKeptCancelled,
    SourceOutcome.keptChanged => l10n.transferOriginalKeptChanged,
    SourceOutcome.keptFailed => l10n.transferOriginalKeptFailed,
  };
}

/// Every Wi-Fi transfer in one place (TASK-N9): Downloads · Uploads (plus
/// the [transferSections] slots), one card per job with total progress,
/// speed, ETA and Cancel; expanding a card lists its files.
class TransfersScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final jobs = ref.watch(transferJobsProvider);
    final sections = ref.watch(transferSectionsProvider);
    final all = jobs.value ?? const <TransferJob>[];
    final anyFinished =
        all.any((j) => j.isFinished) ||
        (ref.watch(shareOffersProvider).value ?? const []).any(
          (o) => !o.isOpen,
        );
    return DefaultTabController(
      length: 2 + sections.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.transfersTitle),
          actions: [
            TextButton(
              key: const ValueKey('transfers-clear-finished'),
              onPressed: anyFinished
                  ? () => unawaited(_clear(context, ref))
                  : null,
              child: Text(l10n.transferClearFinished),
            ),
          ],
          bottom: TabBar(
            isScrollable: sections.isNotEmpty,
            tabs: [
              Tab(text: l10n.transfersDownloads),
              Tab(text: l10n.transfersUploads),
              for (final s in sections) Tab(text: s.label(context)),
            ],
          ),
        ),
        body: SafeArea(
          child: switch (jobs) {
            AsyncError(:final error) => Center(child: Text(error.toString())),
            _ when jobs.value == null => const SizedBox.shrink(),
            _ => TabBarView(
              children: [
                _JobList(
                  jobs: [
                    for (final j in all)
                      if (j.direction == TransferDirection.download) j,
                  ],
                  empty: l10n.transfersEmptyDownloads,
                ),
                _JobList(
                  jobs: [
                    for (final j in all)
                      if (j.direction == TransferDirection.upload) j,
                  ],
                  empty: l10n.transfersEmptyUploads,
                ),
                for (final s in sections) Builder(builder: s.builder),
              ],
            ),
          },
        ),
      ),
    );
  }

  Future<void> _clear(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(transferEngineProvider).clearFinished();
      // N12: finished offers (Received / Offered cards).
      await ref.read(offerRepositoryProvider).clearFinished();
    } on Object catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

class _JobList extends StatelessWidget {
  const new({required this.jobs, required this.empty});

  final List<TransferJob> jobs;
  final String empty;

  @override
  Widget build(BuildContext context) {
    final spacing = context.tokens.spacing;
    if (jobs.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsetsDirectional.all(spacing * 3),
          child: Text(empty, textAlign: TextAlign.center),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsetsDirectional.all(spacing),
      itemCount: jobs.length,
      itemBuilder: (context, i) => _JobCard(job: jobs[i]),
    );
  }
}

class _JobCard extends ConsumerWidget {
  const new({required this.job});

  final TransferJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final live = ref.watch(transferLiveProvider).value ?? TransferLive.empty;
    final connected = switch (ref.watch(remoteConnectionControllerProvider)) {
      RemoteConnected(:final peerFingerprint) =>
        peerFingerprint == job.deviceFingerprint,
      _ => false,
    };
    final engine = ref.read(transferEngineProvider);
    final total = job.totalBytes;
    final done = live.doneBytesOf(job);
    final download = job.direction == TransferDirection.download;
    // N12: a send whose offer ended (declined, no answer, stopped).
    final offerEnd = job.isOffer && job.isFinished
        ? job.files.map((f) => f.error).where(_isOfferError).firstOrNull
        : null;
    final status = switch (job.status) {
      _ when offerEnd != null => transferErrorText(l10n, offerEnd, job),
      TransferStatus.paused => switch (job.pauseReason) {
        TransferPauseReason.awaitingAccept => l10n.sendWaiting(job.deviceName),
        TransferPauseReason.user => l10n.transferPausedByYou,
        TransferPauseReason.noSpace =>
          download
              ? l10n.transferNoSpaceHere
              : l10n.transferNoSpaceOn(job.deviceName),
        _ => l10n.transferStatusWaitingFor(job.deviceName),
      },
      TransferStatus.queued when !connected => l10n.transferStatusWaitingFor(
        job.deviceName,
      ),
      TransferStatus.queued when job.files.any((f) => f.isRetrying) =>
        l10n.transferRetrying,
      TransferStatus.queued => l10n.transferStatusQueued,
      // Q8: every byte sent, both sides are hashing (minutes for big files).
      TransferStatus.running when _onlyChecking(job) =>
        job.isMove ? l10n.transferVerifying : l10n.transferChecking,
      TransferStatus.running => l10n.transferStatusRunning,
      TransferStatus.done => l10n.transferStatusDone,
      TransferStatus.failed => l10n.transferStatusFailed(job.failedCount),
      TransferStatus.cancelled => l10n.transferStatusCancelled,
    };
    final speed = live.bytesPerSecond[job.id] ?? 0;
    final finalizing = live.finalizing.contains(job.id);
    // N11: originals that "Delete originals" may (re)try.
    final deletable =
        job.isMove &&
        job.allFilesEnded &&
        !finalizing &&
        job.files.any((f) => f.originalDeletable) &&
        (!download || connected);
    final shown = finalizing ? l10n.transferDeletingOriginals : status;
    final lines = <String>[
      '${l10n.transferFiles(job.files.length)} · $shown',
      l10n.transferProgress(
        formatBytes(done, locale: locale),
        formatBytes(total, locale: locale),
      ),
      if (job.status == TransferStatus.running && speed > 0)
        l10n.transferSpeedEta(
          formatBytes(speed.round(), locale: locale),
          formatDuration(
            Duration(seconds: ((total - done) / speed).ceil().clamp(0, 359999)),
          ),
        ),
    ];
    // Waiting for the device: it continues by itself; Pause keeps it.
    final waiting =
        job.isPaused && job.pauseReason == TransferPauseReason.waitingForDevice;
    // N12: an ended offer can't take files any more (send again).
    final retryable =
        offerEnd == null &&
        job.files.any(
          (f) =>
              f.status == TransferFileStatus.failed ||
              f.status == TransferFileStatus.cancelled,
        );
    return Card(
      key: ValueKey('transfer-job-${job.id}'),
      child: ExpansionTile(
        leading: Icon(
          download ? Icons.download_outlined : Icons.upload_outlined,
        ),
        title: Text(switch ((download, job.isMove)) {
          (true, false) => l10n.transferFromDevice(job.deviceName),
          (true, true) => l10n.transferMoveFromDevice(job.deviceName),
          (false, false) => l10n.transferToDevice(job.deviceName),
          (false, true) => l10n.transferMoveToDeviceTitle(job.deviceName),
        }),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final line in lines) Text(line),
            Padding(
              padding: EdgeInsetsDirectional.only(
                top: context.tokens.spacing / 2,
              ),
              // Determinate only: no repeating animation.
              child: LinearProgressIndicator(
                value: total == 0 ? (job.isFinished ? 1 : 0) : done / total,
              ),
            ),
            Wrap(
              spacing: context.tokens.spacing,
              children: [
                if (job.isActive || waiting)
                  TextButton(
                    key: ValueKey('transfer-pause-${job.id}'),
                    onPressed: () => unawaited(engine.pauseJob(job.id)),
                    child: Text(l10n.transferPause),
                  ),
                if (job.isPaused && !waiting && !job.awaitingAccept)
                  TextButton(
                    key: ValueKey('transfer-resume-${job.id}'),
                    onPressed: () => unawaited(engine.resumeJob(job.id)),
                    child: Text(l10n.transferResume),
                  ),
                if (waiting && !job.deviceTemporary && !connected)
                  TextButton(
                    key: ValueKey('transfer-reconnect-${job.id}'),
                    onPressed: () => unawaited(_reconnect(context, ref)),
                    child: Text(l10n.transferReconnect),
                  ),
                if (job.isActive || job.isPaused)
                  TextButton(
                    key: ValueKey('transfer-cancel-${job.id}'),
                    onPressed: () => unawaited(engine.cancelJob(job.id)),
                    child: Text(l10n.transferCancel),
                  ),
                if (retryable && !job.isActive && !job.isPaused)
                  TextButton(
                    key: ValueKey('transfer-retry-${job.id}'),
                    onPressed: () => unawaited(engine.retry(job.id)),
                    child: Text(l10n.transferRetry),
                  ),
                if (deletable)
                  TextButton(
                    key: ValueKey('transfer-delete-originals-${job.id}'),
                    onPressed: () => unawaited(engine.deleteOriginals(job.id)),
                    child: Text(l10n.transferDeleteOriginals),
                  ),
              ],
            ),
          ],
        ),
        children: [
          for (final f in job.files)
            _FileRow(job: job, file: f, live: live, locale: locale),
        ],
      ),
    );
  }

  /// N6's reconnect; a failure shows why (rule 8).
  Future<void> _reconnect(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    try {
      await ref.read(transferEngineProvider).reconnect(job.deviceFingerprint);
    } on PairingException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(pairingFailureMessage(l10n, e.failure, job.deviceName)),
        ),
      );
    } on Object catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

class _FileRow extends ConsumerWidget {
  const new({
    required this.job,
    required this.file,
    required this.live,
    required this.locale,
  });

  final TransferJob job;
  final TransferFile file;
  final TransferLive live;
  final String locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final engine = ref.read(transferEngineProvider);
    final f = file;
    final subtitle = switch (f.status) {
      // N11: a move's whole copy waiting to be checked (the link dropped).
      // Q8: a copy's too (both sides hash it; can take minutes).
      TransferFileStatus.queued
          when f.sizeBytes > 0 && f.bytesDone >= f.sizeBytes =>
        job.isMove ? l10n.transferVerifying : l10n.transferChecking,
      TransferFileStatus.queued when f.isRetrying => l10n.transferRetrying,
      TransferFileStatus.queued
          when f.error == TransferErrors.verificationFailed =>
        l10n.transferVerifyFailed,
      TransferFileStatus.queued when f.bytesDone > 0 => l10n.transferProgress(
        formatBytes(f.bytesDone, locale: locale),
        formatBytes(f.sizeBytes, locale: locale),
      ),
      TransferFileStatus.queued => l10n.transferStatusQueued,
      TransferFileStatus.verifying =>
        job.isMove ? l10n.transferVerifying : l10n.transferChecking,
      TransferFileStatus.running => l10n.transferProgress(
        formatBytes(live.bytes[f.id] ?? f.bytesDone, locale: locale),
        formatBytes(f.sizeBytes, locale: locale),
      ),
      TransferFileStatus.done when f.receiverSha256 != null =>
        transferOutcomeText(l10n, job, f),
      TransferFileStatus.done when job.isMove => l10n.transferVerified,
      TransferFileStatus.skipped when f.error == TransferErrors.alreadyMoved =>
        l10n.transferAlreadyMoved,
      TransferFileStatus.done ||
      TransferFileStatus.skipped => l10n.transferStatusDone,
      TransferFileStatus.failed => transferErrorText(l10n, f.error, job),
      TransferFileStatus.cancelled when _isOfferError(f.error) =>
        transferErrorText(l10n, f.error, job),
      TransferFileStatus.cancelled => l10n.transferStatusCancelled,
    };
    final Widget? trailing = switch (f.status) {
      TransferFileStatus.queued || TransferFileStatus.running => IconButton(
        tooltip: l10n.transferCancel,
        icon: const Icon(Icons.close),
        onPressed: () => unawaited(engine.cancelFile(job.id, f.id)),
      ),
      TransferFileStatus.failed ||
      TransferFileStatus.cancelled when !_isOfferError(f.error) => IconButton(
        tooltip: l10n.transferRetry,
        icon: const Icon(Icons.refresh),
        onPressed: () => unawaited(engine.retry(job.id, fileId: f.id)),
      ),
      _ => null,
    };
    return ListTile(
      dense: true,
      title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle),
      trailing: trailing,
    );
  }
}
