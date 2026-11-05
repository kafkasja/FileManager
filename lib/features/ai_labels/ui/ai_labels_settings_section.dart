import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/features/ai_labels/data/ai_labels_providers.dart';
import 'package:kfm/features/ai_labels/data/ai_model_store.dart';
import 'package:kfm/features/ai_labels/data/labeling_job.dart';
import 'package:kfm/features/ai_labels/ui/ai_model_state_text.dart';
import 'package:kfm/features/ai_labels/ui/ai_models_details_screen.dart';
import 'package:kfm/features/settings/ui/settings_section.dart';

/// Settings → Smart features → Photo labels (AI) (TASK-C3 §7, E2 §5).
/// Never hidden: where labels can't run, the row says why.
final aiLabelsEntry = SettingsEntry(
  id: 'smart.aiLabels',
  titleBuilder: (c) => c.l10n.aiLabelsTitle,
  subtitleBuilder: (c) => c.l10n.aiLabelsEnableHint,
  keywordsBuilder: (c) => c.l10n.settingsKeywordsAiLabels,
  builder: (_) => const AiLabelsSettingsSection(),
);

/// Settings → Photo labels (AI) (TASK-C3 §7).
class AiLabelsSettingsSection extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final support = ref.watch(aiSupportProvider).value;
    if (support == null) return const SizedBox.shrink();
    if (support != AiSupport.supported) {
      return ListTile(
        leading: const Icon(Icons.auto_awesome_outlined),
        title: Text(l10n.aiLabelsEnable),
        subtitle: Text(
          support == AiSupport.needsAndroid8
              ? l10n.aiLabelsNeedsAndroid8
              : l10n.aiLabelsUnsupported,
        ),
        enabled: false,
      );
    }
    return const _Supported();
  }
}

