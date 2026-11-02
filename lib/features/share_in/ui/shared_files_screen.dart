import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/thumbs/thumbnail.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/features/folders/ui/file_op_flow.dart';
import 'package:kfm/features/share_in/data/share_in_service.dart';
import 'package:kfm/features/share_in/domain/shared_batch.dart';
import 'package:kfm/features/swipe/domain/swipe_source.dart';
import 'package:kfm/features/swipe/ui/swipe_these.dart';
import 'package:kfm/features/transfers/ui/send_flow.dart';

/// TASK-X1: the files another app shared into KFM, with Swipe / Move to /
/// Copy to / Send to. Closing it forgets the batch (copies stay until the
/// 7-day cleanup).
class SharedFilesScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<SharedFilesScreen> createState() => _SharedFilesScreenState();
}

class _SharedFilesScreenState extends ConsumerState<SharedFilesScreen> {
  late final PendingSharedBatch _notifier;
  String? _shownId;

  @override
  void initState() {
    super.initState();
    _notifier = ref.read(pendingSharedBatchProvider.notifier);
  }

  @override
  void dispose() {
    // Later: providers can't change while the tree finalizes.
    final notifier = _notifier;
    final id = _shownId;
    unawaited(Future<void>.microtask(() => notifier.dismissIf(id)));
    super.dispose();
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.swipe);
    }
  }

  Future<void> _cancel() async {
    await _notifier.cancel();
    if (mounted) _close();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(pendingSharedBatchProvider);
    _shownId = state.batchId;
    final batch = state.batch;
    final count = batch.value?.files.length ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          batch.hasValue && batch.value != null
              ? l10n.shareInTitle(count)
              : l10n.swipeSourceOriginSharedIn,
        ),
      ),
      body: switch (batch) {
        AsyncData(:final value?) => _BatchView(batch: value),
        AsyncError(:final error) => _Message(
          text: error is ShareInFailedException && error.noSpace
              ? l10n.shareInNoSpace
              : l10n.shareInFailedAll,
          action: TextButton(onPressed: _close, child: Text(l10n.shareInDone)),
        ),
        AsyncData() when state.batchId == null => _Message(
          text: l10n.shareInEmpty,
          action: TextButton(onPressed: _close, child: Text(l10n.shareInDone)),
        ),
        _ => _Resolving(onCancel: _cancel),
      },
    );
  }
}

class _Message extends StatelessWidget {
  const new({required this.text, required this.action});

  final String text;
  final Widget action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsetsDirectional.all(context.tokens.spacing * 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, textAlign: TextAlign.center),
          SizedBox(height: context.tokens.spacing),
          action,
        ],
      ),
    ),
  );
}

class _Resolving extends ConsumerWidget {
  const new({required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final p = ref.watch(shareInProgressSinkProvider);
    final locale = Localizations.localeOf(context).toString();
    return Center(
      child: Padding(
        padding: EdgeInsetsDirectional.all(context.tokens.spacing * 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (p == null || p.total <= 0)
              const CircularProgressIndicator()
            else
              LinearProgressIndicator(value: p.bytes / p.total),
            SizedBox(height: context.tokens.spacing),
            Text(
              p == null || p.total <= 0
                  ? l10n.shareInPreparing
                  : l10n.shareInCopying(
                      formatBytes(p.bytes, locale: locale),
                      formatBytes(p.total, locale: locale),
                    ),
            ),
            SizedBox(height: context.tokens.spacing),
            TextButton(onPressed: onCancel, child: Text(l10n.shareInCancel)),
          ],
        ),
      ),
    );
  }
}

class _BatchView extends ConsumerWidget {
  const new({required this.batch});

  final SharedBatch batch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final spacing = context.tokens.spacing;
    final locale = Localizations.localeOf(context).toString();
    final files = batch.files;
    final hasCopies = files.any(batch.isCopy);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (batch.failedCount > 0)
          _Note(
            icon: Icons.error_outline,
            text: l10n.shareInFailed(batch.failedCount),
            color: scheme.error,
          ),
        if (hasCopies)
          _Note(
            icon: Icons.info_outline,
            text: l10n.shareInCopyDeleteNote,
            color: scheme.onSurfaceVariant,
          ),
        Expanded(
          child: files.isEmpty
              ? Center(child: Text(l10n.shareInEmpty))
              : ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (context, i) {
                    final f = files[i];
                    final size = formatBytes(f.sizeBytes, locale: locale);
                    return ListTile(
                      leading: SizedBox.square(
                        dimension: 48,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            context.tokens.radius,
                          ),
                          child: Thumbnail(file: f),
                        ),
                      ),
                      title: Text(
                        f.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        batch.isCopy(f)
                            ? l10n.shareInCopiedSubtitle(size)
                            : size,
                      ),
                    );
                  },
                ),
        ),
        if (files.isNotEmpty)
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsetsDirectional.all(spacing),
              child: Wrap(
                spacing: spacing,
                runSpacing: spacing,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: () => _swipe(context, ref, files),
                    icon: const Icon(Icons.swipe_outlined),
                    label: Text(l10n.shareInSwipe),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        moveOrCopyFiles(context, ref, files, copy: false),
                    icon: const Icon(Icons.drive_file_move_outlined),
                    label: Text(l10n.shareInMoveTo),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        moveOrCopyFiles(context, ref, files, copy: true),
                    icon: const Icon(Icons.copy_outlined),
                    label: Text(l10n.shareInCopyTo),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => startSend(context, ref, files),
                    icon: const Icon(Icons.send_to_mobile_outlined),
                    label: Text(l10n.shareInSendToDevice),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _swipe(
    BuildContext context,
    WidgetRef ref,
    List<FileRef> files,
  ) => swipeFileIds(
    context,
    ref,
    ids: [for (final f in files) f.id],
    title: context.l10n.swipeSourceOriginSharedIn,
    origin: SwipeSourceOrigin.sharedIn,
  );
}

class _Note extends StatelessWidget {
  const new({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final spacing = context.tokens.spacing;
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(spacing, spacing, spacing, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          SizedBox(width: spacing),
          Expanded(
            child: Text(text, style: TextStyle(color: color)),
          ),
        ],
      ),
    );
  }
}
