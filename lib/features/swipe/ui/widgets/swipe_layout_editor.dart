import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/ui/known_device_names.dart';
import 'package:kfm/features/folders/ui/folder_picker_sheet.dart';
import 'package:kfm/features/session/domain/session_source.dart';
import 'package:kfm/features/swipe/domain/action_label.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/ui/swipe_layout_controller.dart';
import 'package:kfm/features/swipe/ui/swipe_settings_section.dart';
import 'package:kfm/features/tags/data/tag_providers.dart';
import 'package:kfm/features/tags/ui/tag_picker_sheet.dart';
import 'package:kfm/features/transfers/ui/transfer_flows.dart';
import 'package:kfm/features/trash/data/trash_providers.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';

/// S6: the direction cross (+ optionally the P4 action bar and "Reset to
/// basic") of [sourceId]'s layout. Used by Settings → Customize swipes and
/// the swipe setup sheet, so both edit the same way. Directions are
/// physical, never mirrored for RTL.
class SwipeLayoutEditor extends ConsumerWidget {
  const new({
    super.key,
    this.sourceId = kLocalSourceId,
    this.showActionBar = true,
    this.beforeReset,
  });

  final String sourceId;

  /// False in the setup sheet, which shows the bar under Extras.
  final bool showActionBar;

  /// Shown between the editor and "Reset to basic" (Settings: "Save as
  /// preset…").
  final Widget? beforeReset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final colors = Theme.of(context).colorScheme;
    final layout = ref.watch(swipeLayoutForSourceProvider(sourceId)).value;
    if (layout == null) {
      return const Center(child: CircularProgressIndicator());
    }
    Widget tile(SwipeDirection d) => SwipeDirectionTile(
      direction: d,
      action: layout.actionFor(d),
      onTap: () => _pick(context, ref, layout, d),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        if (showActionBar) ...[
          SizedBox(height: spacing * 3),
          SwipeActionBarEditor(sourceId: sourceId),
        ],
        if (beforeReset case final extra?) ...[
          SizedBox(height: spacing * 2),
          extra,
        ],
        if (layout != SwipeLayout.basic) ...[
          SizedBox(height: beforeReset == null ? spacing * 2 : spacing),
          Center(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.restart_alt),
              label: Text(l10n.swipeLayoutReset),
              onPressed: () => _confirmReset(context, ref),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    SwipeLayout layout,
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
      disabledTypes: disabledTypesFor(sourceId),
    );
    if (picked == null || picked.action == current) return;
    await ref
        .read(swipeLayoutForSourceProvider(sourceId).notifier)
        .setDirection(direction, picked.action);
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
      await ref
          .read(swipeLayoutForSourceProvider(sourceId).notifier)
          .resetToBasic();
    }
  }
}

/// S6: action types a source's sessions can't use. A remote session (N8)
/// never offers rename batch, sending, or moves/copies (the folder picker
/// shows this device's folders, which the other device can't write).
Set<SwipeActionType> disabledTypesFor(String sourceId) =>
    sourceId == kLocalSourceId
    ? const {}
    : const {
        SwipeActionType.renameBatch,
        SwipeActionType.sendToDevice,
        SwipeActionType.moveTo,
        SwipeActionType.copyTo,
      };

/// The picked option; `type` null = nothing.
typedef _Choice = ({SwipeActionType? type});

/// One direction of the cross: its arrow and what it does.
class SwipeDirectionTile extends ConsumerWidget {
  const new({
    required this.direction,
    required this.action,
    required this.onTap,
    super.key,
  });

  final SwipeDirection direction;
  final SwipeAction? action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final tags = ref.watch(tagsByIdProvider).value ?? const {};
    // N9: send labels name the device.
    ref.watch(knownDevicesProvider);
    final name = swipeActionName(
      l10n,
      action,
      ref.watch(swipeDeleteModeProvider),
      tags: tags,
      deviceNameOf: (id) => knownDeviceName(ref, id),
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

  static IconData _arrow(SwipeDirection d) => swipeDirectionIcon(d);
}

/// The arrow of a physical swipe direction.
IconData swipeDirectionIcon(SwipeDirection d) => switch (d) {
  SwipeDirection.left => Icons.arrow_back,
  SwipeDirection.right => Icons.arrow_forward,
  SwipeDirection.up => Icons.arrow_upward,
  SwipeDirection.down => Icons.arrow_downward,
};

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
    final mode = ref.watch(swipeDeleteModeProvider);
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
final Provider<DeleteMode> swipeDeleteModeProvider =
    Provider.autoDispose<DeleteMode>(
      (ref) => ref.watch(deleteModeSettingProvider).value ?? DeleteMode.trash,
    );

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
    case SwipeActionType.sendToDevice:
      return await pickSendToDeviceAction(context);
    case SwipeActionType.trash ||
        SwipeActionType.keep ||
        SwipeActionType.favorite ||
        SwipeActionType.renameBatch:
      return SwipeAction(type);
  }
}

/// P4: on/off switch + the bar's buttons (add, reorder, remove) of
/// [sourceId]'s layout.
class SwipeActionBarEditor extends ConsumerWidget {
  const new({super.key, this.sourceId = kLocalSourceId});

  final String sourceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final layout = ref.watch(swipeLayoutForSourceProvider(sourceId)).value;
    if (layout == null) return const SizedBox.shrink();
    final enabled = ref.watch(actionBarEnabledProvider).value ?? false;
    final bar = layout.actionBar;
    final tags = ref.watch(tagsByIdProvider).value ?? const {};
    final mode = ref.watch(swipeDeleteModeProvider);
    final controller = ref.read(
      swipeLayoutForSourceProvider(sourceId).notifier,
    );
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
                    title: Text(
                      swipeActionName(
                        l10n,
                        a,
                        mode,
                        tags: tags,
                        deviceNameOf: (id) => knownDeviceName(ref, id),
                      ),
                    ),
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
              onTap: () => _add(context, ref, layout),
            ),
          ],
        ],
      ),
    );
  }

  /// P4: "Add action" for the action bar.
  Future<void> _add(
    BuildContext context,
    WidgetRef ref,
    SwipeLayout layout,
  ) async {
    final action = (await pickSwipeAction(
      context,
      title: context.l10n.actionBarAdd,
      showNothing: false,
      disabledTypes: {...barTypesInUse(layout), ...disabledTypesFor(sourceId)},
    ))?.action;
    if (action == null) return;
    await ref
        .read(swipeLayoutForSourceProvider(sourceId).notifier)
        .addBarAction(action);
  }
}
