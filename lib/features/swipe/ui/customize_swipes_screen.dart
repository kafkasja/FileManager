import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/features/folders/ui/folder_picker_sheet.dart';
import 'package:kfm/features/presets/data/preset_repository.dart';
import 'package:kfm/features/presets/ui/save_preset_dialog.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/swipe/domain/action_label.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/ui/swipe_layout_controller.dart';
import 'package:kfm/features/swipe/ui/swipe_settings_section.dart';
import 'package:kfm/features/tags/data/tag_providers.dart';
import 'package:kfm/features/tags/domain/tag.dart';
import 'package:kfm/features/tags/ui/tag_picker_sheet.dart';
import 'package:kfm/features/trash/data/trash_providers.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// Settings → Swiping → Customize swipes (TASK-P1): one action per
/// direction. Directions are physical, never mirrored for RTL.
class CustomizeSwipesScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final layout = ref.watch(swipeLayoutControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.customizeSwipes)),
      body: switch (layout) {
        AsyncData(:final value) => _Body(layout: value),
        AsyncError(:final error) => Center(child: Text(error.toString())),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _Body extends ConsumerWidget {
  const new({required this.layout});

  final SwipeLayout layout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final colors = Theme.of(context).colorScheme;
    Widget tile(SwipeDirection d) => _DirectionTile(
      direction: d,
      action: layout.actionFor(d),
      onTap: () => _pick(context, ref, d),
    );

    return ListView(
      padding: EdgeInsetsDirectional.all(spacing * 2),
      children: [
        Text(l10n.customizeSwipesIntro),
        SizedBox(height: spacing * 2),
        Center(child: SizedBox(width: 180, child: tile(SwipeDirection.up))),
        SizedBox(height: spacing),
        Row(
          // Physical directions: left stays left in RTL languages too.
          textDirection: TextDirection.ltr,
          children: [
            Expanded(child: tile(SwipeDirection.left)),
            SizedBox(width: spacing),
            Container(
              width: 88,
              height: 120,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.photo_outlined, color: colors.outline),
            ),
            SizedBox(width: spacing),
            Expanded(child: tile(SwipeDirection.right)),
          ],
        ),
        SizedBox(height: spacing),
        Center(child: SizedBox(width: 180, child: tile(SwipeDirection.down))),
        SizedBox(height: spacing * 3),
        _ActionBarSection(
          layout: layout,
          onAdd: () => _addBarAction(context, ref),
        ),
        SizedBox(height: spacing * 2),
        // P6: keep this setup as a preset (doesn't switch to it).
        Center(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.bookmark_add_outlined),
            label: Text(l10n.presetSaveAs),
            onPressed: () => _saveAsPreset(context, ref),
          ),
        ),
        SizedBox(height: spacing),
        if (layout != SwipeLayout.basic)
          Center(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.restart_alt),
              label: Text(l10n.swipeLayoutReset),
              onPressed: () => _confirmReset(context, ref),
            ),
          ),
      ],
    );
  }

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    SwipeDirection direction,
  ) async {
    final current = layout.actionFor(direction);
    final picked = await pickSwipeAction(
      context,
      title: swipeDirectionName(context.l10n, direction),
      current: current,
      // The last mapped direction can't become "nothing": the deck would be
      // stuck with no way to swipe.
      canPickNothing: !(current != null && layout.directions.length == 1),
    );
    if (picked == null || picked.action == current) return;
    await ref
        .read(swipeLayoutControllerProvider.notifier)
        .setDirection(direction, picked.action);
  }

  Future<void> _saveAsPreset(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final session = await ref.read(sessionRepositoryProvider).active();
    if (!context.mounted) return;
    final id = await showSavePresetDialog(
      context,
      layout: layout,
      filterJson: session?.filterJson,
    );
    if (id == null) return;
    final saved = await ref.read(presetRepositoryProvider).byId(id);
    if (saved != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.presetSaved(saved.name))),
      );
    }
  }

  /// P4: "Add action" for the action bar.
  Future<void> _addBarAction(BuildContext context, WidgetRef ref) async {
    final action = (await pickSwipeAction(
      context,
      title: context.l10n.actionBarAdd,
      showNothing: false,
      disabledTypes: barTypesInUse(layout),
    ))?.action;
    if (action == null) return;
    await ref.read(swipeLayoutControllerProvider.notifier).addBarAction(action);
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.swipeLayoutResetTitle),
        content: Text(l10n.swipeLayoutResetBody),
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
    if (ok ?? false) {
      await ref.read(swipeLayoutControllerProvider.notifier).resetToBasic();
    }
  }
}

