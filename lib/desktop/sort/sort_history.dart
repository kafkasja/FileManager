import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/desktop/sort/sort_actions.dart';
import 'package:kfm/desktop/widgets/desktop_metrics.dart';
import 'package:kfm/features/connect/ui/known_device_names.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/swipe/domain/action_label.dart';
import 'package:kfm/features/swipe/ui/swipe_action_bar.dart'
    show swipeActionIcon;
import 'package:kfm/features/tags/data/tag_providers.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';
import 'package:kfm/features/undo/data/undo_repository.dart';
import 'package:kfm/features/undo/domain/previous_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sort_history.g.dart';

/// One row of the Sort History panel.
@immutable
class SortHistoryEntry {
  const new(this.action, this.fileName);

  final SessionAction action;
  final String fileName;
}

/// How many actions the panel lists (the log itself is unlimited; older
/// ones are still undone one by one through Undo).
const sortHistoryLimit = 500;

/// The session's undoable actions, newest first, with file names. Follows
/// the undo log (S2) through its undoable count.
@riverpod
Future<List<SortHistoryEntry>> sortHistory(Ref ref, int sessionId) async {
  ref.watch(undoableCountProvider(sessionId));
  final actions = await ref
      .watch(undoRepositoryProvider)
      .stack(sessionId, limit: sortHistoryLimit);
  final names = {
    for (final f in await ref.watch(mediaIndexDaoProvider).byIds([
      for (final a in actions) a.fileId,
    ]))
      f.id: f.name,
  };
  return [
    for (final a in actions)
      SortHistoryEntry(a, names[a.fileId] ?? _fallbackName(a)),
  ];
}

/// A committed delete's file left the index: its stored FileRef has the
/// name; else the id's last path segment.
String _fallbackName(SessionAction a) {
  final previous = a.previous;
  final item = previous is TrashPreviousState ? previous.trashedItem : null;
  final original = item == null ? null : item['original'];
  if (original is Map) {
    final name = original['name'];
    if (name is String) return name;
  }
  final id = a.fileId;
  final slash = id.lastIndexOf('/');
  return slash < 0 ? id : id.substring(slash + 1);
}

/// The History panel (TASK-PL3, PL3-5 a): newest first; clicking an entry
/// undoes back to (and including) it, after a confirm when that is more
/// than 10 actions.
class SortHistoryPanel extends ConsumerWidget {
  const new({
    required this.sessionId,
    required this.deleteMode,
    required this.onUndoSteps,
    required this.onClose,
    this.busy = false,
    super.key,
  });

  final int sessionId;
  final DeleteMode deleteMode;

  /// Undo the newest `steps` actions.
  final Future<void> Function(int steps) onUndoSteps;
  final VoidCallback onClose;
  final bool busy;

  static const width = 300.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final entries = ref.watch(sortHistoryProvider(sessionId)).value ?? [];
    final tags = ref.watch(tagsByIdProvider).value ?? const {};
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: scaledExtent(context, 44),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    l10n.desktopSortHistory,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  tooltip: l10n.desktopClose,
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Text(
                      l10n.desktopSortHistoryEmpty,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    key: const ValueKey('sort-history-list'),
                    itemCount: entries.length,
                    itemBuilder: (context, i) {
                      final e = entries[i];
                      final a = e.action;
                      final label = switch (a.previous) {
                        RenamePreviousState(op: RenameOp.apply) =>
                          l10n.labelRenameApplied,
                        _ => actionLabel(
                          l10n,
                          a.action,
                          deleteMode: deleteMode,
                          tagName: tags[a.action.tagId]?.name,
                          deviceName: knownDeviceName(ref, a.action.deviceId),
                        ),
                      };
                      final time = TimeOfDay.fromDateTime(a.createdAt.toLocal())
                          .format(context);
                      return Tooltip(
                        message: l10n.desktopSortUndoToHere,
                        waitDuration: const Duration(milliseconds: 600),
                        child: ListTile(
                          key: ValueKey('sort-history-$i'),
                          dense: true,
                          enabled: !busy,
                          leading: Icon(
                            swipeActionIcon(a.action.type),
                            size: 18,
                            color: sortActionColor(context, a.action),
                          ),
                          title: Text(
                            e.fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(label),
                          trailing: Text(
                            time,
                            style: theme.textTheme.bodySmall,
                          ),
                          onTap: () => onUndoSteps(i + 1),
                        ),
                      );
                    },
                  ),
          ),
          if (entries.length >= sortHistoryLimit)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                l10n.desktopStatusItems(entries.length),
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}
