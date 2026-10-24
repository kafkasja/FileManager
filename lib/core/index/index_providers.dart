import 'dart:io';

import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/media_change_source.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/core/index/media_indexer.dart';
import 'package:kfm/core/platform/permissions/storage_access.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/core/thumbs/thumbnail_cache.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'index_providers.g.dart';

@Riverpod(keepAlive: true)
MediaIndexDao mediaIndexDao(Ref ref) =>
    MediaIndexDao(ref.watch(appDatabaseProvider));

bool _canSeeAllFiles(Ref ref) =>
    ref.read(storageAccessControllerProvider).value?.canSeeAllFiles ?? false;

/// Live MediaStore changes. Empty off Android and in tests.
@Riverpod(keepAlive: true)
Raw<Stream<MediaChange>> mediaChanges(Ref ref) =>
    Platform.isAndroid ? photoManagerChanges() : const Stream.empty();

/// What a storage-access change means for the index.
enum IndexTrigger { none, start, fullScan }

/// App start with access → [IndexTrigger.start] (incremental if a full scan
/// exists). Any change of what is visible later (media granted / limited /
/// re-granted, All files access turned on) → a full scan: an incremental
/// scan would miss older files that just became visible (seen on a device:
/// a scan during the permission dialog recorded an empty index).
IndexTrigger indexTriggerFor(StorageAccess? before, StorageAccess? now) {
  if (now == null || !now.canUseSwipe) return IndexTrigger.none;
  if (before == null) return IndexTrigger.start;
  final widened =
      before.media != now.media ||
      (!before.canSeeAllFiles && now.canSeeAllFiles);
  return widened ? IndexTrigger.fullScan : IndexTrigger.none;
}

/// Starts once storage access allows it (and rescans when it widens). The shell reads it so it exists for the app's lifetime.
@Riverpod(keepAlive: true)
MediaIndexer mediaIndexer(Ref ref) {
  final indexer = MediaIndexer(
    dao: ref.watch(mediaIndexDaoProvider),
    source: ref.watch(fileSourceProvider),
    settings: ref.watch(settingsRepositoryProvider),
    canSeeAllFiles: () => _canSeeAllFiles(ref),
    changes: ref.watch(mediaChangesProvider),
  );
  ref
    ..onDispose(indexer.dispose)
    ..listen(storageAccessControllerProvider, (previous, next) {
      switch (indexTriggerFor(previous?.value, next.value)) {
        case IndexTrigger.start:
          indexer.start().ignore();
        case IndexTrigger.fullScan:
          indexer.fullScan().ignore();
        case IndexTrigger.none:
          break;
      }
    }, fireImmediately: true);
  return indexer;
}

@Riverpod(keepAlive: true)
Stream<IndexStatus> indexStatus(Ref ref) async* {
  final indexer = ref.watch(mediaIndexerProvider);
  yield indexer.current;
  yield* indexer.status;
}

/// One page of a view. Non-media is hidden while All files access is off
/// (the rows stay in the index). Views refresh on `mediaIndexChanges`.
@riverpod
Future<IndexPage> indexPage(
  Ref ref,
  IndexQuery query, {
  IndexCursor? after,
}) async {
  ref.watch(mediaIndexChangesProvider);
  final canSeeAll =
      ref.watch(storageAccessControllerProvider).value?.canSeeAllFiles ?? false;
  final visible = query.visible(canSeeAllFiles: canSeeAll);
  if (visible == null) return IndexPage.empty;
  return await ref.watch(mediaIndexDaoProvider).page(visible, after: after);
}

/// Ticks (debounced) whenever the index changes.
@Riverpod(keepAlive: true)
Stream<void> mediaIndexChanges(Ref ref) =>
    ref.watch(mediaIndexDaoProvider).watchChanges();

@Riverpod(keepAlive: true)
Future<ThumbnailCache> thumbnailCache(Ref ref) async {
  final base = await getApplicationCacheDirectory();
  final settings = ref.watch(settingsRepositoryProvider);
  return DiskThumbnailCache(
    dir: Directory('${base.path}/thumbs'),
    generator: photoManagerThumbnail,
    maxDiskBytes: () async =>
        await settings.read(AppSettings.thumbCacheMaxMb) * 1024 * 1024,
  );
}
