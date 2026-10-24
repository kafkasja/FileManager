import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/features/session/ui/clear_sheet.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'swipe_settings_section.g.dart';

/// Vibration on swipes (S4), cached so a swipe never waits for the DB.
@Riverpod(keepAlive: true)
Stream<bool> hapticsEnabled(Ref ref) =>
    ref.watch(settingsRepositoryProvider).watch(AppSettings.hapticsEnabled);

/// P4: the optional action bar under the card.
@Riverpod(keepAlive: true)
Stream<bool> actionBarEnabled(Ref ref) =>
    ref.watch(settingsRepositoryProvider).watch(AppSettings.actionBarEnabled);

/// Settings → Swiping (S4; P1/P2 add their options here).
class SwipeSettingsSection extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.swipe_outlined),
          title: Text(l10n.customizeSwipes),
          subtitle: Text(l10n.customizeSwipesHelp),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go(AppRoutes.customizeSwipes),
        ),
        ListTile(
          leading: const Icon(Icons.tune),
          title: Text(l10n.settingsPresets),
          subtitle: Text(l10n.settingsPresetsHelp),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go(AppRoutes.presets),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.vibration),
          title: Text(l10n.settingsHaptics),
          subtitle: Text(l10n.settingsHapticsHelp),
          value: ref.watch(hapticsEnabledProvider).value ?? true,
          onChanged: (v) => ref
              .read(settingsRepositoryProvider)
              .write(AppSettings.hapticsEnabled, v)
              .fireAndForget(),
        ),
        ListTile(
          leading: const Icon(Icons.restart_alt),
          title: Text(l10n.settingsFreshStart),
          onTap: () => showClearSheet(context, ref),
        ),
      ],
    );
  }
}
