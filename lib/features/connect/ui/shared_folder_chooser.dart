import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/platform/host_platform.dart';
import 'package:kfm/features/connect/data/shared_folder_fs.dart';
import 'package:path/path.dart' as p;

/// Opens the minimal folder chooser (TASK-N4) at the primary volume and
/// returns the chosen folder path, or null. Callers run
/// `ensureAllFilesAccess` first.
Future<String?> showSharedFolderChooser(BuildContext context) => Navigator.of(
  context,
).push<String>(MaterialPageRoute(builder: (_) => const SharedFolderChooser()));

/// Lists subfolders (no dot-folders, no `Android/data`/`obb`); "Share this
/// folder" picks the folder shown. Never goes above the volume root.
class SharedFolderChooser extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<SharedFolderChooser> createState() =>
      _SharedFolderChooserState();
}

class _SharedFolderChooserState extends ConsumerState<SharedFolderChooser> {
  late final SharedFolderFs _fs = ref.read(sharedFolderFsProvider);
  late String _path = _fs.primaryRoot;
  late Future<List<String>> _children = _fs.listSubfolders(_path);

  bool get _atRoot => _path == _fs.primaryRoot;

  void _open(String path) => setState(() {
    _path = path;
    _children = _fs.listSubfolders(path);
  });

  void _up() => _open(p.posix.dirname(_path));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final theme = Theme.of(context);
    // Windows (E1): the root is the user's folder, not "All storage".
    final shown = isWindowsHost
        ? _path
        : _atRoot
        ? l10n.sharedFolderAllStorage
        : _path.substring(_fs.primaryRoot.length + 1);
    return PopScope(
      canPop: _atRoot,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _up();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.folderChooserTitle)),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.all(spacing * 2),
              child: Text(
                shown,
                key: const ValueKey('chooser-path'),
                style: theme.textTheme.titleMedium,
              ),
            ),
            if (!_atRoot)
              ListTile(
                key: const ValueKey('chooser-up'),
                leading: const Icon(Icons.arrow_upward),
                title: Text(p.posix.basename(p.posix.dirname(_path))),
                onTap: _up,
              ),
            Expanded(
              child: FutureBuilder<List<String>>(
                future: _children,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Center(child: Text(l10n.folderChooserError));
                  }
                  final list = snap.data;
                  if (list == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (list.isEmpty) {
                    return Center(child: Text(l10n.folderChooserEmpty));
                  }
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, i) => ListTile(
                      key: ValueKey('chooser-${list[i]}'),
                      leading: const Icon(Icons.folder_outlined),
                      title: Text(p.posix.basename(list[i])),
                      onTap: () => _open(list[i]),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsetsDirectional.all(spacing * 2),
                child: FilledButton(
                  key: const ValueKey('chooser-share-this'),
                  onPressed: () => Navigator.of(context).pop(_path),
                  child: Text(l10n.folderChooserShareThis),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