/// The picked option; `type` null = nothing.
typedef _Choice = ({SwipeActionType? type});

class _DirectionTile extends ConsumerWidget {
  const new({
    required this.direction,
    required this.action,
    required this.onTap,
  });

  final SwipeDirection direction;
  final SwipeAction? action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final tags = ref.watch(tagsByIdProvider).value ?? const {};
    final name = swipeActionName(
      l10n,
      action,
      ref.watch(_deleteModeProvider),
      tags: tags,
    );
    final tagMissing =
        action?.type == SwipeActionType.addTag &&
        !tags.containsKey(action?.tagId);
    final directionName = swipeDirectionName(l10n, direction);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Semantics(
          button: true,
          label: '$directionName: $name',
          excludeSemantics: true,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Icon(
                  tagMissing ? Icons.warning_amber : _arrow(direction),
                  color: tagMissing ? colors.error : colors.primary,
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: action == null ? colors.onSurfaceVariant : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static IconData _arrow(SwipeDirection d) => switch (d) {
    SwipeDirection.left => Icons.arrow_back,
    SwipeDirection.right => Icons.arrow_forward,
    SwipeDirection.up => Icons.arrow_upward,
    SwipeDirection.down => Icons.arrow_downward,
  };
}

class _ActionPicker extends ConsumerWidget {
  const new({
    required this.title,
    this.current,
    this.canPickNothing = true,
    this.showNothing = true,
    this.disabledTypes = const {},
  });

  final String title;
  final SwipeAction? current;
  final bool canPickNothing;
  final bool showNothing;

  /// P4: no-target actions already in the bar.
  final Set<SwipeActionType> disabledTypes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final mode = ref.watch(_deleteModeProvider);
    final access = ref.watch(storageAccessControllerProvider).value;
    // API 30+ asks before moving other apps' photos unless one of these is on.
    final moveAsks =
        access != null && !access.canSeeAllFiles && !access.mediaManagement;
    Widget option(
      SwipeActionType? type, {
      bool enabled = true,
      String? help,
      Widget? action,
    }) {
      final selected = type == current?.type;
      return ListTile(
        enabled: enabled,
        selected: selected,
        title: Text(swipeTypeName(l10n, type, mode)),
        subtitle: help == null ? null : Text(help),
        trailing: action ?? (selected ? const Icon(Icons.check) : null),
        onTap: () => Navigator.of(context).pop<_Choice>((type: type)),
      );
    }

    // Seven options: scroll on short screens.
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          for (final t in assignableSwipeActionTypes)
            if (t == SwipeActionType.moveTo && moveAsks)
              option(
                t,
                help: l10n.moveConsentNotice,
                action: access.mediaManagementSupported
                    ? TextButton(
                        onPressed: () => ref
                            .read(permissionServiceProvider)
                            .openMediaManagementSettings(),
                        child: Text(l10n.turnOn),
                      )
                    : null,
              )
            else
              option(t, enabled: !disabledTypes.contains(t)),
          if (showNothing)
            option(
              null,
              enabled: canPickNothing,
              help: canPickNothing ? null : l10n.swipeActionNeedOne,
            ),
        ],
      ),
    );
  }
}

/// The saved delete mode, so "trash" reads "Delete permanently" when that
/// is what it will do.
final Provider<DeleteMode> _deleteModeProvider =
    Provider.autoDispose<DeleteMode>(
      (ref) => ref.watch(deleteModeSettingProvider).value ?? DeleteMode.trash,
    );

String swipeDirectionName(AppLocalizations l, SwipeDirection d) => switch (d) {
  SwipeDirection.left => l.swipeDirectionLeft,
  SwipeDirection.right => l.swipeDirectionRight,
  SwipeDirection.up => l.swipeDirectionUp,
  SwipeDirection.down => l.swipeDirectionDown,
};

/// A picker option ("Move to folder…").
String swipeTypeName(
  AppLocalizations l,
  SwipeActionType? type,
  DeleteMode mode,
) => switch (type) {
  null => l.swipeActionNothing,
  SwipeActionType.trash =>
    mode == DeleteMode.permanent ? l.swipeActionDelete : l.swipeActionTrash,
  SwipeActionType.keep => l.swipeActionKeep,
  SwipeActionType.moveTo => l.swipeActionMoveTo,
  SwipeActionType.copyTo => l.swipeActionCopyTo,
  SwipeActionType.addTag => l.swipeActionAddTag,
  SwipeActionType.favorite => l.swipeActionFavorite,
  SwipeActionType.renameBatch => l.swipeActionRenameBatch,
  // Not assignable yet (Phase 5): shown only if a stored layout has it.
  SwipeActionType.sendToDevice => actionLabel(l, SwipeAction(type)),
};

