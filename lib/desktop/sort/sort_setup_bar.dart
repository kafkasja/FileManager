import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/desktop/shell/desktop_command_bar.dart';
import 'package:kfm/features/filters/domain/file_filter.dart';
import 'package:kfm/features/filters/ui/filter_sheet.dart';
import 'package:kfm/features/presets/data/preset_repository.dart';
import 'package:kfm/features/presets/domain/preset.dart';
import 'package:kfm/features/presets/ui/active_preset_controller.dart';
import 'package:kfm/features/presets/ui/preset_modified_provider.dart';
import 'package:kfm/features/swipe/domain/swipe_deck_state.dart';
import 'package:kfm/features/swipe/ui/swipe_setup_sheet.dart';

/// Desktop Sort's setup commands (TASK-PL3 polish, E3: in the shell's
/// command bar): the presets menu (Basic + each preset, Manage presets…),
/// Filter and "Sort setup…" (the S6 setup as a dialog).
List<DesktopCommand> sortSetupCommands(
  BuildContext context,
  WidgetRef ref,
  SwipeDeckState deck,
) {
  final l10n = context.l10n;
  final presets = ref.watch(presetsProvider).value ?? const <PresetEntry>[];
  final activeId = ref.watch(activePresetIdProvider).value ?? 0;
  final name = ref.watch(activePresetEntryProvider)?.name ?? l10n.presetBasic;
  final modified = ref.watch(presetModifiedProvider);
  final busy = ref.watch(activePresetControllerProvider).isLoading;
  final filterOn =
      deck.source == null &&
      !FileFilter.decode(deck.session.filterJson).isEmpty;

  void switchTo(int? id) =>
      unawaited(ref.read(activePresetControllerProvider.notifier).switchTo(id));

  DesktopCommand item(String label, int? id, {bool broken = false}) =>
      DesktopCommand(
        id: 'sort-preset-${id ?? 0}',
        key: ValueKey('sort-preset-${id ?? 0}'),
        label: broken ? l10n.swipeSetupPresetBroken : label,
        icon: Icons.bookmark_outline,
        selected: (id ?? 0) == activeId,
        onPressed: broken ? null : () => switchTo(id),
      );

  return [
    DesktopCommand(
      id: 'sort-preset',
      key: const ValueKey('sort-preset-dropdown'),
      label: l10n.desktopSortPreset(name),
      icon: Icons.bookmarks_outlined,
      badge: modified,
      keepLabel: true,
      menu: busy
          ? const []
          : [
              item(l10n.presetBasic, null),
              for (final p in presets)
                item(p.name, p.id, broken: p is PresetLoadError),
              DesktopCommand(
                id: 'sort-presets-manage',
                key: const ValueKey('sort-presets-manage'),
                label: l10n.desktopSortManagePresets,
                icon: Icons.tune,
                divider: true,
                onPressed: () =>
                    unawaited(GoRouter.of(context).push(AppRoutes.presets)),
              ),
            ],
    ),
    if (deck.source == null)
      DesktopCommand(
        id: 'sort-filter',
        key: const ValueKey('sort-filter'),
        label: filterOn ? l10n.swipeSetupFilterOn : l10n.filterTitle,
        icon: Icons.filter_list,
        badge: filterOn,
        onPressed: () => unawaited(showFilterSheet(context)),
      ),
    DesktopCommand(
      id: 'sort-setup',
      key: const ValueKey('sort-setup'),
      label: l10n.desktopSortSetup,
      icon: Icons.settings_outlined,
      onPressed: () => unawaited(
        showSwipeSetupSheet(
          context,
          initialSection: SwipeSetupSection.directions,
        ),
      ),
    ),
  ];
}

/// A preset switch that failed says why (was in the PL3 setup row).
void listenPresetSwitchErrors(BuildContext context, WidgetRef ref) {
  ref.listen(activePresetControllerProvider, (_, next) {
    final error = next.error;
    if (next.isLoading || error == null) return;
    final l10n = context.l10n;
    final active = ref.read(activePresetEntryProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error is PresetSwitchBlocked
              ? l10n.presetSwitchBlocked(active?.name ?? l10n.presetBasic)
              : l10n.swipeErrorGeneric,
        ),
      ),
    );
  });
}
