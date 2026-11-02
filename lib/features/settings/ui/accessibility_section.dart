import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/layout/handed.dart';
import 'package:kfm/app/layout/text_scale.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';

/// Left-handed mode (L4) + text size (L5).
class AccessibilitySection extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.read(settingsRepositoryProvider);
    final left = handednessOf(ref) == Handedness.left;
    final size = ref.watch(textSizeProvider).value ?? AppTextSize.system;
    final spacing = context.tokens.spacing;

    // The preview applies the chosen size to the platform scaler itself, so
    // it never stacks on the factor the app may already have applied.
    final ambient = MediaQuery.textScalerOf(context);
    final base = ambient is AppTextScaler ? ambient.base : ambient;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          title: Text(l10n.leftHandedTitle),
          subtitle: Text(l10n.leftHandedSubtitle),
          value: left,
          onChanged: (v) =>
              settings.write(AppSettings.leftHanded, v).fireAndForget(),
        ),
        ListTile(title: Text(l10n.textSizeLabel)),
        Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: spacing * 2),
          child: SegmentedButton<AppTextSize>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: AppTextSize.system,
                label: Text(l10n.textSizeSystem),
              ),
              ButtonSegment(
                value: AppTextSize.large,
                label: Text(l10n.textSizeLarge),
              ),
              ButtonSegment(
                value: AppTextSize.extraLarge,
                label: Text(l10n.textSizeExtraLarge),
              ),
            ],
            selected: {size},
            onSelectionChanged: (s) =>
                settings.write(AppSettings.textSize, s.single).fireAndForget(),
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.all(spacing * 2),
          child: Text(
            l10n.textSizePreview,
            key: const ValueKey('text-size-preview'),
            style: Theme.of(context).textTheme.bodyLarge,
            textScaler: textScalerFor(base, size),
          ),
        ),
      ],
    );
  }
}
