import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/platform/permissions/ensure_all_files_access.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/features/archive/data/archive_service.dart';
import 'package:kfm/features/archive/domain/archive_job.dart';
import 'package:kfm/features/archive/ui/archive_flow.dart';

/// ⋮ → View contents (TASK-B5): the archive view on the root navigator.
Future<void> viewZipContents(
  BuildContext context,
  WidgetRef ref,
  FileRef zip,
) async {
  if (!await ensureAllFilesAccess(context, ref) || !context.mounted) return;
  await Navigator.of(
    context,
    rootNavigator: true,
  ).push(ArchiveViewScreen.route(zip));
}

/// A zip's entries (lazy list: name, size, folder rows) with Extract here /
/// Extract to…; long-press an entry → "Extract this" (into the zip's
/// folder). Nothing inside the zip opens in KFM (extract first).
class ArchiveViewScreen extends ConsumerStatefulWidget {
  const new({required this.zip, super.key});

  static Route<void> route(FileRef zip) =>
      MaterialPageRoute(builder: (_) => ArchiveViewScreen(zip: zip));

  final FileRef zip;

  @override
  ConsumerState<ArchiveViewScreen> createState() => _ArchiveViewScreenState();
}

class _ArchiveViewScreenState extends ConsumerState<ArchiveViewScreen> {
  late final Future<ArchiveListing> _listing = ref
      .read(archiveServiceProvider)
      .list(widget.zip.path);
  ArchiveListing? _loaded;

  Future<void> _extract(
    ExtractDestination destination, {
    Set<String>? entries,
  }) => extractZip(
    context,
    ref,
    widget.zip,
    destination: destination,
    entries: entries,
    listing: _loaded,
  );

  Future<void> _entryMenu(ArchiveEntry entry) async {
    final extract = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(entry.name, maxLines: 2), enabled: false),
            ListTile(
              leading: const Icon(Icons.unarchive_outlined),
              title: Text(context.l10n.archiveExtractThis),
              onTap: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
    if (extract != true || !mounted) return;
    // A folder's name picks everything below it (prefix match in the
    // worker), so one name is enough.
    await _extract(ExtractDestination.zipFolder, entries: {entry.name});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    return Scaffold(
      appBar: AppBar(title: Text(widget.zip.name)),
      body: FutureBuilder<ArchiveListing>(
        future: _listing,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final error = snapshot.error;
            return _Message(
              error is ArchiveError
                  ? archiveErrorMessage(l10n, error)
                  : l10n.archiveCorrupt,
            );
          }
          final listing = snapshot.data;
          if (listing == null) {
            return const Center(child: CircularProgressIndicator());
          }
          _loaded = listing;
          if (listing.entries.isEmpty) return _Message(l10n.archiveEmpty);
          return Column(
            children: [
              Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: spacing * 2,
                  vertical: spacing,
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    l10n.archiveSummary(
                      listing.entries.length,
                      formatBytes(
                        listing.uncompressedTotal,
                        locale: l10n.localeName,
                      ),
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: listing.entries.length,
                  itemBuilder: (context, i) {
                    final e = listing.entries[i];
                    return ListTile(
                      leading: Icon(
                        e.isDirectory
                            ? Icons.folder_outlined
                            : Icons.insert_drive_file_outlined,
                      ),
                      title: Text(
                        e.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: e.isDirectory
                          ? null
                          : Text(formatBytes(e.size, locale: l10n.localeName)),
                      trailing: e.encrypted
                          ? const Icon(Icons.lock_outline)
                          : null,
                      onLongPress: () => unawaited(_entryMenu(e)),
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsetsDirectional.all(spacing * 2),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => unawaited(
                            _extract(ExtractDestination.chooseFolder),
                          ),
                          child: Text(l10n.archiveExtractTo),
                        ),
                      ),
                      SizedBox(width: spacing * 2),
                      Expanded(
                        child: FilledButton(
                          onPressed: () =>
                              unawaited(_extract(ExtractDestination.here)),
                          child: Text(l10n.archiveExtractHere),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsetsDirectional.all(context.tokens.spacing * 3),
      child: Text(text, textAlign: TextAlign.center),
    ),
  );
}
