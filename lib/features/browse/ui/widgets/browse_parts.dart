import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/source_rule.dart';
import 'package:kfm/core/platform/permissions/ensure_all_files_access.dart';
import 'package:kfm/features/browse/ui/browse_controller.dart';
import 'package:kfm/features/external_storage/data/known_places.dart';
import 'package:kfm/features/external_storage/ui/place_labels.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// A folder's display name; volume roots get a friendly one.
String nameOfFolder(AppLocalizations l10n, String path) {
  final root = volumeRootOf(path);
  if (path != root) return path.substring(path.lastIndexOf('/') + 1);
  if (RegExp(r'^/storage/emulated/\d+$').hasMatch(root)) {
    return l10n.browseInternalStorage;
  }
  // The name Places shows (U2 follow-up), else a generic one.
  final place = KnownPlaces.atRoot(root);
  if (place != null) return placeLabel(l10n, place);
  return l10n.browseExternalVolume(root.substring(root.lastIndexOf('/') + 1));
}

/// E4: a folder with its place, "Camera · Internal storage"; a volume's
/// root is just the place.
String folderLabel(AppLocalizations l10n, String folderPath) {
  final root = volumeRootOf(folderPath);
  final place = nameOfFolder(l10n, root);
  if (folderPath == root) return place;
  return l10n.folderLabel(nameOfFolder(l10n, folderPath), place);
}

/// "Grant access to see documents, downloads and hidden files".
class AccessBanner extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    return Padding(
      padding: EdgeInsets.all(spacing * 2),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(spacing * 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.browseNeedsAllFiles),
              SizedBox(height: spacing),
              FilledButton(
                onPressed: () => unawaited(ensureAllFilesAccess(context, ref)),
                child: Text(l10n.browseGrantAccess),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Other apps": files no rule recognised, grouped by folder ("Tapo —
/// DCIM"), largest first. [onOpen] shows one group's files.
class OtherGroups extends ConsumerWidget {
  const new({
    required this.scope,
    required this.onOpen,
    this.leading = const [],
    super.key,
  });

  final IndexQuery scope;
  final ValueChanged<String> onOpen;
  final List<Widget> leading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final groups = ref.watch(otherFoldersProvider(scope));
    return CustomScrollView(
      slivers: [
        ...leading,
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(context.tokens.spacing * 2),
            child: Text(l10n.browseOtherHint),
          ),
        ),
        switch (groups) {
          AsyncData(:final value) when value.isEmpty => SliverToBoxAdapter(
            child: Center(child: Text(l10n.browseEmpty)),
          ),
          AsyncData(:final value) => SliverList.builder(
            itemCount: value.length,
            itemBuilder: (context, i) {
              final entry = value[i];
              final isVolume = entry.path == volumeRootOf(entry.path);
              final parent = entry.path.substring(
                0,
                entry.path.lastIndexOf('/'),
              );
              return ListTile(
                key: ValueKey(entry.path),
                leading: const Icon(Icons.folder),
                title: Text(nameOfFolder(l10n, entry.path)),
                // A volume's own loose files have no parent folder.
                subtitle: isVolume ? null : Text(nameOfFolder(l10n, parent)),
                trailing: Text(l10n.browseFileCount(entry.fileCount)),
                onTap: () => onOpen(entry.path),
              );
            },
          ),
          AsyncError() => SliverToBoxAdapter(
            child: ListTile(
              title: Text(l10n.browseLoadError),
              trailing: TextButton(
                onPressed: () => ref.invalidate(otherFoldersProvider(scope)),
                child: Text(l10n.retry),
              ),
            ),
          ),
          _ => const SliverToBoxAdapter(child: LinearProgressIndicator()),
        },
      ],
    );
  }
}
