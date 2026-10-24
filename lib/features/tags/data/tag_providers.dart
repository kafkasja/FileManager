import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/files/file_source_provider.dart';
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
