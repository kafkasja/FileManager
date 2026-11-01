import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/features/tags/data/favorites_repository.dart';
import 'package:kfm/features/tags/data/file_id_rekeyer.dart';
import 'package:kfm/features/tags/data/tag_repository.dart';
import 'package:kfm/features/tags/domain/tag.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tag_providers.g.dart';

@Riverpod(keepAlive: true)
TagRepository tagRepository(Ref ref) =>
    TagRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
FavoritesRepository favoritesRepository(Ref ref) =>
    FavoritesRepository(ref.watch(appDatabaseProvider));

/// All tags by id, kept loaded so the swipe path reads them synchronously.
@Riverpod(keepAlive: true)
Stream<Map<int, Tag>> tagsById(Ref ref) =>
    ref.watch(tagRepositoryProvider).watchAll();

/// Lives for the app's lifetime (watched in `App`).
@Riverpod(keepAlive: true)
FileIdRekeyer fileIdRekeyer(Ref ref) {
  final rekeyer = FileIdRekeyer(
    ref.watch(appDatabaseProvider),
    ref.watch(dbWriteQueueProvider),
  )..start(ref.watch(fileSourceProvider).idChanges);
  ref.onDispose(rekeyer.dispose);
  return rekeyer;
}

/// Every favorite file id (B9: ♡ state in the preview and ⋮ menu).
@Riverpod(keepAlive: true)
Stream<Set<String>> favoriteIds(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final q = db.selectOnly(db.favorites)..addColumns([db.favorites.fileId]);
  return q.watch().map(
    (rows) => {for (final r in rows) r.read(db.favorites.fileId)!},
  );
}

/// B9: one file's tag ids, live (the Tags sheet).
@riverpod
Stream<Set<int>> fileTagIds(Ref ref, String fileId) =>
    ref.watch(tagRepositoryProvider).watchTagIdsOf(fileId);

/// B9: visible files per tag (what each tag's view would show).
@riverpod
Stream<Map<int, int>> tagCounts(Ref ref) {
  final canSeeAll =
      ref.watch(storageAccessControllerProvider).value?.canSeeAllFiles ?? false;
  return ref
      .watch(mediaIndexDaoProvider)
      .watchTagCounts(IndexQuery.all.visible(canSeeAllFiles: canSeeAll));
}

/// B9: up to 4 newest visible favorites (the Favorites card).
@riverpod
Future<List<FileRef>> favoriteThumbs(Ref ref) async {
  ref.watch(indexAndTagChangesProvider);
  final canSeeAll =
      ref.watch(storageAccessControllerProvider).value?.canSeeAllFiles ?? false;
  final visible = const IndexQuery(favoritesOnly: true)
      .visible(canSeeAllFiles: canSeeAll);
  if (visible == null) return const [];
  final page = await ref.watch(mediaIndexDaoProvider).page(visible, limit: 4);
  return page.items;
}
