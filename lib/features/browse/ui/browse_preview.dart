import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/files/file_kind_resolver.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/core/thumbs/thumbnail.dart';
import 'package:kfm/features/browse/ui/browse_controller.dart';
import 'package:kfm/features/browse/ui/open_file.dart';
import 'package:kfm/features/browse/ui/text_viewer_screen.dart';
import 'package:kfm/features/selection/domain/selection_state.dart';
import 'package:kfm/features/selection/ui/selection_controller.dart';
import 'package:kfm/features/swipe/ui/file_viewer.dart';

/// Files the paged preview opens itself (TASK-B7); the rest go straight to
/// "Open with" on a Normal-mode tap.
bool opensInPreview(FileRef f) => f.isMedia || isTextFile(f);

/// Opens the preview over [query]'s loaded pages at [index] (B7). The
/// Browse query, paging and selection only change through the preview's
/// Select / Remove buttons. Completes with the last file shown.
Future<FileRef?> openResultsPreview(
  BuildContext context, {
  required IndexQuery query,
  required int index,
}) async {
  final source = FilePagesViewerSource(
    ProviderScope.containerOf(context, listen: false),
    query,
  );
  try {
    return await openPagedViewer(
      context,
      source: source,
      initialIndex: index,
      otherPage: previewOtherPage,
      actions: previewActions,
    );
  } finally {
    source.dispose();
  }
}

/// Pages through [ids] (null = the selection, in selection order) from the
/// file at [startAt]: B7 "Preview selected", taps on "View selected", B3
/// group thumbnails. [loaded] = files already read for the first
/// [loadedIds] ids (skips re-reading them).
Future<void> openSelectionPreview(
  BuildContext context,
  WidgetRef ref, {
  int startAt = 0,
  List<String>? ids,
  List<FileRef> loaded = const [],
  int loadedIds = 0,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  final IdsViewerSource source;
  try {
    final ordered =
        ids ??
        await ref.read(selectionControllerProvider.notifier).orderedIds();
    if (ordered.isEmpty) return;
    source = IdsViewerSource(
      ref.read(mediaIndexDaoProvider),
      ordered,
      items: loaded,
      loadedIds: loadedIds,
    );
    if (source.items.isEmpty) await source.loadMore();
  } on Object {
    // Rule 8: shown, not swallowed.
    messenger.showSnackBar(SnackBar(content: Text(l10n.browseLoadError)));
    return;
  }
  if (!context.mounted || source.items.isEmpty) return;
  try {
    await openPagedViewer(
      context,
      source: source,
      initialIndex: startAt.clamp(0, source.items.length - 1),
      otherPage: previewOtherPage,
      actions: previewActions,
    );
  } finally {
    source.dispose();
  }
}

/// [PagedViewerSource] over a `FilePages` provider: the same list the grid
/// shows, so pages the viewer loads land in the grid too.
class FilePagesViewerSource extends ChangeNotifier
    implements PagedViewerSource {
  new(this._container, this._query) {
    _sub = _container.listen(filePagesProvider(_query), (_, next) {
      final value = next.value;
      final items = value?.items ?? const <FileRef>[];
      final more = _more(value);
      if (identical(items, _items) && more == _hasMore) return;
      _items = items;
      _hasMore = more;
      notifyListeners();
    });
    final value = _sub.read().value;
    _items = value?.items ?? const [];
    _hasMore = _more(value);
  }

  final ProviderContainer _container;
  final IndexQuery _query;
  late final ProviderSubscription<AsyncValue<FilePagesState>> _sub;
  List<FileRef> _items = const [];
  bool _hasMore = false;

  /// A failed page stops paging (the grid shows its retry).
  static bool _more(FilePagesState? s) =>
      s != null && s.hasMore && s.loadMoreError == null;

  @override
  List<FileRef> get items => _items;

  @override
  bool get hasMore => _hasMore;

  @override
  Listenable get changes => this;

  @override
  Future<void> loadMore() =>
      _container.read(filePagesProvider(_query).notifier).loadMore();

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

/// [PagedViewerSource] over a list of ids (the selection, a B3 group), read
/// 200 at a time; ids that left the index are skipped.
class IdsViewerSource extends ChangeNotifier implements PagedViewerSource {
  new(this._dao, this._ids, {this._items = const [], int loadedIds = 0})
    : _loaded = loadedIds;

  static const pageSize = 200;

  final MediaIndexDao _dao;
  final List<String> _ids;
  List<FileRef> _items;
  int _loaded;
  bool _loading = false;
  bool _disposed = false;

  @override
  List<FileRef> get items => _items;

  @override
  bool get hasMore => _loaded < _ids.length;

  @override
  Listenable get changes => this;

  @override
  Future<void> loadMore() async {
    if (_loading || !hasMore) return;
    _loading = true;
    try {
      // Pruned ids give empty pages: keep reading until something shows.
      while (hasMore) {
        final end = (_loaded + pageSize).clamp(0, _ids.length);
        final page = await _dao.byIds(_ids.sublist(_loaded, end));
        if (_disposed) return;
        _loaded = end;
        if (page.isEmpty) continue;
        _items = List.unmodifiable([..._items, ...page]);
        break;
      }
      notifyListeners();
    } finally {
      _loading = false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Pages for files that aren't photos or videos: text as text, the rest an
/// info card with "Open with".
Widget previewOtherPage(BuildContext context, FileRef f) => isTextFile(f)
    ? Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: context.tokens.spacing * 2,
            ),
            child: Text(
              f.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(child: TextViewerBody(file: f)),
        ],
      )
    : FileInfoCard(file: f);

/// Type icon, the file's details and a big "Open with" (B7).
class FileInfoCard extends ConsumerWidget {
  const new({required this.file, super.key});

  final FileRef file;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = context.tokens.spacing;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: spacing * 2),
        Icon(fileKindIcon(file.kind), size: 72, color: scheme.primary),
        SizedBox(height: spacing * 2),
        Center(
          child: FilledButton.icon(
            onPressed: () => unawaited(openWithOrExplain(context, ref, file)),
            icon: const Icon(Icons.open_in_new),
            label: Text(context.l10n.openWith),
          ),
        ),
        SizedBox(height: spacing),
        Expanded(child: FileDetailsList(file: file)),
      ],
    );
  }
}

