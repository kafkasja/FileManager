import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/features/browse/ui/browse_preview.dart';
import 'package:kfm/features/browse/ui/open_file.dart';
import 'package:kfm/features/browse/ui/widgets/file_tile.dart';
import 'package:kfm/features/selection/domain/selection_state.dart';
import 'package:kfm/features/selection/ui/drag_select_detector.dart';
import 'package:kfm/features/selection/ui/selection_bar.dart';
import 'package:kfm/features/selection/ui/selection_controller.dart';

/// "View selected" (TASK-B6): the selection in selection order, 200 files
/// per page, with the same mode rules as Browse.
class SelectedFilesScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<SelectedFilesScreen> createState() =>
      _SelectedFilesScreenState();
}

class _SelectedFilesScreenState extends ConsumerState<SelectedFilesScreen> {
  static const _pageSize = 200;

  List<String>? _ids;
  List<FileRef> _items = const [];
  bool _loading = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  Future<void> _start() async {
    try {
      final ids = await ref
          .read(selectionControllerProvider.notifier)
          .orderedIds();
      if (!mounted) return;
      setState(() => _ids = ids);
      await _loadMore();
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _loadMore() async {
    final ids = _ids;
    if (ids == null || _loading) return;
    // Pages are cut from the id list; missing (pruned) ids are skipped.
    final start = _loaded;
    if (start >= ids.length) return;
    _loading = true;
    try {
      final end = start + _pageSize > ids.length
          ? ids.length
          : start + _pageSize;
      final page = await ref
          .read(mediaIndexDaoProvider)
          .byIds(ids.sublist(start, end));
      if (!mounted) return;
      setState(() {
        _loaded = end;
        _items = List.unmodifiable([..._items, ...page]);
      });
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      _loading = false;
    }
  }

  int _loaded = 0;

  /// B7: pages through the selection from file [i], reusing what's loaded.
  void _preview(int i) => unawaited(
    openSelectionPreview(
      context,
      ref,
      startAt: i,
      ids: _ids,
      loaded: _items,
      loadedIds: _loaded,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final count =
        ref.watch(selectionControllerProvider.select((s) => s.value?.count)) ??
        0;
    final mode =
        ref.watch(selectionControllerProvider.select((s) => s.value?.mode)) ??
        SelectionMode.normal;
    final selector = ref.read(selectionControllerProvider.notifier);
    final ids = _ids;
    final Widget body;
    if (_error != null) {
      body = Center(child: Text(l10n.browseLoadError));
    } else if (ids == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (ids.isEmpty) {
      body = Center(child: Text(l10n.browseEmpty));
    } else {
      body = GridView.builder(
        padding: EdgeInsets.all(spacing / 4),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 128,
          mainAxisSpacing: spacing / 4,
          crossAxisSpacing: spacing / 4,
        ),
        itemCount: _items.length,
        itemBuilder: (context, i) {
          if (i >= _items.length - 60) {
            scheduleMicrotask(() => unawaited(_loadMore()));
          }
          final f = _items[i];
          return SelectableFile(
            key: ValueKey(f.id),
            index: i,
            items: _items,
            onOpen: () => opensInPreview(f)
                ? _preview(i)
                : unawaited(openWithOrExplain(context, ref, f)),
            onPreview: () => _preview(i),
            builder: (context, onTap) => FileGridTile(file: f, onTap: onTap),
          );
        },
      );
    }
    return PopScope(
      canPop: mode != SelectionMode.edit,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) selector.exitEdit();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.selectionViewTitle(count))),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SelectionHint(),
            Expanded(child: body),
            const SelectionBar(),
          ],
        ),
      ),
    );
  }
}
