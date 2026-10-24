import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/features/presets/data/preset_repository.dart';
import 'package:kfm/features/presets/domain/preset.dart';
import 'package:kfm/features/presets/ui/active_preset_controller.dart';

/// P6: the active preset in the swipe app bar. Hidden until a preset exists
/// ("simple by default"). Tap → switch sheet.
class PresetChip extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final presets = ref.watch(presetsProvider).value ?? const [];
    if (presets.isEmpty) return const SizedBox.shrink();
    final activeId = ref.watch(activePresetIdProvider).value ?? 0;
    final active = presets.where((p) => p.id == activeId).firstOrNull;
    final busy = ref.watch(activePresetControllerProvider).isLoading;
    ref.listen(activePresetControllerProvider, (_, next) {
      final error = next.error;
      if (next.isLoading || error == null) return;
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
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 4),
      child: ActionChip(
        tooltip: l10n.presetChipTooltip,
        avatar: busy
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.tune, size: 18),
        label: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 110),
          child: Text(
            active?.name ?? l10n.presetBasic,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        onPressed: busy ? null : () => _showSheet(context, ref, activeId),
      ),
    );
  }

  Future<void> _showSheet(
    BuildContext context,
    WidgetRef ref,
    int activeId,
  ) async {
    final chosen = await showModalBottomSheet<_Pick>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _PresetSheet(activeId: activeId),
    );
    if (chosen == null || !context.mounted) return;
    switch (chosen) {
      case _Switch(:final id):
        await ref.read(activePresetControllerProvider.notifier).switchTo(id);
      case _Manage():
        context.go(AppRoutes.presets);
    }
  }
}

sealed class _Pick {
  const new();
}

final class _Switch extends _Pick {
  const new(this.id);

  /// Null = Basic.
  final int? id;
}

final class _Manage extends _Pick {
  const new();
}

class _PresetSheet extends ConsumerWidget {
  const new({required this.activeId});

  final int activeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final presets = ref.watch(presetsProvider).value ?? const [];
    Widget row(String name, int? id, {bool broken = false}) {
      final selected = (id ?? 0) == activeId;
      return ListTile(
        leading: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_off,
        ),
        title: Text(name),
        subtitle: broken ? Text(l10n.presetLoadError) : null,
        onTap: () =>
            Navigator.of(context)
                .pop<_Pick>(broken ? const _Manage() : _Switch(id)),
      );
    }

    return DraggableScrollableSheet(
      expand: false,
      maxChildSize: 0.9,
      builder: (context, scroll) => ListView(
        controller: scroll,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
            child: Text(
              l10n.presetSheetTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          row(l10n.presetBasic, null),
          for (final p in presets)
            row(p.name, p.id, broken: p is PresetLoadError),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(l10n.presetManage),
            onTap: () => Navigator.of(context).pop<_Pick>(const _Manage()),
          ),
        ],
      ),
    );
  }
}