/// What a direction does, as a name ("Move to Holiday"), not a result label.
String swipeActionName(
  AppLocalizations l,
  SwipeAction? a,
  DeleteMode mode, {
  Map<int, Tag> tags = const {},
}) => switch (a?.type) {
  SwipeActionType.moveTo => l.swipeActionMoveToNamed(_leaf(a!.targetFolder)),
  SwipeActionType.copyTo => l.swipeActionCopyToNamed(_leaf(a!.targetFolder)),
  SwipeActionType.addTag => switch (tags[a!.tagId]) {
    final tag? => l.swipeActionTagNamed(tag.name),
    null => l.swipeActionTagMissing,
  },
  final type => swipeTypeName(l, type, mode),
};

String _leaf(String? path) {
  final parts = (path ?? '').split('/').where((p) => p.isNotEmpty);
  return parts.isEmpty ? '' : parts.last;
}

/// No-target types already in the action bar (can't be added twice).
Set<SwipeActionType> barTypesInUse(SwipeLayout layout) => {
  for (final a in layout.actionBar)
    if (!a.type.needsTarget) a.type,
};

/// The action picker plus its folder/tag sub-picker (P1/P2; also used by
/// P6's preset editor). Null = dismissed; `action` null = "Nothing".
Future<({SwipeAction? action})?> pickSwipeAction(
  BuildContext context, {
  required String title,
  SwipeAction? current,
  bool canPickNothing = true,
  bool showNothing = true,
  Set<SwipeActionType> disabledTypes = const {},
}) async {
  final choice = await showModalBottomSheet<_Choice>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _ActionPicker(
      title: title,
      current: current,
      canPickNothing: canPickNothing,
      showNothing: showNothing,
      disabledTypes: disabledTypes,
    ),
  );
  if (choice == null || !context.mounted) return null;
  final type = choice.type;
  if (type == null) return (action: null);
  final action = await _withTarget(context, type);
  return action == null ? null : (action: action);
}

/// Asks for the folder or tag a type needs; null when that was dismissed.
Future<SwipeAction?> _withTarget(
  BuildContext context,
  SwipeActionType type,
) async {
  switch (type) {
    case SwipeActionType.moveTo || SwipeActionType.copyTo:
      final folder = await showFolderPicker(context);
      return folder == null ? null : SwipeAction(type, targetFolder: folder);
    case SwipeActionType.addTag:
      final tagId = await showTagPicker(context);
      return tagId == null ? null : SwipeAction(type, tagId: tagId);
    case SwipeActionType.trash ||
        SwipeActionType.keep ||
        SwipeActionType.favorite ||
        SwipeActionType.renameBatch ||
        SwipeActionType.sendToDevice:
      return SwipeAction(type);
  }
}

/// P4: on/off switch + the bar's buttons (add, reorder, remove).
class _ActionBarSection extends ConsumerWidget {
  const new({required this.layout, required this.onAdd});

  final SwipeLayout layout;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final enabled = ref.watch(actionBarEnabledProvider).value ?? false;
    final bar = layout.actionBar;
    final tags = ref.watch(tagsByIdProvider).value ?? const {};
    final mode = ref.watch(_deleteModeProvider);
    final controller = ref.read(swipeLayoutControllerProvider.notifier);
    final full = bar.length >= SwipeLayoutController.maxBarActions;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            title: Text(l10n.actionBarTitle),
            subtitle: Text(l10n.actionBarHelp),
            value: enabled,
            onChanged: (v) => ref
                .read(settingsRepositoryProvider)
                .write(AppSettings.actionBarEnabled, v)
                .fireAndForget(),
          ),
          if (enabled) ...[
            if (bar.isEmpty)
              ListTile(dense: true, title: Text(l10n.actionBarEmpty)),
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorderItem: (from, to) =>
                  controller.moveBarAction(from, to).ignore(),
              children: [
                for (final (i, a) in bar.indexed)
                  ListTile(
                    key: ValueKey('bar:$i:${a.hashCode}'),
                    leading: ReorderableDragStartListener(
                      index: i,
                      child: const Icon(Icons.drag_handle),
                    ),
                    title: Text(swipeActionName(l10n, a, mode, tags: tags)),
                    trailing: IconButton(
                      tooltip: l10n.actionBarRemove,
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => controller.removeBarAction(i).ignore(),
                    ),
                  ),
              ],
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: Text(l10n.actionBarAdd),
              subtitle: full ? Text(l10n.actionBarFull) : null,
              enabled: !full,
              onTap: onAdd,
            ),
          ],
        ],
      ),
    );
  }
}