/// The shown page's buttons: Select / Remove (B6 rules) and, for photos and
/// videos, "Open with".
List<Widget> previewActions(BuildContext context, FileRef f) => [
  if (f.isMedia) _OpenWithAction(file: f),
  PreviewSelectButton(file: f),
];

class _OpenWithAction extends ConsumerWidget {
  const new({required this.file});

  final FileRef file;

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
    tooltip: context.l10n.openWith,
    style: IconButton.styleFrom(
      backgroundColor: Colors.black54,
      foregroundColor: Colors.white,
    ),
    icon: const Icon(Icons.open_in_new),
    onPressed: () => unawaited(openWithOrExplain(context, ref, file)),
  );
}

/// Normal / Select: "Select", or a disabled "Selected ✓" (no unselect).
/// Edit: "Remove from selection" with Undo. Selecting from Normal mode
/// doesn't switch modes.
class PreviewSelectButton extends ConsumerWidget {
  const new({required this.file, super.key});

  final FileRef file;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final (mode, selected) = ref.watch(
      selectionControllerProvider.select(
        (s) => (
          s.value?.mode ?? SelectionMode.normal,
          s.value?.contains(file.id) ?? false,
        ),
      ),
    );
    final controller = ref.read(selectionControllerProvider.notifier);
    if (mode == SelectionMode.edit) {
      if (!selected) return const SizedBox.shrink();
      return FilledButton.tonalIcon(
        onPressed: () {
          controller.remove(file);
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(l10n.selectionRemoved),
                persist: false,
                action: SnackBarAction(
                  label: l10n.undoAction,
                  onPressed: controller.undoRemove,
                ),
              ),
            );
        },
        icon: const Icon(Icons.remove_circle_outline),
        label: Text(l10n.previewRemove),
      );
    }
    if (selected) {
      return FilledButton.icon(
        onPressed: null,
        style: FilledButton.styleFrom(
          disabledBackgroundColor: Theme.of(context).colorScheme.primary,
          disabledForegroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
        icon: const Icon(Icons.check),
        label: Text(l10n.previewSelected),
      );
    }
    return FilledButton.icon(
      onPressed: () => controller.add(file),
      icon: const Icon(Icons.add_circle_outline),
      label: Text(l10n.previewSelect),
    );
  }
}
