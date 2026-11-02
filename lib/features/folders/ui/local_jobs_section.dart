import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/features/external_storage/data/places_repository.dart';
import 'package:kfm/features/external_storage/ui/place_labels.dart';
import 'package:kfm/features/folders/data/local_job_providers.dart';
import 'package:kfm/features/folders/data/local_job_runner.dart';
import 'package:kfm/features/folders/data/local_jobs_dao.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// Jobs of the last 7 days.
final StreamProvider<List<LocalJobView>> localJobsRecentProvider =
    StreamProvider.autoDispose<List<LocalJobView>>(
      (ref) => ref
          .watch(localJobsDaoProvider)
          .watchRecent(since: DateTime.now().subtract(const Duration(days: 7))),
    );

/// A file's log line, or null when it went fine.
String? localFileReason(AppLocalizations l10n, LocalJobFileRow f) =>
    switch (f.failureReason) {
      null => null,
      LocalJobErrors.verificationFailed => l10n.externalVerifyFailed,
      LocalJobErrors.sourceGone => l10n.externalSourceGone,
      LocalJobErrors.alreadyMoved => l10n.externalAlreadyMoved,
      LocalJobErrors.exists => l10n.externalSkippedExists,
      LocalJobErrors.fat32TooLarge => l10n.externalFat32TooLarge(
        f.originalName,
      ),
      'noSpace' => l10n.transferNoSpaceHere,
      _ when f.status == LocalFileStatus.failed => l10n.externalFileFailed,
      _ => null,
    };

/// U2's "On this phone" tab on the Transfers page: one card per local
/// copy/move job with progress, Pause / Resume / Cancel, "Delete
/// originals" and the job log.
class LocalJobsSection extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final jobs = ref.watch(localJobsRecentProvider).value ?? const [];
    if (jobs.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsetsDirectional.all(spacing * 2),
          child: Text(l10n.externalNoJobs, textAlign: TextAlign.center),
        ),
      );
    }
    return ListView(
      padding: EdgeInsetsDirectional.all(spacing),
      children: [
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            onPressed: () =>
                unawaited(ref.read(localJobsDaoProvider).clearFinished()),
            child: Text(l10n.externalClearFinished),
          ),
        ),
        for (final j in jobs) _JobCard(view: j),
      ],
    );
  }
}

class _JobCard extends ConsumerWidget {
  const new({required this.view});

  final LocalJobView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final job = view.job;
    final runner = ref.watch(localJobRunnerProvider);
    final places = ref.watch(placesProvider).value ?? const [];
    final place = places.where((p) => p.id == job.targetPlaceId).firstOrNull;
    final placeName = place == null
        ? job.targetFolder
        : placeLabel(l10n, place);
    final title = job.mode == LocalJobMode.move
        ? l10n.externalJobTitleMove(view.total, placeName)
        : l10n.externalJobTitleCopy(view.total, placeName);
    final status = switch (job.status) {
      LocalJobStatus.queued => l10n.externalJobQueued,
      LocalJobStatus.running => l10n.externalJobRunning,
      LocalJobStatus.paused
          when job.failureReason == LocalJobErrors.placeUnmounted =>
        l10n.externalJobPausedUnplugged,
      LocalJobStatus.paused => l10n.externalJobPaused,
      LocalJobStatus.done => l10n.externalJobDone,
      LocalJobStatus.cancelled => l10n.externalJobCancelled,
      LocalJobStatus.failed when job.failureReason == LocalJobErrors.noSpace =>
        l10n.externalJobStoppedNoSpace,
      LocalJobStatus.failed => l10n.externalJobFailed(view.failed),
    };
    final left = view.originalsLeft;
    final active =
        job.status == LocalJobStatus.running ||
        job.status == LocalJobStatus.queued;
    return Card(
      key: ValueKey('local-job-${job.id}'),
      child: Padding(
        padding: EdgeInsetsDirectional.all(spacing * 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            SizedBox(height: spacing / 2),
            Text(status),
            SizedBox(height: spacing / 2),
            LinearProgressIndicator(
              value: view.bytesTotal == 0
                  ? null
                  : view.bytesDone / view.bytesTotal,
            ),
            SizedBox(height: spacing / 2),
            Text(
              l10n.externalJobProgress(
                view.finished,
                view.total,
                formatBytes(view.bytesDone),
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (left.isNotEmpty && !active)
              Text(l10n.externalOriginalNotRemoved(left.length)),
            Wrap(
              spacing: spacing,
              children: [
                if (active && runner != null)
                  TextButton(
                    onPressed: () => unawaited(runner.pause(job.id)),
                    child: Text(l10n.externalJobPause),
                  ),
                if ((job.status == LocalJobStatus.paused ||
                        job.status == LocalJobStatus.failed) &&
                    runner != null)
                  TextButton(
                    onPressed: () => unawaited(runner.resume(job.id)),
                    child: Text(l10n.externalJobResume),
                  ),
                if (job.status != LocalJobStatus.done &&
                    job.status != LocalJobStatus.cancelled &&
                    runner != null)
                  TextButton(
                    onPressed: () => unawaited(runner.cancel(job.id)),
                    child: Text(l10n.cancel),
                  ),
                if (left.isNotEmpty && !active && runner != null)
                  TextButton(
                    onPressed: () => unawaited(runner.deleteOriginals(job.id)),
                    child: Text(l10n.externalDeleteOriginals),
                  ),
                TextButton(
                  onPressed: () => unawaited(_showLog(context)),
                  child: Text(l10n.externalJobDetails),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLog(BuildContext context) {
    final l10n = context.l10n;
    final lines = <String>[
      for (final f in view.renamed)
        l10n.externalRenamedForDrive(f.originalName, f.targetName),
      for (final f in view.files)
        if (localFileReason(l10n, f) case final reason?)
          l10n.externalLogLine(f.originalName, reason),
    ];
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.externalJobDetails),
        content: SizedBox(
          width: double.maxFinite,
          child: lines.isEmpty
              ? Text(l10n.externalJobDone)
              : ListView(
                  shrinkWrap: true,
                  children: [for (final l in lines) Text(l)],
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(MaterialLocalizations.of(context).closeButtonLabel),
          ),
        ],
      ),
    );
  }
}
