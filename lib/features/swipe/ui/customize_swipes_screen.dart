import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/features/presets/data/preset_repository.dart';
import 'package:kfm/features/presets/ui/active_preset_controller.dart';
import 'package:kfm/features/presets/ui/save_preset_dialog.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/ui/swipe_layout_controller.dart';
import 'package:kfm/features/swipe/ui/widgets/swipe_layout_editor.dart';

export 'package:kfm/features/swipe/ui/widgets/swipe_layout_editor.dart'
    show barTypesInUse, pickSwipeAction;

/// Settings → Swiping → Customize swipes (TASK-P1): one action per
/// direction. S6: the editor itself is [SwipeLayoutEditor], shared with the
/// swipe setup sheet.
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
    return ListView(
      padding: EdgeInsetsDirectional.all(spacing * 2),
      children: [
        Text(l10n.customizeSwipesIntro),
        SizedBox(height: spacing * 2),
        SwipeLayoutEditor(
          // P6: keep this setup as a preset; X6 note: it becomes the
          // active one (same session).
          beforeReset: Center(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.bookmark_add_outlined),
              label: Text(l10n.presetSaveAs),
              onPressed: () => _saveAsPreset(context, ref),
            ),
          ),
        ),
      ],
    );
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
    await ref.read(activePresetControllerProvider.notifier).adoptCurrentAs(id);
    final saved = await ref.read(presetRepositoryProvider).byId(id);
    if (saved != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.presetSaved(saved.name))),
      );
    }
  }
}
