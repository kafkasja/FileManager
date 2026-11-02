import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/files/folder_listing.dart';
import 'package:kfm/core/files/routing_file_source.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/features/browse/ui/open_file.dart';
import 'package:kfm/features/browse/ui/widgets/file_tile.dart';
import 'package:kfm/features/external_storage/data/places_repository.dart';
import 'package:kfm/features/folders/ui/local_job_flow.dart';
import 'package:kfm/features/swipe/domain/swipe_source.dart';
import 'package:kfm/features/swipe/ui/swipe_source_launcher.dart';

/// The browsable source behind [folder] (SAF or camera), or null.
BrowsableSource? browsableSourceFor(FileSource fs, String folder) =>
    switch (fs) {
      final RoutingFileSource r => folder.startsWith('mtp:') ? r.mtp : r.saf,
      final BrowsableSource b => b,
      _ => null,
    };

final FutureProviderFamily<FolderListing, String> placeFolderProvider =
    FutureProvider.autoDispose.family<FolderListing, String>((
      ref,
      folder,
    ) async {
      // A fresh grant reaches the SAF source through the places list.
      ref.watch(placesProvider);
      final source = browsableSourceFor(ref.watch(fileSourceProvider), folder);
      if (source == null) return FolderListing.empty;
      return await source.listChildren(folder);
    });

enum _Sort { name, date, size }

/// Browses an SD card / USB drive reached through SAF, or a camera
/// (TASK-U2): scan-based (these places aren't in the F5 index). Folders
/// first, then files; sort, a photos/videos filter, Copy to / Move to /
/// Delete per file and "Swipe this folder".
class PlaceBrowserScreen extends ConsumerStatefulWidget {
  const new({required this.root, required this.title, super.key});

  /// The place's root folder: a volume path (SAF) or `mtp:<device>`.
  final String root;
  final String title;

  @override
  ConsumerState<PlaceBrowserScreen> createState() => _PlaceBrowserState();
}

class _PlaceBrowserState extends ConsumerState<PlaceBrowserScreen> {
  /// Open folders below the root: (id, name).
  final List<FolderItem> _stack = [];
  _Sort _sort = _Sort.name;
  var _mediaOnly = false;

  String get _folder => _stack.isEmpty ? widget.root : _stack.last.id;

  void _open(FolderItem f) => setState(() => _stack.add(f));

  List<FileRef> _sorted(List<FileRef> files) {
    final out = [
      for (final f in files)
        if (!_mediaOnly || f.isMedia) f,
    ];
    switch (_sort) {
      case _Sort.name:
        out.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case _Sort.date:
        out.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
      case _Sort.size:
        out.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final listing = ref.watch(placeFolderProvider(_folder));
    final readOnly = widget.root.startsWith('mtp:');
    return PopScope(
      canPop: _stack.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(_stack.removeLast);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_stack.isEmpty ? widget.title : _stack.last.name),
          actions: [
            IconButton(
              key: const ValueKey('place-swipe-folder'),
              tooltip: l10n.externalSwipeFolder,
              icon: const Icon(Icons.swipe_outlined),
              onPressed: listing.value == null
                  ? null
                  : () => unawaited(_swipeFolder(listing.value!)),
            ),
            PopupMenuButton<Object>(
              onSelected: (v) => setState(() {
                if (v is _Sort) _sort = v;
                if (v is bool) _mediaOnly = v;
              }),
              itemBuilder: (_) => [
                CheckedPopupMenuItem(
                  value: _Sort.name,
                  checked: _sort == _Sort.name,
                  child: Text(l10n.externalSortByName),
                ),
                CheckedPopupMenuItem(
                  value: _Sort.date,
                  checked: _sort == _Sort.date,
                  child: Text(l10n.externalSortByDate),
                ),
                CheckedPopupMenuItem(
                  value: _Sort.size,
                  checked: _sort == _Sort.size,
                  child: Text(l10n.externalSortBySize),
                ),
                const PopupMenuDivider(),
                CheckedPopupMenuItem(
                  value: false,
                  checked: !_mediaOnly,
                  child: Text(l10n.externalShowAll),
                ),
                CheckedPopupMenuItem(
                  value: true,
                  checked: _mediaOnly,
                  child: Text(l10n.externalShowMedia),
                ),
              ],
            ),
          ],
        ),
        body: switch (listing) {
          AsyncValue(:final value?) => _body(value, readOnly),
          AsyncError() => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.externalFolderError),
                TextButton(
                  onPressed: () => ref.invalidate(placeFolderProvider(_folder)),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }

  Widget _body(FolderListing listing, bool readOnly) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final files = _sorted(listing.files);
    final folders = [...listing.folders]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    if (folders.isEmpty && files.isEmpty) {
      return Center(child: Text(l10n.externalFolderEmpty));
    }
    return RefreshIndicator(
      onRefresh: () => ref.refresh(placeFolderProvider(_folder).future),
      child: ListView(
        padding: EdgeInsetsDirectional.only(bottom: spacing * 2),
        children: [
          if (readOnly)
            ListTile(
              dense: true,
              leading: const Icon(Icons.lock_outline),
              title: Text(l10n.externalReadOnly),
            ),
          for (final f in folders)
            ListTile(
              key: ValueKey('place-folder-${f.id}'),
              leading: const Icon(Icons.folder_outlined),
              title: Text(f.name),
              onTap: () => _open(f),
            ),
          for (final f in files)
            FileListRow(
              key: ValueKey('place-file-${f.id}'),
              file: f,
              onTap: () => unawaited(openFile(context, ref, f)),
              menu: _menu(f),
            ),
        ],
      ),
    );
  }

