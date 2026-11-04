import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/platform/permissions/ensure_all_files_access.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/core/utils/read_future.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/data/path_guard.dart';
import 'package:kfm/features/connect/data/shared_folder_fs.dart';
import 'package:kfm/features/connect/domain/share_scope.dart';
import 'package:kfm/features/connect/ui/shared_folder_chooser.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';
import 'package:path/path.dart' as p;

/// Opens the shared-folder picker for one client (TASK-N4): after Accept
/// and from the share screen's client list. Saving replaces the client's
/// scope at once (the next request sees it).
Future<void> showSharedFoldersPicker(
  BuildContext context, {
  required String clientFingerprint,
  required String clientName,
}) => Navigator.of(context).push<void>(
  MaterialPageRoute(
    builder: (_) => SharedFoldersPicker(
      clientFingerprint: clientFingerprint,
      clientName: clientName,
    ),
  ),
);

/// A quick pick: label + candidate folders below the volume root (the first
/// that exists is used; Samsung keeps screenshots in DCIM).
typedef _Quick = ({
  String Function(AppLocalizations l10n) label,
  List<String> relative,
  bool media,
});

final List<_Quick> _quickPicks = [
  (label: (l) => l.sharedFolderCamera, relative: ['DCIM'], media: true),
  (label: (l) => l.sharedFolderPictures, relative: ['Pictures'], media: true),
  (
    label: (l) => l.sharedFolderScreenshots,
    relative: ['Pictures/Screenshots', 'DCIM/Screenshots'],
    media: true,
  ),
  (label: (l) => l.sharedFolderDownloads, relative: ['Download'], media: false),
  (
    label: (l) => l.sharedFolderDocuments,
    relative: ['Documents'],
    media: false,
  ),
];

class _Pick {
  new(this.label, {required this.readOnly});

  final String label;
  bool readOnly;
}

class SharedFoldersPicker extends ConsumerStatefulWidget {
  const new({
    required this.clientFingerprint,
    required this.clientName,
    super.key,
  });

  final String clientFingerprint;
  final String clientName;

  @override
  ConsumerState<SharedFoldersPicker> createState() =>
      _SharedFoldersPickerState();
}

class _SharedFoldersPickerState extends ConsumerState<SharedFoldersPicker> {
  /// Canonical path → pick, in pick order.
  final Map<String, _Pick> _picks = {};