class _Supported extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final controller = ref.read(aiLabelsControllerProvider);
    final total = ref.watch(aiModelStoreProvider).value?.manifest.totalBytes;
    final state =
        ref.watch(aiModelStateProvider).value ?? const AiModelsChecking();
    final enabled = ref.watch(aiLabelsEnabledProvider).value ?? false;
    final paused = ref.watch(aiLabelsPausedProvider).value ?? false;
    final wifiOnly = ref.watch(aiModelsWifiOnlyProvider).value ?? true;
    final progress = ref.watch(labelingProgressProvider).value;
    final failed = ref.watch(labelingFailedCountProvider).value ?? 0;
    final jobError = ref.watch(labelingJobErrorsProvider).value;
    final installed = state is AiModelsInstalled;
    final downloading =
        state is AiModelsDownloading ||
        state is AiModelsVerifying ||
        state is AiModelsWaitingForWifi;
    final hasFiles =
        installed ||
        (state is AiModelsNotInstalled && state.partialBytes > 0) ||
        (state is AiModelsFailed && state.partialBytes > 0);
    final errorStyle = TextStyle(color: theme.colorScheme.error);

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.memory_outlined),
          title: Text(
            aiModelStateText(l10n, state, totalBytes: total ?? 0),
            style: state is AiModelsFailed ? errorStyle : null,
          ),
          subtitle: switch (state) {
            AiModelsDownloading(:final doneBytes, :final totalBytes) =>
              LinearProgressIndicator(
                value: totalBytes == 0 ? null : doneBytes / totalBytes,
              ),
            AiModelsInstalled() => null,
            _ when downloading => null,
            _ => Text(l10n.aiModelsAbout),
          },
          trailing: downloading
              ? TextButton(
                  onPressed: () => unawaited(controller.cancelDownload()),
                  child: Text(l10n.aiModelsCancel),
                )
              : null,
          onTap: installed || downloading
              ? null
              : () => unawaited(context.push(AppRoutes.aiModels)),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.wifi),
          title: Text(l10n.aiModelsWifiOnly),
          value: wifiOnly,
          onChanged: (v) => unawaited(controller.setWifiOnly(on: v)),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.auto_awesome_outlined),
          title: Text(l10n.aiLabelsEnable),
          subtitle: Text(
            installed
                ? l10n.aiLabelsEnableHint
                : l10n.aiLabelsEnableNeedsModels,
          ),
          value: enabled && installed,
          onChanged: installed
              ? (v) => unawaited(controller.setEnabled(on: v))
              : null,
        ),
        if (enabled && installed)
          ListTile(
            leading: Icon(
              paused ? Icons.play_arrow_outlined : Icons.pause_outlined,
            ),
            title: Text(paused ? l10n.aiLabelsResume : l10n.aiLabelsPause),
            subtitle: paused ? Text(l10n.aiLabelsPausedLine) : null,
            onTap: () => unawaited(controller.setPaused(paused: !paused)),
          ),
        if (progress != null && (enabled || progress.processed > 0))
          ListTile(
            leading: const Icon(Icons.label_outline),
            title: Text(
              l10n.aiLabelsProgress(progress.processed, progress.total),
            ),
            subtitle: enabled && !paused && progress.processed < progress.total
                ? LinearProgressIndicator(value: progress.fraction)
                : null,
          ),
        if (failed > 0)
          ListTile(
            leading: const Icon(Icons.report_outlined),
            title: Text(l10n.aiLabelsFailed(failed)),
          ),
        if (jobError != null && enabled)
          ListTile(
            leading: Icon(Icons.error_outline, color: theme.colorScheme.error),
            title: Text(switch (jobError) {
              LabelingJobError.modelsMissing => l10n.aiLabelsJobError,
              LabelingJobError.workerFailed => l10n.aiLabelsWorkerError,
              LabelingJobError.workerCrashed => l10n.aiLabelsCrashError,
            }, style: errorStyle),
            onTap: jobError == LabelingJobError.modelsMissing
                ? () => unawaited(context.push(AppRoutes.aiModels))
                : null,
          ),
        if ((progress != null && progress.processed > 0) || failed > 0)
          ListTile(
            leading: const Icon(Icons.restart_alt),
            title: Text(l10n.aiLabelsReset),
            onTap: () => unawaited(_confirmReset(context, ref)),
          ),
        if (hasFiles && !downloading)
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: Text(l10n.aiModelsRemove),
            onTap: () => unawaited(_confirmRemove(context, ref, total ?? 0)),
          ),
        ListTile(
          dense: true,
          leading: const Icon(Icons.lock_outline),
          title: Text(l10n.aiLabelsHelp),
        ),
      ],
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.aiLabelsResetConfirm),
        content: Text(l10n.aiLabelsResetConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.aiCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.aiLabelsResetAction),
          ),
        ],
      ),
    );
    if (ok ?? false) {
      await ref.read(aiLabelsControllerProvider).resetLabels();
    }
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    int totalBytes,
  ) async {
    final deleteLabels = await showDialog<bool>(
      context: context,
      builder: (_) => _RemoveDialog(totalBytes: totalBytes),
    );
    if (deleteLabels == null) return;
    await ref
        .read(aiLabelsControllerProvider)
        .removeModels(deleteLabels: deleteLabels);
  }
}

/// "Remove AI models (10.0 MB)?" with "Also delete the photo labels"
/// (unchecked by default). Pops the checkbox value, null = cancel.
class _RemoveDialog extends StatefulWidget {
  const new({required this.totalBytes});

  final int totalBytes;

  @override
  State<_RemoveDialog> createState() => _RemoveDialogState();
}

class _RemoveDialogState extends State<_RemoveDialog> {
  bool _labels = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      // Scrolls on short screens (a phone in landscape, big text).
      scrollable: true,
      title: Text(l10n.aiModelsRemoveTitle(megabytes(widget.totalBytes))),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.aiModelsRemoveBody),
          CheckboxListTile(
            contentPadding: EdgeInsetsDirectional.zero,
            value: _labels,
            onChanged: (v) => setState(() => _labels = v ?? false),
            title: Text(l10n.aiModelsRemoveAlsoLabels),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.aiCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_labels),
          child: Text(l10n.aiModelsRemoveConfirm),
        ),
      ],
    );
  }
}
