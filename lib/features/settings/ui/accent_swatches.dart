import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_theme.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/app/theme/theme_providers.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// L1: one round swatch per color theme; tapping applies it live. "System
/// colors" shows only when the device has a wallpaper palette.
class AccentSwatches extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final systemSeed = ref.watch(systemAccentSeedProvider).value;
    final stored = ref.watch(themeAccentProvider).value ?? AppAccent.blue;
    // What the app actually shows (System without a palette is blue).
    final selected = stored == AppAccent.system && systemSeed == null
        ? AppAccent.blue
        : stored;
    final accents = [
      for (final a in AppAccent.values)
        if (a != AppAccent.system || systemSeed != null) a,
    ];

    return Padding(
      padding: EdgeInsetsDirectional.symmetric(horizontal: spacing * 2),
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final a in accents)
            _Swatch(
              key: ValueKey(a),
              label: _label(l10n, a),
              scheme: accentScheme(
                Theme.of(context).brightness,
                seed: accentSeed(a, systemSeed: systemSeed),
                monochrome: a == AppAccent.mono,
              ),
              isSystem: a == AppAccent.system,
              selected: a == selected,
              onTap: () => ref
                  .read(settingsRepositoryProvider)
                  .write(AppSettings.themeAccent, a)
                  .fireAndForget(),
            ),
        ],
      ),
    );
  }

  static String _label(AppLocalizations l10n, AppAccent a) => switch (a) {
    AppAccent.blue => l10n.accentBlue,
    AppAccent.green => l10n.accentGreen,
    AppAccent.purple => l10n.accentPurple,
    AppAccent.orange => l10n.accentOrange,
    AppAccent.mono => l10n.accentMono,
    AppAccent.system => l10n.accentSystem,
  };
}

class _Swatch extends StatelessWidget {
  const new({
    required this.label,
    required this.scheme,
    required this.isSystem,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final ColorScheme scheme;
  final bool isSystem;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ring = Theme.of(context).colorScheme.onSurface;
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: InkResponse(
          onTap: onTap,
          radius: 24,
          child: SizedBox.square(
            dimension: 48,
            child: Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                  border: selected ? Border.all(color: ring, width: 3) : null,
                ),
                child: selected
                    ? Icon(Icons.check, color: scheme.onPrimary, size: 20)
                    : isSystem
                    ? Icon(
                        Icons.wallpaper_outlined,
                        color: scheme.onPrimary,
                        size: 18,
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
