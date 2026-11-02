import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/layout/adaptive_list_tile.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'folders_settings_section.g.dart';

/// What dropping dragged files on a folder does (B4).
@Riverpod(keepAlive: true)
Stream<DropAction> foldersDropAction(Ref ref) =>
    ref.watch(settingsRepositoryProvider).watch(AppSettings.foldersDropAction);

/// Settings → Files (TASK-B4 §11).
class FoldersSettingsSection extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final value = ref.watch(foldersDropActionProvider).value ?? DropAction.move;
    return AdaptiveListTile(
      leading: const Icon(Icons.drive_file_move_outlined),
      title: Text(l10n.settingsDropAction),
      trailing: DropdownButton<DropAction>(
        value: value,
        onChanged: (v) {
          if (v == null) return;
          ref
              .read(settingsRepositoryProvider)
              .write(AppSettings.foldersDropAction, v)
              .fireAndForget();
        },
        items: [
          DropdownMenuItem(
            value: DropAction.move,
            child: Text(l10n.dropActionMove),
          ),
          DropdownMenuItem(
            value: DropAction.copy,
            child: Text(l10n.dropActionCopy),
          ),
        ],
      ),
    );
  }
}
