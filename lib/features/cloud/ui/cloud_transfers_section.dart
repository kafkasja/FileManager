import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/features/cloud/data/cloud_destinations_repository.dart';
import 'package:kfm/features/cloud/data/cloud_items_repository.dart';
import 'package:kfm/features/cloud/data/cloud_providers.dart';
import 'package:kfm/features/cloud/domain/cloud_destination.dart';
import 'package:kfm/features/cloud/ui/cloud_labels.dart';
import 'package:kfm/features/cloud/ui/cloud_send_flow.dart';

/// X3's "Cloud" tab on the Transfers page: one row per file of the last 7
/// days with its destination, progress while saving, status, Cancel /
/// Retry, and "Delete originals" for verified moves whose originals are
/// still there.
class CloudTransfersSection extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final rows = ref.watch(cloudRecentItemsProvider).value ?? const [];
    final dests =
        ref.watch(cloudDestinationsByIdProvider).value ??
        const <int, CloudDestination>{};
    final progress = ref.watch(cloudProgressProvider).value ?? const {};
    final runner = ref.watch(cloudUploadRunnerProvider);
    if (rows.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsetsDirectional.all(spacing * 2),
          child: Text(l10n.cloudTransfersEmpty, textAlign: TextAlign.center),
        ),
      );
    }
    final left = [
      for (final r in rows)
        if (cloudOriginalLeft(r) && !(runner?.inRunningJob(r.id) ?? false)) r,
    ];
    return ListView(
      padding: EdgeInsetsDirectional.all(spacing),
      children: [
        if (left.isNotEmpty && runner != null)
          Padding(
            padding: EdgeInsetsDirectional.all(spacing),
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.tonal(
                key: const ValueKey('cloud-delete-originals'),
                onPressed: () => unawaited(
                  _deleteOriginals(context, ref, [for (final r in left) r.id]),
                ),
                child: Text(l10n.cloudDeleteOriginals),
              ),
            ),
          ),
        for (final r in rows)
          _CloudRowTile(
            row: r,
            label: dests[r.destinationId]?.label ?? '',
            provider:
                dests[r.destinationId]?.provider ?? CloudProviderGuess.other,
            bytes: progress[r.id],
          ),
      ],
    );
  }

  Future<void> _deleteOriginals(
    BuildContext context,
    WidgetRef ref,
    List<int> ids,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final runner = ref.read(cloudUploadRunnerProvider);
    if (runner == null) return;
    try {
      final s = await runner.deleteOriginals(ids);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            s.kept > 0
                ? l10n.cloudOriginalsKept(s.kept)
                : l10n.cloudOriginalsDeleted(s.deleted),
          ),
        ),
      );
    } on Object catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

class _CloudRowTile extends ConsumerWidget {
  const new({
    required this.row,
    required this.label,
    required this.provider,
    required this.bytes,
  });

  final CloudItemRow row;
  final String label;
  final CloudProviderGuess provider;
  final int? bytes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final outcome = cloudOutcomeText(l10n, row);
    final status = cloudStatusText(l10n, row, label);
    final uploading = row.status == CloudItemStatus.uploading;
    final active = uploading || row.status == CloudItemStatus.queued;
    final done = bytes;
    return ListTile(
      key: ValueKey('cloud-row-${row.id}'),
      leading: Icon(cloudProviderIcon(provider)),
      title: Text(row.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(outcome == null ? status : '$status · $outcome'),
          if (uploading)
            LinearProgressIndicator(
              value: done == null || row.sizeBytes <= 0
                  ? null
                  : (done / row.sizeBytes).clamp(0, 1).toDouble(),
            ),
        ],
      ),
      trailing: active
          ? IconButton(
              key: ValueKey('cloud-cancel-${row.id}'),
              tooltip: l10n.cancel,
              icon: const Icon(Icons.close),
              onPressed: () => unawaited(
                ref.read(cloudUploadRunnerProvider)?.cancel(row.id),
              ),
            )
          : row.status == CloudItemStatus.failed &&
                row.error != CloudItemErrors.destinationRemoved
          ? IconButton(
              key: ValueKey('cloud-retry-${row.id}'),
              tooltip: l10n.cloudRetry,
              icon: const Icon(Icons.refresh),
              onPressed: () => unawaited(_retry(context, ref)),
            )
          : null,
    );
  }

  /// Retry = the same file to the same destination again (the same
  /// questions as a new copy/move).
  Future<void> _retry(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    try {
      final file = await ref.read(fileSourceProvider).stat(row.fileId);
      if (file == null) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.cloudSourceGone)));
        return;
      }
      if (!context.mounted) return;
      await startCloudJobFlow(
        context,
        ref,
        [file],
        row.destinationId,
        move: row.mode == CloudItemMode.move,
      );
    } on FileOpException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}
