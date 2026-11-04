import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show FutureProviderFamily;
import 'package:kfm/app/file_op_messages.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/file_names.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/files/folder_listing.dart';
import 'package:kfm/core/files/routing_file_source.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/source_rule.dart';
import 'package:kfm/core/platform/permissions/ensure_all_files_access.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/core/utils/read_future.dart';
import 'package:kfm/features/browse/ui/widgets/browse_parts.dart';
import 'package:kfm/features/cloud/data/cloud_providers.dart';
import 'package:kfm/features/cloud/domain/cloud_destination.dart';
import 'package:kfm/features/cloud/ui/cloud_labels.dart';
import 'package:kfm/features/external_storage/data/places_repository.dart';
import 'package:kfm/features/external_storage/domain/storage_place.dart';
import 'package:kfm/features/external_storage/ui/place_browser_screen.dart';
import 'package:kfm/features/external_storage/ui/place_labels.dart';
import 'package:kfm/features/external_storage/ui/saf_grant_flow.dart';
import 'package:kfm/features/folders/domain/move_target.dart';

/// What the picked folder is for: sets the default title and the label of
/// the "… here" button in the All folders section.
enum FolderPickerMode { choose, move, copy }

/// Picks a target folder for move/copy (TASK-P2; B4 extends it). Returns
/// the absolute path, or null when dismissed.
///
/// [disabledFolder] (B4 Move: the files' current folder) is shown greyed
/// out and can't be picked. [title] overrides the mode's default title.
Future<String?> showFolderPicker(
  BuildContext context, {
  String? disabledFolder,
  String? title,
  FolderPickerMode mode = FolderPickerMode.choose,
}) async {
  final picked = await showModalBottomSheet<MoveTarget>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _FolderPicker(
      disabledFolder: disabledFolder,
      title: title,
      mode: mode,
      includeCloud: false,
    ),
  );
  return switch (picked) {
    FolderTarget(:final path) => path,
    _ => null,
  };
}

/// B4's Move/Copy target (TASK-X3): the same sheet plus a "Cloud" group of
/// the active cloud destinations, shown only when at least one exists.
/// [showFolderPicker] (P2 swipe actions, archives, presets) never lists
/// cloud destinations.
Future<MoveTarget?> showMoveTargetPicker(
  BuildContext context, {
  String? disabledFolder,
  FolderPickerMode mode = FolderPickerMode.move,
  bool includeCloud = true,
}) => showModalBottomSheet<MoveTarget>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _FolderPicker(
    disabledFolder: disabledFolder,
    title: null,
    mode: mode,
    includeCloud: includeCloud,
  ),
);

const _maxRecent = 5;

/// Whether [path] is in DCIM / Pictures / Movies, where photos can be
/// moved without All files access (B4's New folder uses it too).
bool isMediaFolderPath(String path) {
  final rel = path.replaceFirst(RegExp(r'^/storage/[^/]+(/\d+)?/'), '');
  return _mediaRoots.any((r) => rel == r || rel.startsWith('$r/'));
}

/// Media folders MediaStore lets KFM move photos into without All files
/// access.
const _mediaRoots = ['DCIM', 'Pictures', 'Movies'];

final FutureProvider<List<({String path, int count})>> _folderSummaries =
    FutureProvider.autoDispose<List<({String path, int count})>>(
      (ref) => ref.watch(mediaIndexDaoProvider).folderSummaries(),
    );

