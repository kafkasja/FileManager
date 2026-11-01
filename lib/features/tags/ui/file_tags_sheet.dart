import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/features/tags/data/tag_providers.dart';
import 'package:kfm/features/tags/ui/tag_actions.dart';
import 'package:kfm/features/tags/ui/tag_picker_sheet.dart';

/// One file's tags as checkboxes (TASK-B9). Each toggle writes at once
/// (unchecking undoes it); "New tag…" creates a tag and adds it.
Future<void> showFileTagsSheet(BuildContext context, String fileId) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FileTagsSheet(fileId: fileId),
    );

class _FileTagsSheet extends ConsumerWidget {
  const new({required this.fileId});

  final String fileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tags = ref.watch(tagsByIdProvider).value?.values.toList() ?? const [];
    final on = ref.watch(fileTagIdsProvider(fileId)).value ?? const <int>{};
    // The snackbar belongs to the screen under the sheet.
    final outer = Navigator.of(context).context;
    return DraggableScrollableSheet(
      expand: false,
      maxChildSize: 0.9,
      builder: (context, scroll) => ListView(
        controller: scroll,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
            child: Text(
              l10n.fileTagsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.new_label_outlined),
            title: Text(l10n.tagPickerNew),
            onTap: () async {
              final tag = await showNewTagDialog(context);
              if (tag == null || !outer.mounted) return;
              await addTagIdToFiles(outer, tag.id, [fileId], quiet: true);
            },
          ),
          if (tags.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.tagsEmpty),
            ),
          for (final t in tags)
            CheckboxListTile(
              secondary: Icon(Icons.label, color: Color(t.color)),
              title: Text(t.name),
              value: on.contains(t.id),
              // Quiet: the checkbox is its own undo, and a snackbar would
              // cover the sheet's rows.
              onChanged: (value) => unawaited(
                value ?? false
                    ? addTagIdToFiles(outer, t.id, [fileId], quiet: true)
                    : removeTagIdFromFiles(outer, t.id, [fileId], quiet: true),
              ),
            ),
        ],
      ),
    );
  }
}
