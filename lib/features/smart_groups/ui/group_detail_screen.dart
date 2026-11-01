import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/features/browse/ui/widgets/file_results_view.dart';
import 'package:kfm/features/filters/domain/file_filter.dart';
import 'package:kfm/features/smart_groups/data/smart_groups_providers.dart';
import 'package:kfm/features/smart_groups/data/smart_groups_repository.dart';
import 'package:kfm/features/smart_groups/ui/smart_group_titles.dart';
import 'package:kfm/features/swipe/domain/swipe_source.dart';
import 'package:kfm/features/swipe/ui/swipe_source_launcher.dart';
import 'package:kfm/features/swipe/ui/swipe_these.dart';

/// One group's files (TASK-C5): Browse's grid with keyset paging over the
/// group's [IndexQuery]. Trips/Places can be renamed; a stored group that
/// was recomputed away shows "This group changed".
class GroupDetailScreen extends ConsumerWidget {
  const new({required this.groupKey, super.key});

  final GroupKey groupKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    switch (groupKey) {
      case LiveGroupKey(:final group):
        final title = liveGroupTitle(l10n, group);
        return _scaffold(
          context,
          ref,
          title: title,
          query: group.query,
          // Documents swipes its photos C3 labeled 'document' (non-media
          // documents are left out; none → "nothing to swipe").
          canSwipe: true,
        );
      case StoredGroupKey(:final id):
        final async = ref.watch(smartGroupProvider(id));
        final row = async.value?.row;
        if (row == null) {
          if (!async.hasValue && !async.hasError) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: CircularProgressIndicator()),
            );
          }
          return _Changed(onBack: () => context.go(AppRoutes.groups));
        }
        return _scaffold(
          context,
          ref,
          title: smartGroupTitle(l10n, row),
          query: IndexQuery(smartGroupId: id),
          canSwipe: true,
          row: row,
        );
    }
  }

  Widget _scaffold(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required IndexQuery query,
    required bool canSwipe,
    SmartGroupRow? row,
  }) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (canSwipe)
            IconButton(
              tooltip: l10n.groupsSwipe,
              icon: const Icon(Icons.swipe_outlined),
              onPressed: () => unawaited(_swipe(context, ref, title, query)),
            ),
          if (row != null)
            IconButton(
              tooltip: l10n.groupsRename,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => unawaited(_rename(context, ref, row)),
            ),
        ],
      ),
      body: FileResultsView(query: query),
    );
  }

  Future<void> _swipe(
    BuildContext context,
    WidgetRef ref,
    String title,
    IndexQuery query,
  ) async {
    final returnRoute = AppRoutes.groupFor(groupKey.value);
    if (groupKey case LiveGroupKey(group: LiveGroup.screenshots)) {
      // Same filter as B1's Screenshots source.
      final SwipeSourceOpenResult r;
      try {
        r = await ref
            .read(swipeSourceLauncherProvider.notifier)
            .open(
              FilterSourceRequest(
                origin: SwipeSourceOrigin.smartGroup,
                title: title,
                filter: const FileFilter(screenshotsOnly: true),
                returnRoute: returnRoute,
              ),
            );
      } on Object {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.swipeErrorGeneric)),
          );
        }
        return;
      }
      if (!context.mounted) return;
      if (r is SwipeSourceOpened) context.go(AppRoutes.swipe);
      showSwipeSourceResult(context, r);
      return;
    }
    await swipeQueryFiles(
      context,
      ref,
      query: query,
      title: title,
      origin: SwipeSourceOrigin.smartGroup,
      returnRoute: returnRoute,
    );
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    SmartGroupRow row,
  ) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _RenameDialog(initial: row.userTitle ?? ''),
    );
    if (result == null) return;
    ref
        .read(smartGroupsRepositoryProvider)
        .rename(row.id, result)
        .fireAndForget();
  }
}

class _RenameDialog extends StatefulWidget {
  const new({required this.initial});

  final String initial;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _text = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.groupsRename),
      content: TextField(
        controller: _text,
        autofocus: true,
        maxLength: 80,
        decoration: InputDecoration(hintText: l10n.groupsRenameHint),
        onSubmitted: (v) => Navigator.of(context).pop(v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.groupsRenameCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_text.text),
          child: Text(l10n.groupsRenameSave),
        ),
      ],
    );
  }
}

class _Changed extends StatelessWidget {
  const new({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: EdgeInsetsDirectional.all(spacing * 3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.groupsChanged,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: spacing),
              Text(l10n.groupsChangedBody, textAlign: TextAlign.center),
              SizedBox(height: spacing * 2),
              FilledButton(onPressed: onBack, child: Text(l10n.groupsBack)),
            ],
          ),
        ),
      ),
    );
  }
}
