import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/features/selection/ui/selection_actions.dart';
import 'package:kfm/features/swipe/domain/swipe_source.dart';
import 'package:kfm/features/swipe/ui/swipe_source_launcher.dart';

const Set<FileKind> _media = {FileKind.image, FileKind.video};

/// "Swipe these" for a Browse view, search results, a tag or Favorites
/// (TASK-SS1): the photos and videos of [query], in the view's order, as a
/// list source (first 10,000). Then opens the swipe tab.
Future<void> swipeQueryFiles(
  BuildContext context,
  WidgetRef ref, {
  required IndexQuery query,
  required String title,
  SwipeSourceOrigin origin = SwipeSourceOrigin.browse,
  String? returnRoute,
}) async {
  final kinds = query.kinds.isEmpty ? _media : query.kinds.intersection(_media);
  final canSeeAll =
      ref.read(storageAccessControllerProvider).value?.canSeeAllFiles ?? false;
  final visible = kinds.isEmpty
      ? null
      : query.copyWith(kinds: kinds).visible(canSeeAllFiles: canSeeAll);
  if (visible == null) {
    showSwipeSourceResult(
      context,
      const SwipeSourceNotOpened(SwipeSourceProblem.noMedia),
    );
    return;
  }
  final ids = <String>[];
  try {
    final dao = ref.read(mediaIndexDaoProvider);
    IndexCursor? after;
    do {
      final page = await dao.page(visible, after: after, limit: 1000);
      ids.addAll(page.items.map((f) => f.id));
      after = page.next;
    } while (after != null && ids.length <= kMaxSourceItems);
  } on Object {
    if (context.mounted) _showError(context);
    return;
  }
  if (!context.mounted) return;
  await swipeFileIds(
    context,
    ref,
    ids: ids,
    title: title,
    origin: origin,
    returnRoute: returnRoute,
  );
}

/// "Swipe these" for explicit [ids] (a B6 selection, a B3 group).
Future<void> swipeFileIds(
  BuildContext context,
  WidgetRef ref, {
  required List<String> ids,
  required String title,
  SwipeSourceOrigin origin = SwipeSourceOrigin.browse,
  String? returnRoute,
}) async {
  final SwipeSourceOpenResult result;
  try {
    result = await ref
        .read(swipeSourceLauncherProvider.notifier)
        .open(
          FilesSourceRequest(
            origin: origin,
            title: title.trim().isEmpty ? context.l10n.tabSwipe : title,
            fileIds: ids,
            returnRoute: returnRoute,
          ),
        );
  } on Object {
    if (context.mounted) _showError(context);
    return;
  }
  if (!context.mounted) return;
  if (result is SwipeSourceOpened) context.go(AppRoutes.swipe);
  showSwipeSourceResult(context, result);
}

void _showError(BuildContext context) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.swipeErrorGeneric)));

/// B6 "Swipe these": the selection in selection order (not cleared).
final SelectionAction swipeSelectionAction = SelectionAction(
  id: 'ss1.swipe',
  order: 5,
  label: (c) => c.l10n.browseSwipeThese,
  icon: Icons.swipe_outlined,
  run: (context, ref, ids) => swipeFileIds(
    context,
    ref,
    ids: ids,
    title: context.l10n.swipeSourceSelectionTitle,
    returnRoute: AppRoutes.browse,
  ),
);
