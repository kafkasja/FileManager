import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/features/filters/domain/file_filter.dart';
import 'package:kfm/features/filters/ui/filter_sheet.dart';
import 'package:kfm/features/presets/data/preset_repository.dart';
import 'package:kfm/features/presets/domain/preset.dart';
import 'package:kfm/features/presets/ui/active_preset_controller.dart';
import 'package:kfm/features/presets/ui/preset_modified_provider.dart';
import 'package:kfm/features/swipe/domain/swipe_deck_state.dart';
import 'package:kfm/features/swipe/ui/swipe_setup_sheet.dart';

/// Desktop Sort's setup row (TASK-PL3 polish; replaces the phone's S6
/// strip): a presets dropdown (Basic + each preset, Manage presets…), a
/// filter button and "Sort setup…", which opens the S6 setup (directions,
/// filter, extras, Save / Revert) as a dialog.
class SortSetupBar extends ConsumerWidget {
  const new({required this.deck, super.key});

  final SwipeDeckState deck;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final presets = ref.watch(presetsProvider).value ?? const <PresetEntry>[];
    final activeId = ref.watch(activePresetIdProvider).value ?? 0;
    final name = ref.watch(activePresetEntryProvider)?.name ?? l10n.presetBasic;
    final modified = ref.watch(presetModifiedProvider);
    final busy = ref.watch(activePresetControllerProvider).isLoading;
    ref.listen(activePresetControllerProvider, (_, next) {
      final error = next.error;
      if (next.isLoading || error == null) return;
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
    final filterOn =
        deck.source == null &&
        !FileFilter.decode(deck.session.filterJson).isEmpty;

    void switchTo(int? id) => unawaited(
      ref.read(activePresetControllerProvider.notifier).switchTo(id),
    );

    MenuItemButton item(String label, int? id, {bool broken = false}) =>
        MenuItemButton(
          key: ValueKey('sort-preset-${id ?? 0}'),
          leadingIcon: Icon(
            (id ?? 0) == activeId ? Icons.check : null,
            size: 18,
          ),
          onPressed: broken ? null : () => switchTo(id),
          child: Text(broken ? l10n.swipeSetupPresetBroken : label),
        );

    return Material(
      color: scheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          children: [
            MenuAnchor(
              menuChildren: [
                item(l10n.presetBasic, null),
                for (final p in presets)
                  item(p.name, p.id, broken: p is PresetLoadError),
                const Divider(height: 8),
                MenuItemButton(
                  key: const ValueKey('sort-presets-manage'),
                  leadingIcon: const Icon(Icons.tune, size: 18),
                  onPressed: () =>
                      unawaited(GoRouter.of(context).push(AppRoutes.presets)),
                  child: Text(l10n.desktopSortManagePresets),
                ),
              ],
              builder: (context, menu, _) => TextButton.icon(
                key: const ValueKey('sort-preset-dropdown'),
                onPressed: busy
                    ? null
                    : () => menu.isOpen ? menu.close() : menu.open(),
                icon: const Icon(Icons.bookmarks_outlined, size: 18),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: Text(
                        l10n.desktopSortPreset(name),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        semanticsLabel: modified
                            ? l10n.swipeSetupPresetModifiedSemantics(name)
                            : l10n.swipeSetupPresetSemantics(name),
                      ),
                    ),
                    if (modified)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 6),
                        child: Container(
                          key: const ValueKey('preset-modified-dot'),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: scheme.tertiary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    const Icon(Icons.arrow_drop_down, size: 20),
                  ],
                ),
              ),
            ),
            if (deck.source == null)
              TextButton.icon(
                key: const ValueKey('sort-filter'),
                onPressed: () => unawaited(showFilterSheet(context)),
                icon: filterOn
                    ? const Badge(
                        smallSize: 8,
                        child: Icon(Icons.filter_list, size: 18),
                      )
                    : const Icon(Icons.filter_list, size: 18),
                label: Text(
                  filterOn ? l10n.swipeSetupFilterOn : l10n.filterTitle,
                ),
              ),
            TextButton.icon(
              key: const ValueKey('sort-setup'),
              onPressed: () => unawaited(
                showSwipeSetupSheet(
                  context,
                  initialSection: SwipeSetupSection.directions,
                ),
              ),
              icon: const Icon(Icons.settings_outlined, size: 18),
              label: Text(l10n.desktopSortSetup),
            ),
          ],
        ),
      ),
    );
  }
}
