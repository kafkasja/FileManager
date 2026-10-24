import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/features/presets/data/preset_repository.dart';
import 'package:kfm/features/reviewed/data/reviewed_repository.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';

/// P7 "Reset reviewed labels…": pick Basic, a preset or all; confirm.
Future<void> showResetReviewedDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final l10n = context.l10n;
  final counts = await ref.read(reviewedRepositoryProvider).fileCounts();
  final presets = await ref.read(presetsProvider.future);
  if (!context.mounted) return;
  // (key, name); null key = all presets.
  final options = <(int?, String)>[
    (0, l10n.presetBasic),
    for (final p in presets) (p.id, p.name),
    (null, l10n.reviewedResetAll),
  ];
  final picked = await showModalBottomSheet<(int?, String)>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          ListTile(title: Text(l10n.reviewedReset)),
          for (final o in options)
            ListTile(
              title: Text(o.$2),
              subtitle: Text(
                l10n.reviewedResetCount(
                  o.$1 == null
                      ? counts.values.fold(0, (a, b) => a + b)
                      : counts[o.$1] ?? 0,
                ),
              ),
              onTap: () => Navigator.of(context).pop(o),
            ),
        ],
      ),
    ),
  );
  if (picked == null || !context.mounted) return;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(l10n.reviewedResetConfirm(picked.$2)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.reset),
        ),
      ],
    ),
  );
  if (!(ok ?? false) || !context.mounted) return;
  final repo = ref.read(reviewedRepositoryProvider);
  final key = picked.$1;
  await (key == null ? repo.resetAll() : repo.resetPreset(key));
  // Skipped files come back.
  ref.invalidate(swipeDeckControllerProvider);
  if (context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.reviewedResetDone)));
  }
}
