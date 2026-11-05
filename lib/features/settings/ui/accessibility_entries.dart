import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/form_factor.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/layout/handed.dart';
import 'package:kfm/app/layout/segment_label.dart';
import 'package:kfm/app/layout/text_scale.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/features/settings/ui/settings_section.dart';
import 'package:kfm/features/settings/ui/widgets/settings_tiles.dart';

/// Settings → Accessibility (TASK-E2): text size (L5), left-handed (L4).
final textSizeEntry = SettingsEntry(
  id: 'a11y.textSize',
  titleBuilder: (c) => c.l10n.textSizeLabel,
  keywordsBuilder: (c) => c.l10n.settingsKeywordsTextSize,
  selfExplanatory: true,
  builder: (_) => const TextSizeRow(),
);

/// Thumb-side controls; desktop has no thumb (TASK-E2 §7).
final leftHandedEntry = SettingsEntry(
  id: 'a11y.leftHanded',
  titleBuilder: (c) => c.l10n.leftHandedTitle,
  subtitleBuilder: (c) => c.l10n.leftHandedSubtitle,
  formFactors: const {FormFactor.mobile},
  builder: (_) => const LeftHandedRow(),
);

/// What TalkBack / Narrator read on file tiles (E2 §7).
final screenReaderEntry = SettingsEntry(
  id: 'a11y.screenReader',
  titleBuilder: (c) => c.l10n.a11yScreenReaderTitle,
  subtitleBuilder: (c) => c.l10n.a11yScreenReaderBody,
  keywordsBuilder: (c) => c.l10n.settingsKeywordsScreenReader,
  builder: (c) => ListTile(
    leading: const Icon(Icons.record_voice_over_outlined),
    title: Text(c.l10n.a11yScreenReaderTitle),
    subtitle: Text(c.l10n.a11yScreenReaderBody),
  ),
);

class LeftHandedRow extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => SettingsSwitchTile(
    icon: Icons.back_hand_outlined,
    title: context.l10n.leftHandedTitle,
    subtitle: context.l10n.leftHandedSubtitle,
    value: handednessOf(ref) == Handedness.left,
    onChanged: (v) => ref
        .read(settingsRepositoryProvider)
        .write(AppSettings.leftHanded, v)
        .fireAndForget(),
  );
}

/// System / Large / Extra large, with a preview line.
class TextSizeRow extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.read(settingsRepositoryProvider);
    final size = ref.watch(textSizeProvider).value ?? AppTextSize.system;
    final spacing = context.tokens.spacing;

    // The preview applies the chosen size to the platform scaler itself, so
    // it never stacks on the factor the app may already have applied.
    final ambient = MediaQuery.textScalerOf(context);
    final base = ambient is AppTextScaler ? ambient.base : ambient;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: const Icon(Icons.format_size),
          title: Text(l10n.textSizeLabel),
        ),
        Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: spacing * 2),
          child: SegmentedButton<AppTextSize>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: AppTextSize.system,
                label: SegmentLabel(l10n.textSizeSystem),
              ),
              ButtonSegment(
                value: AppTextSize.large,
                label: SegmentLabel(l10n.textSizeLarge),
              ),
              ButtonSegment(
                value: AppTextSize.extraLarge,
                label: SegmentLabel(l10n.textSizeExtraLarge),
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
