import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/device_kind.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/features/ai_labels/data/ai_labels_providers.dart';

/// "Find photos by what's in them" (TASK-C3 §7): shown in Browse's image
/// view and the search screen while labeling is off and not dismissed.
/// Hidden where labeling can't run (API < 26, no runtime).
class AiLabelsCard extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supported = ref.watch(aiSupportProvider).value == AiSupport.supported;
    final enabled = ref.watch(aiLabelsEnabledProvider).value;
    final dismissed = ref.watch(aiLabelsCardDismissedProvider).value;
    if (!supported || enabled != false || dismissed != false) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final space = context.tokens.spacing;
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsetsDirectional.symmetric(
        horizontal: space * 2,
        vertical: space,
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.all(space * 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(width: space),
                Expanded(
                  child: Text(
                    l10n.aiLabelsCardTitle,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            SizedBox(height: space),
            Text(
              l10n.aiLabelsCardBodyOn(deviceKind(context)),
              style: theme.textTheme.bodySmall,
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Wrap(
                spacing: space,
                children: [
                  TextButton(
                    onPressed: () => unawaited(
                      ref.read(aiLabelsControllerProvider).dismissCard(),
                    ),
                    child: Text(l10n.aiLabelsCardNotNow),
                  ),
                  FilledButton(
                    onPressed: () => unawaited(turnOnAiLabels(context, ref)),
                    child: Text(l10n.aiLabelsCardTurnOn),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Turn on: models installed → labeling on; otherwise the details screen
/// (its Download button is the consent).
Future<void> turnOnAiLabels(BuildContext context, WidgetRef ref) async {
  final result = await ref.read(aiLabelsControllerProvider).turnOn();
  if (!context.mounted) return;
  switch (result) {
    case TurnOnResult.enabled:
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.aiLabelsTurnedOn)));
    case TurnOnResult.needsDownload:
      // E2 §5: the download lives in Settings → Smart features.
      context.go(AppRoutes.settingsEntry('smart.aiLabels'));
    case TurnOnResult.unsupported:
      break;
  }
}
