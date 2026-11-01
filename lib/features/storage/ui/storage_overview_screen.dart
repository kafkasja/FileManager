import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/platform/permissions/ensure_all_files_access.dart';
import 'package:kfm/core/thumbs/thumbnail.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/features/browse/ui/open_file.dart';
import 'package:kfm/features/storage/domain/storage_category.dart';
import 'package:kfm/features/storage/ui/storage_providers.dart';
import 'package:kfm/features/swipe/domain/swipe_source.dart';
import 'package:kfm/features/swipe/ui/swipe_source_launcher.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// Where the space goes (TASK-C1): used/free, categories with "Clean up"
/// (SS1 filter source), the 20 biggest files.
class StorageOverviewScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final overview = ref.watch(storageOverviewProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.storageOverviewTitle)),
      body: switch (overview) {
        AsyncValue(:final value?) => _Body(overview: value),
        AsyncError() => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.browseLoadError),
              TextButton(
                onPressed: () => ref.invalidate(storageOverviewProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

String storageCategoryName(
  AppLocalizations l10n,
  StorageCategory c, {
  String? locale,
}) => switch (c.id) {
  StorageCategoryId.videos => l10n.storageCatVideos,
  StorageCategoryId.screenshots => l10n.storageCatScreenshots,
  StorageCategoryId.bigFiles => l10n.storageCatBigFiles(
    formatBytes(c.filter.minSizeBytes ?? 0, locale: locale),
  ),
  StorageCategoryId.whatsapp => l10n.storageCatWhatsapp,
  StorageCategoryId.downloads => l10n.storageCatDownloads,
};

class _Body extends ConsumerWidget {
  const new({required this.overview});

  final StorageOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final space = overview.space;
    return ListView(
      padding: EdgeInsetsDirectional.symmetric(vertical: spacing),
      children: [
        Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: spacing * 2),
          child: space == null
              ? Text(l10n.storageSpaceUnknown, style: text.bodyMedium)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.storageUsedFree(
                        formatBytes(space.usedBytes, locale: locale),
                        formatBytes(space.freeBytes, locale: locale),
                      ),
                      style: text.titleSmall,
                    ),
                    SizedBox(height: spacing),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(spacing),
                      child: LinearProgressIndicator(
                        value: space.totalBytes <= 0
                            ? 0
                            : space.usedBytes / space.totalBytes,
                        minHeight: 10,
                        backgroundColor: scheme.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
        ),
        if (overview.scanning)
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              spacing * 2,
              spacing * 2,
              spacing * 2,
              0,
            ),
            child: Row(
              children: [
                const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: spacing),
                Expanded(child: Text(l10n.storageScanning)),
              ],
            ),
          ),
        SizedBox(height: spacing),
        for (final total in overview.categories)
          _CategoryRow(total: total, allFilesAccess: overview.allFilesAccess),
        // C2: similar and blurry photos.
        ListTile(
          leading: const Icon(Icons.burst_mode_outlined),
          title: Text(l10n.similarTitle),
          subtitle: Text(l10n.similarStorageHint),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => unawaited(context.push<void>(AppRoutes.similar)),
        ),
        Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: spacing * 2,
            vertical: spacing,
          ),
          child: Text(l10n.storageOverlapNote, style: text.bodySmall),
        ),
        if (overview.biggestFiles.isNotEmpty) ...[
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              spacing * 2,
              spacing * 2,
              spacing * 2,
              spacing,
            ),
            child: Text(l10n.storageBiggestFiles, style: text.titleSmall),
          ),
          for (final f in overview.biggestFiles) _BigFileRow(file: f),
        ],
      ],
    );
  }
}

class _CategoryRow extends ConsumerWidget {
  const new({required this.total, required this.allFilesAccess});

  final StorageCategoryTotal total;
  final bool allFilesAccess;

  Future<void> _cleanUp(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final messenger = ScaffoldMessenger.of(context);
    final SwipeSourceOpenResult r;
    try {
      r = await ref
          .read(swipeSourceLauncherProvider.notifier)
          .open(
            FilterSourceRequest(
              origin: SwipeSourceOrigin.storage,
              title: storageCategoryName(l10n, total.category, locale: locale),
              filter: total.category.filter,
              returnRoute: AppRoutes.storage,
            ),
          );
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(l10n.swipeErrorGeneric)));
      return;
    }
    if (!context.mounted) return;
    if (r is SwipeSourceOpened) context.go(AppRoutes.swipe);
    showSwipeSourceResult(context, r);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final c = total.category;
    final hints = <String>[
      if (total.swipeableCount > 0 && total.swipeableCount < total.fileCount)
        l10n.storageCleanUpMediaOnly,
      if (c.id == StorageCategoryId.whatsapp && allFilesAccess)
        l10n.storageWhatsappHint,
    ];
    return ListTile(
      leading: Icon(_icon(c.id)),
      title: Text(storageCategoryName(l10n, c, locale: locale)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Without access the totals are incomplete: the prompt replaces
          // them (no counts of files the user can't see).
          if (!total.needsAccess)
            Text(
              l10n.storageCategorySummary(
                total.fileCount,
                formatBytes(total.totalBytes, locale: locale),
              ),
            ),
          for (final h in hints)
            Text(h, style: Theme.of(context).textTheme.bodySmall),
          if (total.needsAccess)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () => unawaited(ensureAllFilesAccess(context, ref)),
                child: Text(l10n.storageNeedsAccess),
              ),
            ),
        ],
      ),
      isThreeLine: hints.isNotEmpty || total.needsAccess,
      trailing: total.swipeableCount > 0
          ? FilledButton.tonal(
              onPressed: () => unawaited(_cleanUp(context, ref)),
              child: Text(l10n.storageCleanUp),
            )
          : null,
    );
  }

  static IconData _icon(StorageCategoryId id) => switch (id) {
    StorageCategoryId.videos => Icons.videocam_outlined,
    StorageCategoryId.screenshots => Icons.screenshot_outlined,
    StorageCategoryId.bigFiles => Icons.sd_storage_outlined,
    StorageCategoryId.whatsapp => Icons.chat_outlined,
    StorageCategoryId.downloads => Icons.download_outlined,
  };
}

class _BigFileRow extends ConsumerWidget {
  const new({required this.file});

  final FileRef file;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return ListTile(
      leading: SizedBox.square(
        dimension: 48,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(context.tokens.radius / 2),
          child: Thumbnail(file: file),
        ),
      ),
      title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(formatBytes(file.sizeBytes, locale: locale)),
      onTap: () => unawaited(openFile(context, ref, file)),
    );
  }
}
