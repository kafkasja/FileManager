import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/features/swipe/data/swipe_action_dispatcher.dart';
import 'package:kfm/features/swipe/domain/action_label.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/ui/swipe_settings_section.dart';
import 'package:kfm/features/tags/data/tag_providers.dart';
import 'package:kfm/features/tags/domain/tag.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// The icon for an action (hint overlay, action bar, P9 buttons).
IconData swipeActionIcon(SwipeActionType type) => switch (type) {
  SwipeActionType.trash => Icons.delete_outline,
  SwipeActionType.keep => Icons.check,
  SwipeActionType.moveTo => Icons.drive_file_move_outline,
  SwipeActionType.copyTo => Icons.file_copy_outlined,
  SwipeActionType.addTag => Icons.label_outline,
  SwipeActionType.favorite => Icons.star_outline,
  SwipeActionType.renameBatch => Icons.drive_file_rename_outline,
  SwipeActionType.sendToDevice => Icons.send_to_mobile_outlined,
};

/// A short button label ("Trash", "Holiday", "Cats"…).
String swipeActionShortLabel(
  AppLocalizations l,
  SwipeAction a, {
  DeleteMode deleteMode = DeleteMode.trash,
  Map<int, Tag> tags = const {},
}) {
  String cut(String s) => s.length <= 12 ? s : '${s.substring(0, 11)}…';
  String leaf(String? path) {
    final parts = (path ?? '').split('/').where((p) => p.isNotEmpty);
    return parts.isEmpty ? '' : parts.last;
  }

  return switch (a.type) {
    SwipeActionType.trash =>
      deleteMode == DeleteMode.permanent ? l.barDelete : l.barTrash,
    SwipeActionType.keep => l.barKeep,
    SwipeActionType.moveTo ||
    SwipeActionType.copyTo => cut(leaf(a.targetFolder)),
    SwipeActionType.addTag => cut(tags[a.tagId]?.name ?? '?'),
    SwipeActionType.favorite => l.barFavorite,
    SwipeActionType.renameBatch => l.barRename,
    SwipeActionType.sendToDevice => actionLabel(l, a),
  };
}

/// P4: extra action buttons under the card. Hidden when turned off or
/// empty. Reads the deck's layout (what `apply` runs), never the editor's.
class SwipeActionBar extends ConsumerStatefulWidget {
  const new({
    required this.layout,
    required this.deleteMode,
    required this.onApply,
    required this.onBlocked,
    super.key,
  });

  final SwipeLayout layout;
  final DeleteMode deleteMode;
  final bool Function(SwipeAction action) onApply;

  /// Tapped an action that can't run (e.g. its tag was deleted).
  final void Function(SwipeActionProblem problem) onBlocked;

  @override
  ConsumerState<SwipeActionBar> createState() => _SwipeActionBarState();
}

class _SwipeActionBarState extends ConsumerState<SwipeActionBar> {
  /// A fast double tap must not act on the next file before it's seen.
  static const cooldown = Duration(milliseconds: 300);
  DateTime? _lastTap;

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(actionBarEnabledProvider).value ?? false;
    final actions = widget.layout.actionBar;
    if (!enabled || actions.isEmpty) return const SizedBox.shrink();
    final tags = ref.watch(tagsByIdProvider).value ?? const {};
    final spacing = context.tokens.spacing;
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsetsDirectional.symmetric(horizontal: spacing * 2),
        itemCount: actions.length,
        separatorBuilder: (_, _) => SizedBox(width: spacing),
        itemBuilder: (context, i) {
          final action = actions[i];
          return Center(
            child: _ActionBarButton(
              action: action,
              deleteMode: widget.deleteMode,
              tags: tags,
              problem: SwipeActionDispatcher.problemFor(action, tags),
              onPressed: () => _tap(action, tags),
            ),
          );
        },
      ),
    );
  }

  void _tap(SwipeAction action, Map<int, Tag> tags) {
    final problem = SwipeActionDispatcher.problemFor(action, tags);
    if (problem != null) {
      widget.onBlocked(problem);
      return;
    }
    final now = DateTime.now();
    final last = _lastTap;
    if (last != null && now.difference(last) < cooldown) return;
    _lastTap = now;
    widget.onApply(action);
  }
}

class _ActionBarButton extends StatelessWidget {
  const new({
    required this.action,
    required this.deleteMode,
    required this.tags,
    required this.problem,
    required this.onPressed,
  });

  final SwipeAction action;
  final DeleteMode deleteMode;
  final Map<int, Tag> tags;
  final SwipeActionProblem? problem;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final blocked = problem != null;
    return Semantics(
      button: true,
      label: actionLabel(
        l10n,
        action,
        deleteMode: deleteMode,
        tagName: tags[action.tagId]?.name,
      ),
      excludeSemantics: true,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: blocked ? colors.outline : null,
        ),
        onPressed: onPressed,
        icon: Icon(
          blocked ? Icons.warning_amber : swipeActionIcon(action.type),
        ),
        label: Text(
          swipeActionShortLabel(
            l10n,
            action,
            deleteMode: deleteMode,
            tags: tags,
          ),
        ),
      ),
    );
  }
}
