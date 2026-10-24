import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/file_names.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/platform/permissions/ensure_all_files_access.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';

/// Picks a target folder for move/copy (TASK-P2; B4 extends it). Returns
/// the absolute path, or null when dismissed.
Future<String?> showFolderPicker(BuildContext context) =>
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _FolderPicker(),
    );

const _maxRecent = 5;

/// Media folders MediaStore lets KFM move photos into without All files
/// access.
const _mediaRoots = ['DCIM', 'Pictures', 'Movies'];

final FutureProvider<List<({String path, int count})>> _folderSummaries =
    FutureProvider.autoDispose<List<({String path, int count})>>(
      (ref) => ref.watch(mediaIndexDaoProvider).folderSummaries(),
    );

final FutureProvider<List<String>> _recentTargets =
    FutureProvider.autoDispose<List<String>>((ref) async {
      final raw = await ref
          .watch(settingsRepositoryProvider)
          .read(AppSettings.swipeRecentTargets);
      return switch (_decode(raw)) {
        final List<Object?> list => list.whereType<String>().toList(),
        _ => const <String>[],
      };
    });

Object? _decode(String raw) {
  try {
    return jsonDecode(raw);
  } on FormatException {
    return null;
  }
}

class _FolderPicker extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final recent = ref.watch(_recentTargets).value ?? const [];
    final folders = ref.watch(_folderSummaries).value ?? const [];
    final canSeeAll =
        ref.watch(storageAccessControllerProvider).value?.canSeeAllFiles ??
        false;
    Widget folder(String path, {int? count}) {
      final needsAccess = !canSeeAll && !_isMediaFolder(path);
      return ListTile(
        leading: const Icon(Icons.folder_outlined),
        title: Text(_leaf(path)),
        subtitle: Text(
          needsAccess
              ? l10n.folderNeedsAllFiles
              : count == null
              ? path
              : '${l10n.folderFileCount(count)} · $path',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () => _pick(context, ref, path, needsAccess: needsAccess),
      );
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
            child: Text(
              l10n.folderPickerTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.create_new_folder_outlined),
            title: Text(l10n.folderPickerNew),
            onTap: () => _newFolder(context, ref),
          ),
          if (recent.isNotEmpty) ...[
            _Header(l10n.folderPickerRecent),
            for (final path in recent) folder(path),
          ],
          if (folders.isNotEmpty) ...[
            _Header(l10n.folderPickerWithPhotos),
            for (final f in folders) folder(f.path, count: f.count),
          ],
        ],
      ),
    );
  }

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    String path, {
    required bool needsAccess,
  }) async {
    if (needsAccess && !await ensureAllFilesAccess(context, ref)) return;
    final recent = await ref.read(_recentTargets.future);
    final next = [
      path,
      ...recent.where((p) => p != path),
    ].take(_maxRecent).toList();
    ref
        .read(settingsRepositoryProvider)
        .write(AppSettings.swipeRecentTargets, jsonEncode(next))
        .fireAndForget();
    if (context.mounted) Navigator.of(context).pop(path);
  }

  Future<void> _newFolder(BuildContext context, WidgetRef ref) async {
    final parent = ref.read(defaultNewFolderParentProvider);
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _NewFolderDialog(parent: parent),
    );
    if (name == null || !context.mounted) return;
    String path;
    try {
      path = await ref.read(fileSourceProvider).createFolder(parent, name);
    } on FileOpException catch (e) {
      if (e.failure != FileOpFailure.targetExists) rethrow;
      path = '$parent/$name';
    }
    if (context.mounted) await _pick(context, ref, path, needsAccess: false);
  }

  static bool _isMediaFolder(String path) {
    final rel = path.replaceFirst(RegExp(r'^/storage/[^/]+(/\d+)?/'), '');
    return _mediaRoots.any((r) => rel == r || rel.startsWith('$r/'));
  }

  static String _leaf(String path) {
    final parts = path.split('/').where((p) => p.isNotEmpty);
    return parts.isEmpty ? path : parts.last;
  }
}

class _Header extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: Theme.of(context).colorScheme.primary),
    ),
  );
}

class _NewFolderDialog extends StatefulWidget {
  const new({required this.parent});

  final String parent;

  @override
  State<_NewFolderDialog> createState() => _NewFolderDialogState();
}

class _NewFolderDialogState extends State<_NewFolderDialog> {
  final _name = TextEditingController();
  bool _invalid = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    try {
      validateFileName(name);
    } on FileOpException {
      setState(() => _invalid = true);
      return;
    }
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.folderPickerNewTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.folderPickerNewIn(widget.parent)),
          TextField(
            controller: _name,
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n.folderNameHint,
              errorText: _invalid ? l10n.folderNameInvalid : null,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.create)),
      ],
    );
  }
}
