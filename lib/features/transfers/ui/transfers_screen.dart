import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/features/connect/domain/remote_connection_state.dart';
import 'package:kfm/features/connect/ui/remote_connection_controller.dart';
import 'package:kfm/features/transfers/data/transfer_providers.dart';
import 'package:kfm/features/transfers/domain/transfer_job.dart';
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
List<TransferSection> transferSections(Ref ref) => const [];

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
    _ => l10n.transferFailedGeneric,
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
    final anyFinished = all.any((j) => j.isFinished);
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
    final status = switch (job.status) {
      TransferStatus.queued || TransferStatus.paused =>
        connected
            ? l10n.transferStatusQueued
            : l10n.transferStatusWaitingFor(job.deviceName),
      TransferStatus.running => l10n.transferStatusRunning,
      TransferStatus.done => l10n.transferStatusDone,
      TransferStatus.failed => l10n.transferStatusFailed(job.failedCount),
      TransferStatus.cancelled => l10n.transferStatusCancelled,
    };
    final speed = live.bytesPerSecond[job.id] ?? 0;
    final lines = <String>[
      '${l10n.transferFiles(job.files.length)} · $status',
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
    final retryable = job.files.any(
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
        title: Text(
          download
              ? l10n.transferFromDevice(job.deviceName)
              : l10n.transferToDevice(job.deviceName),
        ),
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
                if (job.isActive)
                  TextButton(
                    key: ValueKey('transfer-cancel-${job.id}'),
                    onPressed: () => unawaited(engine.cancelJob(job.id)),
                    child: Text(l10n.transferCancel),
                  ),
                if (retryable && !job.isActive)
                  TextButton(
                    key: ValueKey('transfer-retry-${job.id}'),
                    onPressed: () => unawaited(engine.retry(job.id)),
                    child: Text(l10n.transferRetry),
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
      TransferFileStatus.queued => l10n.transferStatusQueued,
      TransferFileStatus.running ||
      TransferFileStatus.verifying => l10n.transferProgress(
        formatBytes(live.bytes[f.id] ?? f.bytesDone, locale: locale),
        formatBytes(f.sizeBytes, locale: locale),
      ),
      TransferFileStatus.done ||
      TransferFileStatus.skipped => l10n.transferStatusDone,
      TransferFileStatus.failed => transferErrorText(l10n, f.error, job),
      TransferFileStatus.cancelled => l10n.transferStatusCancelled,
    };
    final Widget? trailing = switch (f.status) {
      TransferFileStatus.queued || TransferFileStatus.running => IconButton(
        tooltip: l10n.transferCancel,
        icon: const Icon(Icons.close),
        onPressed: () => unawaited(engine.cancelFile(job.id, f.id)),
      ),
      TransferFileStatus.failed || TransferFileStatus.cancelled => IconButton(
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