  /// Existing quick picks (canonical path + label).
  List<({String path, String label})>? _quick;
  bool _allFiles = false;
  bool _saving = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    for (final r
        in ref
            .read(shareScopeStoreProvider)
            .scopeOf(widget.clientFingerprint)
            .roots) {
      _picks[r.path] = _Pick(r.label, readOnly: r.readOnly);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_load()));
  }

  Future<void> _load() async {
    final l10n = context.l10n;
    try {
      final access = await ref.readFuture(
        storageAccessControllerProvider.future,
      );
      final fs = ref.read(sharedFolderFsProvider);
      final guard = ref.read(pathGuardProvider);
      final quick = <({String path, String label})>[];
      for (final q in _quickPicks) {
        if (!q.media && !access.canSeeAllFiles) continue;
        for (final rel in q.relative) {
          final path = '${fs.primaryRoot}/$rel';
          if (await fs.exists(path)) {
            quick.add((
              path: await guard.canonicalise(path),
              label: q.label(l10n),
            ));
            break;
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _allFiles = access.canSeeAllFiles;
        _quick = quick;
        // N6: stored folders may have been seeded after initState.
        if (_picks.isEmpty) {
          for (final r
              in ref
                  .read(shareScopeStoreProvider)
                  .scopeOf(widget.clientFingerprint)
                  .roots) {
            _picks[r.path] = _Pick(r.label, readOnly: r.readOnly);
          }
        }
      });
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _choose() async {
    final l10n = context.l10n;
    if (!await ensureAllFilesAccess(context, ref) || !mounted) return;
    final chosen = await showSharedFolderChooser(context);
    if (chosen == null || !mounted) return;
    final guard = ref.read(pathGuardProvider);
    final fs = ref.read(sharedFolderFsProvider);
    final path = await guard.canonicalise(chosen);
    if (!mounted) return;
    final whole = path == await guard.canonicalise(fs.primaryRoot);
    if (whole && !await _confirmWholeStorage()) return;
    setState(() {
      _allFiles = true;
      _picks.putIfAbsent(
        path,
        () => _Pick(
          whole ? l10n.sharedFolderAllStorage : p.posix.basename(path),
          readOnly: true,
        ),
      );
    });
  }

  Future<bool> _confirmWholeStorage() async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.sharedFoldersWholeStorageTitle),
        content: Text(l10n.sharedFoldersWholeStorageBody),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const ValueKey('whole-storage-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.sharedFoldersWholeStorageConfirm),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final salt = await ref
          .read(deviceIdentityRepositoryProvider)
          .rootIdSalt();
      final roots = [
        for (final e in _picks.entries)
          SharedRoot(
            id: PathGuard.rootId(salt, e.key),
            path: e.key,
            label: e.value.label,
            readOnly: e.value.readOnly,
          ),
      ];
      ref
          .read(shareScopeStoreProvider)
          .set(widget.clientFingerprint, ShareScope(roots));
      // N6: a remembered device keeps these folders for next time (no-op
      // for others). A failure shows through the write queue's errors.
      ref
          .read(knownDevicesRepositoryProvider)
          .setAllowedRoots(widget.clientFingerprint, roots)
          .fireAndForget();
      if (mounted) Navigator.of(context).pop();
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final spacing = context.tokens.spacing;
    final quick = _quick;
    final quickPaths = {
      for (final q in quick ?? const <({String path, String label})>[]) q.path,
    };
    final custom = [
      for (final path in _picks.keys)
        if (!quickPaths.contains(path)) path,
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sharedFoldersTitle),
        actions: [
          TextButton(
            key: const ValueKey('shared-folders-done'),
            onPressed: _saving ? null : () => unawaited(_save()),
            child: Text(l10n.sharedFoldersDone),
          ),
        ],
      ),
      body: quick == null && _error == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsetsDirectional.symmetric(vertical: spacing),
              children: [
                ListTile(
                  title: Text(
                    l10n.sharedFoldersFor(widget.clientName),
                    style: theme.textTheme.titleMedium,
                  ),
                  subtitle: Text(l10n.sharedFoldersHint),
                ),
                if (!_allFiles)
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(l10n.sharedFoldersMediaOnly),
                  ),
                for (final q
                    in quick ?? const <({String path, String label})>[])
                  ..._folderTiles(q.path, q.label),
                for (final path in custom)
                  ..._folderTiles(path, _picks[path]!.label),
                ListTile(
                  key: const ValueKey('shared-folders-choose'),
                  leading: const Icon(Icons.create_new_folder_outlined),
                  title: Text(l10n.sharedFoldersChoose),
                  onTap: () => unawaited(_choose()),
                ),
                if (_error != null)
                  ListTile(
                    leading: Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.error,
                    ),
                    title: Text(l10n.folderChooserError),
                  ),
              ],
            ),
    );
  }

  List<Widget> _folderTiles(String path, String label) {
    final l10n = context.l10n;
    final pick = _picks[path];
    return [
      CheckboxListTile(
        key: ValueKey('shared-folder-$path'),
        value: pick != null,
        title: Text(label),
        secondary: const Icon(Icons.folder_outlined),
        onChanged: (on) => setState(() {
          if (on ?? false) {
            _picks[path] = _Pick(label, readOnly: true);
          } else {
            _picks.remove(path);
          }
        }),
      ),
      if (pick != null)
        SwitchListTile(
          key: ValueKey('shared-folder-write-$path'),
          contentPadding: EdgeInsetsDirectional.only(
            start: context.tokens.spacing * 9,
            end: context.tokens.spacing * 2,
          ),
          value: !pick.readOnly,
          title: Text(l10n.sharedFolderAllowChanges),
          onChanged: (on) => setState(() => pick.readOnly = !on),
        ),
    ];
  }
}
