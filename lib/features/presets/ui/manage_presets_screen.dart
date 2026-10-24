import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/features/filters/domain/file_filter.dart';
import 'package:kfm/features/folders/ui/folder_picker_sheet.dart';
import 'package:kfm/features/presets/data/preset_repository.dart';
import 'package:kfm/features/presets/domain/preset.dart';
import 'package:kfm/features/presets/ui/active_preset_controller.dart';
import 'package:kfm/features/presets/ui/save_preset_dialog.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';

/// Settings → Swiping → Presets (TASK-P6): reorder, rename, edit,
/// duplicate, delete; examples when there are none.
class ManagePresetsScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final presets = ref.watch(presetsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsPresets)),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(l10n.presetNew),
        onPressed: () => _newFromCurrent(context, ref),
      ),
      body: switch (presets) {
        AsyncData(:final value) when value.isEmpty => const _Empty(),
        AsyncData(:final value) => ReorderableListView(
          buildDefaultDragHandles: false,
          padding: const EdgeInsets.only(bottom: 96),
          onReorderItem: (from, to) {
            final ids = [for (final p in value) p.id];
            ids.insert(to, ids.removeAt(from));
            ref.read(presetRepositoryProvider).reorder(ids).ignore();
          },
          children: [
            for (final (i, p) in value.indexed)
              ListTile(
                key: ValueKey('preset:${p.id}'),
                leading: ReorderableDragStartListener(
                  index: i,
                  child: const Icon(Icons.drag_handle),
                ),
                title: Text(p.name),
                subtitle: p is PresetLoadError
                    ? Text(l10n.presetLoadError)
                    : null,
                onTap: () => context.go(AppRoutes.presetEditorFor(p.id)),
                trailing: _RowMenu(entry: p),
              ),
          ],
        ),
        AsyncError(:final error) => Center(child: Text(error.toString())),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }

  /// FAB: the current setup (active session, else Basic's saved layout).
  static Future<void> _newFromCurrent(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final session = await ref.read(sessionRepositoryProvider).active();
    if (!context.mounted) return;
    await _saveWithFeedback(
      context,
      layout: session?.layout ?? SwipeLayout.basic,
      filterJson: session?.filterJson,
    );
  }
}

Future<void> _saveWithFeedback(
  BuildContext context, {
  required SwipeLayout layout,
  String? filterJson,
  String initialName = '',
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  final repo = ProviderScope.containerOf(context)
      .read(presetRepositoryProvider);
  final id = await showSavePresetDialog(
    context,
    layout: layout,
    filterJson: filterJson,
    initialName: initialName,
  );
  if (id == null) return;
  final saved = await repo.byId(id);
  if (saved == null) return;
  messenger.showSnackBar(SnackBar(content: Text(l10n.presetSaved(saved.name))));
}

enum _Action { rename, edit, duplicate, delete }

class _RowMenu extends ConsumerWidget {
  const new({required this.entry});

  final PresetEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return PopupMenuButton<_Action>(
      onSelected: (a) => switch (a) {
        _Action.rename => _rename(context, ref),
        _Action.edit => context.go(AppRoutes.presetEditorFor(entry.id)),
        _Action.duplicate =>
          ref.read(presetRepositoryProvider).duplicate(entry.id).ignore(),
        _Action.delete => _delete(context, ref),
      },
      itemBuilder: (_) => [
        PopupMenuItem(value: _Action.rename, child: Text(l10n.presetRename)),
        PopupMenuItem(value: _Action.edit, child: Text(l10n.presetEdit)),
        PopupMenuItem(
          value: _Action.duplicate,
          child: Text(l10n.presetDuplicate),
        ),
        PopupMenuItem(value: _Action.delete, child: Text(l10n.presetDelete)),
      ],
    );
  }

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final controller = TextEditingController(text: entry.name);
    String? error;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.presetRename),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: kPresetNameMax,
            decoration: InputDecoration(
              labelText: l10n.presetNameLabel,
              errorText: error,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                try {
                  await ref
                      .read(presetRepositoryProvider)
                      .rename(entry.id, controller.text);
                  navigator.pop();
                } on PresetNameException catch (e) {
                  setState(
                    () => error = e.problem == PresetNameProblem.taken
                        ? l10n.presetNameTaken
                        : l10n.presetNameInvalid,
                  );
                }
              },
              child: Text(l10n.presetEditorSave),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.presetDeleteConfirm(entry.name)),
        content: Text(l10n.presetDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.presetDelete),
          ),
        ],
      ),
    );
    if (ok ?? false) {
      await ref.read(activePresetControllerProvider.notifier).delete(entry.id);
    }
  }
}

class _Empty extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    Widget example(
      String title,
      String help,
      Future<void> Function() onCreate,
    ) => Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(help),
        trailing: TextButton(
          onPressed: onCreate,
          child: Text(l10n.presetCreate),
        ),
      ),
    );
    return ListView(
      padding: EdgeInsetsDirectional.all(spacing * 2),
      children: [
        Text(
          l10n.presetEmptyTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: spacing),
        Text(l10n.presetEmptyBody),
        SizedBox(height: spacing * 2),
        example(
          l10n.presetEmptyQuickCleanup,
          l10n.presetEmptyQuickCleanupHelp,
          () => _saveWithFeedback(
            context,
            layout: SwipeLayout.basic,
            filterJson: jsonEncode(
              const FileFilter(screenshotsOnly: true).toJson(),
            ),
            initialName: l10n.presetEmptyQuickCleanup,
          ),
        ),
        example(
          l10n.presetEmptySortHoliday,
          l10n.presetEmptySortHolidayHelp,
          () async {
            final folder = await showFolderPicker(context);
            if (folder == null || !context.mounted) return;
            await _saveWithFeedback(
              context,
              layout: SwipeLayout(
                directions: {
                  SwipeDirection.left: SwipeAction.trash,
                  SwipeDirection.right: SwipeAction(
                    SwipeActionType.moveTo,
                    targetFolder: folder,
                  ),
                  SwipeDirection.up: const SwipeAction(
                    SwipeActionType.favorite,
                  ),
                },
              ),
              initialName: l10n.presetEmptySortHoliday,
            );
          },
        ),
      ],
    );
  }
}