/// B4 "All folders": the child folders of a folder (null = volumes) that
/// hold indexed files.
final FutureProviderFamily<List<FolderEntry>, String?> _childFolders =
    FutureProvider.autoDispose.family<List<FolderEntry>, String?>(
      (ref, parent) => ref
          .watch(mediaIndexDaoProvider)
          .folders(scope: IndexQuery.all, parent: parent),
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

class _FolderPicker extends ConsumerStatefulWidget {
  const new({
    required this.disabledFolder,
    required this.title,
    required this.mode,
    required this.includeCloud,
  });

  final String? disabledFolder;
  final String? title;
  final FolderPickerMode mode;

  /// X3: list active cloud destinations (B4 Move/Copy only).
  final bool includeCloud;

  @override
  ConsumerState<_FolderPicker> createState() => _FolderPickerState();
}

class _FolderPickerState extends ConsumerState<_FolderPicker> {
  /// The folder open in the All folders section; null = the start page.
  String? _at;

  bool get _browsing => _at != null;

  bool _isDisabled(String path) => path == widget.disabledFolder;

  /// U2: [path] is on a SAF place (listed by scanning, written via SAF).
  bool _isSaf(String path) => switch (ref.read(fileSourceProvider)) {
    final RoutingFileSource r => r.saf.locator.owns(path),
    _ => false,
  };

  /// U2 Places group: opens a removable place's root (after its one-time
  /// SAF grant where needed).
  Future<void> _openPlace(StoragePlace place) async {
    final root = place.rootPath;
    if (root == null) return;
    if (await ensurePlaceAccess(context, ref, place) == null) return;
    if (mounted) _open(root);
  }

  void _open(String? path) => setState(() => _at = path);

  void _up() {
    final at = _at;
    if (at == null) return;
    final root = volumeRootOf(at);
    _open(at == root ? null : at.substring(0, at.lastIndexOf('/')));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canSeeAll =
        ref.watch(storageAccessControllerProvider).value?.canSeeAllFiles ??
        false;
    final title =
        widget.title ??
        switch (widget.mode) {
          FolderPickerMode.choose => l10n.folderPickerTitle,
          FolderPickerMode.move => l10n.pickerMoveTitle,
          FolderPickerMode.copy => l10n.pickerCopyTitle,
        };

    Widget folder(String path, {int? count}) {
      final disabled = _isDisabled(path);
      final needsAccess = !canSeeAll && !_isMediaFolder(path) && !_isSaf(path);
      return ListTile(
        leading: const Icon(Icons.folder_outlined),
        title: Text(nameOfFolder(l10n, path)),
        enabled: !disabled,
        subtitle: Text(
          disabled
              ? l10n.pickerCurrentFolder
              : needsAccess
              ? l10n.folderNeedsAllFiles
              : count == null
              ? path
              : '${l10n.folderFileCount(count)} · $path',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () => _pick(path, needsAccess: needsAccess),
      );
    }

    final newFolder = ListTile(
      leading: const Icon(Icons.create_new_folder_outlined),
      title: Text(l10n.folderPickerNew),
      onTap: _newFolder,
    );

    final List<Widget> children;
    final at = _at;
    if (at == null) {
      final recent = ref.watch(_recentTargets).value ?? const [];
      final folders = ref.watch(_folderSummaries).value ?? const [];
      final volumes = ref.watch(_childFolders(null)).value ?? const [];
      // U2: SD cards and USB drives (cameras are read-only).
      final places = [
        for (final p
            in ref.watch(placesProvider).value ?? const <StoragePlace>[])
          if (p.isMounted &&
              p.isRemovable &&
              p.access != AccessMethod.mtp &&
              p.rootPath != null)
            p,
      ];
      // X3: only read when asked for (never for P2's swipe picker).
      final clouds = widget.includeCloud
          ? ref.watch(activeCloudDestinationsProvider).value ??
                const <CloudDestination>[]
          : const <CloudDestination>[];
      children = [
        newFolder,
        if (clouds.isNotEmpty) ...[
          _Header(l10n.cloudPickerGroup),
          for (final d in clouds)
            ListTile(
              key: ValueKey('picker-cloud-${d.id}'),
              leading: Icon(cloudProviderIcon(d.provider)),
              title: Text(d.label),
              onTap: () => Navigator.of(context).pop(CloudTarget(d.id)),
            ),
        ],
        if (recent.isNotEmpty) ...[
          _Header(l10n.folderPickerRecent),
          for (final path in recent) folder(path),
        ],
        if (places.isNotEmpty) ...[
          _Header(l10n.externalPlacesTitle),
          for (final p in places)
            _BrowseTile(
              label: placeLabel(l10n, p),
              icon: placeIcon(p.kind),
              onTap: () => _openPlace(p),
            ),
        ],
        if (volumes.isNotEmpty) ...[
          _Header(l10n.pickerAllFolders),
          for (final v in volumes)
            _BrowseTile(
              label: nameOfFolder(l10n, v.path),
              count: v.fileCount,
              icon: Icons.sd_storage_outlined,
              onTap: () => _open(v.path),
            ),
        ],
        if (folders.isNotEmpty) ...[
          _Header(l10n.folderPickerWithPhotos),
          for (final f in folders) folder(f.path, count: f.count),
        ],
      ];
    } else {
      final saf = _isSaf(at);
      final sub = saf
          ? const <FolderEntry>[]
          : ref.watch(_childFolders(at)).value ?? const [];
      final safSub = saf
          ? ref.watch(placeFolderProvider(at)).value?.folders ??
                const <FolderItem>[]
          : const <FolderItem>[];
      children = [
        _Breadcrumb(folder: at, onOpen: _open),
        newFolder,
        for (final f in sub)
          _BrowseTile(
            label: f.name,
            count: f.fileCount,
            icon: Icons.folder_outlined,
            onTap: () => _open(f.path),
          ),
        for (final f in safSub)
          _BrowseTile(
            label: f.name,
            icon: Icons.folder_outlined,
            onTap: () => _open(f.id),
          ),
      ];
    }

    final spacing = context.tokens.spacing;
    return PopScope(
      canPop: !_browsing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _up();
      },
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (context, scroll) => Column(
          children: [
            Expanded(
              child: ListView(
                controller: scroll,
                children: [
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      spacing * 2,
                      0,
                      spacing * 2,
                      spacing,
                    ),
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  ...children,
                ],
              ),
            ),
            if (at != null)
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsetsDirectional.all(spacing * 2),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isDisabled(at)
                          ? null
                          : () => _pick(
                              at,
                              needsAccess:
                                  !canSeeAll &&
                                  !_isMediaFolder(at) &&
                                  !_isSaf(at),
                            ),
                      child: Text(switch (widget.mode) {
                        FolderPickerMode.move => l10n.pickerMoveHere,
                        FolderPickerMode.copy => l10n.pickerCopyHere,
                        FolderPickerMode.choose => l10n.pickerChooseHere,
                      }),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(String path, {required bool needsAccess}) async {
    if (_isDisabled(path)) return;
    if (needsAccess && !await ensureAllFilesAccess(context, ref)) return;
    final recent = await ref.readFuture(_recentTargets.future);
    final next = [
      path,
      ...recent.where((p) => p != path),
    ].take(_maxRecent).toList();
    ref
        .read(settingsRepositoryProvider)
        .write(AppSettings.swipeRecentTargets, jsonEncode(next))
        .fireAndForget();
    if (mounted) Navigator.of(context).pop(FolderTarget(path));
  }

  /// Creates the folder inside the folder being shown (or the default
  /// parent on the start page) and picks it.
  Future<void> _newFolder() async {
    final parent = _at ?? ref.read<String>(defaultNewFolderParentProvider);
    final canSeeAll =
        ref.read(storageAccessControllerProvider).value?.canSeeAllFiles ??
        false;
    if (!canSeeAll &&
        !_isMediaFolder(parent) &&
        !_isSaf(parent) &&
        !await ensureAllFilesAccess(context, ref)) {
      return;
    }
    String? taken;
    while (true) {
      if (!mounted) return;
      final name = await showDialog<String>(
        context: context,
        builder: (_) => _NewFolderDialog(parent: parent, taken: taken),
      );
      if (name == null || !mounted) return;
      final String? path;
      try {
        path = await _createOrFind(parent, name);
      } on FileOpException catch (e) {
        // U3: e.g. refused while the place is being ejected. A dialog: a
        // snackbar would sit under this sheet.
        if (!mounted) return;
        final l10n = context.l10n;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            content: Text(folderOpFailureMessage(l10n, e, name)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(MaterialLocalizations.of(context).okButtonLabel),
              ),
            ],
          ),
        );
        return;
      }
      if (!mounted) return;
      if (path != null) {
        await _pick(path, needsAccess: false);
        return;
      }
      taken = name; // a file has that name: ask again
    }
  }

  /// Creates [name] in [parent]. If it exists, returns the existing folder
  /// with its real spelling (shared storage is case-insensitive: "camera"
  /// finds "Camera"), or null when a file has that name.
  Future<String?> _createOrFind(String parent, String name) async {
    final files = ref.read(fileSourceProvider);
    try {
      return await files.createFolder(parent, name);
    } on FileOpException catch (e) {
      if (e.failure != FileOpFailure.targetExists) rethrow;
    }
    final lower = name.toLowerCase();
    final known = await ref
        .read(mediaIndexDaoProvider)
        .folders(scope: IndexQuery.all, parent: parent);
    for (final f in known) {
      if (f.name.toLowerCase() == lower) return f.path;
    }
    if (await files.statPath('$parent/$name') != null) return null;
    // A folder the index doesn't know (empty, or only hidden files): its
    // spelling can't be looked up, so the typed one is used.
    return '$parent/$name';
  }

  static bool _isMediaFolder(String path) => isMediaFolderPath(path);
}

/// A folder row in All folders: tapping opens it (doesn't pick it).
class _BrowseTile extends StatelessWidget {
  const new({
    required this.label,
    required this.icon,
    required this.onTap,
    this.count,
  });

  final String label;

  /// Null = not known (U2 places and SAF folders aren't indexed).
  final int? count;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(label),
    subtitle: switch (count) {
      final c? => Text(context.l10n.folderFileCount(c)),
      null => null,
    },
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}

/// All folders › Internal storage › DCIM › Camera.
class _Breadcrumb extends StatelessWidget {
  const new({required this.folder, required this.onOpen});

  final String folder;
  final ValueChanged<String?> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final root = volumeRootOf(folder);
    final crumbs = <(String, String?)>[
      (l10n.pickerAllFolders, null),
      (nameOfFolder(l10n, root), root),
    ];
    if (folder != root) {
      final segments = folder.substring(root.length + 1).split('/');
      for (var i = 0; i < segments.length; i++) {
        crumbs.add((
          segments[i],
          '$root/${segments.sublist(0, i + 1).join('/')}',
        ));
      }
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: context.tokens.spacing,
      ),
      child: Row(
        children: [
          for (final (i, (label, path)) in crumbs.indexed) ...[
            if (i > 0) const Icon(Icons.chevron_right, size: 18),
            TextButton(
              onPressed: i == crumbs.length - 1 ? null : () => onOpen(path),
              child: Text(label),
            ),
          ],
        ],
      ),
    );
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
  const new({required this.parent, this.taken});

  final String parent;

  /// A name the last attempt found taken by a file: shown with an error.
  final String? taken;

  @override
  State<_NewFolderDialog> createState() => _NewFolderDialogState();
}

class _NewFolderDialogState extends State<_NewFolderDialog> {
  late final _name = TextEditingController(text: widget.taken);
  bool _invalid = false;
  late bool _taken = widget.taken != null;

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
      setState(() {
        _invalid = true;
        _taken = false;
      });
      return;
    }
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      // Scrolls on short screens (a phone in landscape, big text).
      scrollable: true,
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
              errorText: _invalid
                  ? l10n.folderNameInvalid
                  : _taken
                  ? l10n.nameExists
                  : null,
            ),
            onChanged: (_) {
              if (_taken) setState(() => _taken = false);
            },
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