  Widget _menu(FileRef f) {
    final l10n = context.l10n;
    final fs = ref.watch(fileSourceProvider);
    final canMove =
        fs.supports(FileOp.move, f) &&
        fs.supports(FileOp.trash, f);
    final canDelete =
        fs.supports(FileOp.trash, f) || fs.supports(FileOp.deletePermanently, f);
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (v) => unawaited(switch (v) {
        'copy' => _copyOrMove(f, move: false),
        'move' => _copyOrMove(f, move: true),
        _ => _delete(f),
      }),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'copy',
          enabled: fs.supports(FileOp.copy, f),
          child: Text(l10n.externalCopyTo),
        ),
        PopupMenuItem(
          value: 'move',
          enabled: canMove,
          child: Text(l10n.externalMoveTo),
        ),
        PopupMenuItem(
          value: 'delete',
          enabled: canDelete,
          child: Text(l10n.externalDelete),
        ),
      ],
    );
  }

  Future<void> _copyOrMove(FileRef f, {required bool move}) async {
    await pickTargetAndStartLocalJob(context, ref, [f], move: move);
    if (mounted) ref.invalidate(placeFolderProvider(_folder));
  }

  Future<void> _delete(FileRef f) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final fs = ref.read(fileSourceProvider);
    try {
      if (fs.supports(FileOp.trash, f)) {
        final r = await fs.trashBatch([f]);
        if (r.trashed.isEmpty) {
          throw r.failed[f.id] ??
              const FileOpException(FileOpFailure.userCancelled, 'declined');
        }
      } else {
        await fs.deletePermanentlyBatch([f]);
      }
      messenger.showSnackBar(SnackBar(content: Text(l10n.externalDeleted(1))));
    } on FileOpException {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.externalDeleteFailed)),
      );
    }
    if (mounted) ref.invalidate(placeFolderProvider(_folder));
  }

  /// SS1 "Swipe this folder": photos and videos of this folder; an SD photo
  /// MediaStore knows keeps its `ms:` id, so trash and labels match the
  /// main deck.
  Future<void> _swipeFolder(FolderListing listing) async {
    final l10n = context.l10n;
    final media = [
      for (final f in listing.files)
        if (f.isMedia) f,
    ];
    if (media.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.externalSwipeFolderEmpty)));
      return;
    }
    final known = _folder.startsWith('mtp:')
        ? const <String, String>{}
        : await ref.read(mediaIndexDaoProvider).idsByNameIn(media.first.folderPath);
    final request = FilesSourceRequest(
      origin: SwipeSourceOrigin.externalPlace,
      title: swipeSourceTitle(
        _stack.isEmpty ? widget.title : _stack.last.name,
      ),
      fileIds: [for (final f in media) known[f.name] ?? f.id],
    );
    final SwipeSourceOpenResult r;
    try {
      r = await ref.read(swipeSourceLauncherProvider.notifier).open(request);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.swipeErrorGeneric)));
      }
      return;
    }
    if (!mounted) return;
    if (r is SwipeSourceOpened) context.go(AppRoutes.swipe);
    showSwipeSourceResult(context, r);
  }
}
