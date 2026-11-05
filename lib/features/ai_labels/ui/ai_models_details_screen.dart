import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/app_info.dart';
import 'package:kfm/app/device_kind.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/features/ai_labels/data/ai_labels_providers.dart';
import 'package:kfm/features/ai_labels/data/ai_model_manifest.dart';
import 'package:kfm/features/ai_labels/data/ai_model_store.dart';
import 'package:kfm/features/ai_labels/ui/ai_model_state_text.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// Megabytes (10^6) for the size strings.
double megabytes(int bytes) => bytes / 1000000;

/// TASK-C3 §8: what the two models are, where they come from and what
/// happens on the phone, shown before any download. Nothing is downloaded
/// until **Download** is tapped.
class AiModelsDetailsScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<AiModelsDetailsScreen> createState() =>
      _AiModelsDetailsScreenState();
}

class _AiModelsDetailsScreenState extends ConsumerState<AiModelsDetailsScreen> {
  Future<void> _download({bool useMobileData = false}) async {
    final ok = await ref
        .read(aiLabelsControllerProvider)
        .download(useMobileData: useMobileData);
    if (!mounted || !ok) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.aiModelsInstalledDone)));
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final space = context.tokens.spacing;
    final theme = Theme.of(context);
    final support = ref.watch(aiSupportProvider).value;
    final manifest = ref.watch(aiModelStoreProvider).value?.manifest;
    final state = ref.watch(aiModelStateProvider).value;
    final wifiOnly = ref.watch(aiModelsWifiOnlyProvider).value ?? true;

    Widget section(String title, String body) => Padding(
      padding: EdgeInsetsDirectional.only(top: space * 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          SizedBox(height: space / 2),
          Text(body),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aiModelsTitle)),
      body: ListView(
        padding: EdgeInsetsDirectional.all(space * 2),
        children: [
          Text(l10n.aiModelsDetailsIntro),
          if (manifest != null)
            for (final m in manifest.models) _ModelCard(model: m),
          section(
            l10n.aiModelsHowTitle,
            l10n.aiModelsHowBodyOn(deviceKind(context)),
          ),
          section(
            l10n.aiModelsPrivacyTitle,
            '${l10n.aiModelsPrivacyBodyOn(deviceKind(context))}\n\n${l10n.aiModelsBatteryBody}\n\n'
            '${l10n.aiModelsRemovableBody}',
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () => showLicensePage(
                context: context,
                applicationName: l10n.appTitle,
                applicationVersion: appVersion,
              ),
              child: Text(l10n.aiModelsLicences),
            ),
          ),
          SizedBox(height: space * 2),
          if (support != null && support != AiSupport.supported)
            Text(
              support == AiSupport.needsAndroid8
                  ? l10n.aiLabelsNeedsAndroid8
                  : l10n.aiLabelsUnsupported,
              style: TextStyle(color: theme.colorScheme.error),
            )
          else if (manifest != null)
            _Actions(
              state: state,
              totalBytes: manifest.totalBytes,
              wifiOnly: wifiOnly,
              onDownload: _download,
            ),
        ],
      ),
    );
  }
}

class _Actions extends ConsumerWidget {
  const new({
    required this.state,
    required this.totalBytes,
    required this.wifiOnly,
    required this.onDownload,
  });

  final AiModelState? state;
  final int totalBytes;
  final bool wifiOnly;
  final Future<void> Function({bool useMobileData}) onDownload;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final space = context.tokens.spacing;
    final theme = Theme.of(context);
    final s = state;
    final busy =
        s is AiModelsDownloading ||
        s is AiModelsVerifying ||
        s is AiModelsWaitingForWifi;
    final controller = ref.read(aiLabelsControllerProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (s != null && s is! AiModelsNotInstalled)
          Padding(
            padding: EdgeInsetsDirectional.only(bottom: space),
            child: Text(
              aiModelStateText(l10n, s, totalBytes: totalBytes),
              style: s is AiModelsFailed
                  ? TextStyle(color: theme.colorScheme.error)
                  : null,
            ),
          ),
        if (s is AiModelsDownloading)
          Padding(
            padding: EdgeInsetsDirectional.only(bottom: space),
            child: LinearProgressIndicator(
              value: s.totalBytes == 0 ? null : s.doneBytes / s.totalBytes,
            ),
          ),
        if (busy) ...[
          if (s is AiModelsWaitingForWifi)
            OutlinedButton(
              onPressed: () async {
                await controller.cancelDownload();
                await onDownload(useMobileData: true);
              },
              child: Text(l10n.aiModelsUseMobileData),
            ),
          TextButton(
            onPressed: () => unawaited(controller.cancelDownload()),
            child: Text(l10n.aiModelsCancel),
          ),
        ] else if (s is! AiModelsInstalled) ...[
          if (wifiOnly)
            Padding(
              padding: EdgeInsetsDirectional.only(bottom: space),
              child: Text(
                l10n.aiModelsWillUseWifi,
                style: theme.textTheme.bodySmall,
              ),
            ),
          FilledButton(
            onPressed: s == null || s is AiModelsChecking
                ? null
                : () => unawaited(onDownload()),
            child: Text(
              s is AiModelsFailed
                  ? l10n.aiModelsRetry
                  : l10n.aiModelsDownloadButton(megabytes(totalBytes)),
            ),
          ),
          if (wifiOnly)
            TextButton(
              onPressed: s == null || s is AiModelsChecking
                  ? null
                  : () => unawaited(onDownload(useMobileData: true)),
              child: Text(l10n.aiModelsUseMobileData),
            ),
          TextButton(
            onPressed: () {
              if (context.canPop()) context.pop();
            },
            child: Text(l10n.aiCancel),
          ),
        ],
      ],
    );
  }
}

class _ModelCard extends StatelessWidget {
  const new({required this.model});

  final AiModelEntry model;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final space = context.tokens.spacing;
    final theme = Theme.of(context);
    final (what, use) = _texts(l10n, model.id);
    return Card(
      margin: EdgeInsetsDirectional.only(top: space * 2),
      child: Padding(
        padding: EdgeInsetsDirectional.all(space * 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(model.name, style: theme.textTheme.titleMedium),
            SizedBox(height: space / 2),
            Text(what),
            SizedBox(height: space / 2),
            Text(use),
            SizedBox(height: space),
            for (final line in [
              l10n.aiModelSize(megabytes(model.sizeBytes)),
              l10n.aiModelPublisher(model.publisher),
              l10n.aiModelLicence(model.licence),
              l10n.aiModelOriginal(model.sourceUrl),
              l10n.aiModelSource(model.url),
            ])
              Text(line, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  static (String, String) _texts(AppLocalizations l10n, String id) =>
      switch (id) {
        'detector' => (l10n.aiModelDetectorWhat, l10n.aiModelDetectorUse),
        _ => (l10n.aiModelClassifierWhat, l10n.aiModelClassifierUse),
      };
}
