import 'package:drift/drift.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/tables/tags_table.dart';
import 'package:kfm/features/undo/domain/previous_state.dart';

part 'favorites_repository.g.dart';

/// Favorite files (TASK-P2).
@DriftAccessor(tables: [Favorites])
class FavoritesRepository extends DatabaseAccessor<AppDatabase>
    with _$FavoritesRepositoryMixin {
  new(super.attachedDatabase, {this._clock = DateTime.now});

  final DateTime Function() _clock;

  /// Run inside the undo row's transaction.
  Future<FavoritePreviousState> addInTransaction(String fileId) async {
    final was = await isFavorite(fileId);
    if (!was) {
      await into(favorites)
          .insert(FavoritesCompanion.insert(fileId: fileId, addedAt: _clock()));
    }
    return FavoritePreviousState(wasFavorite: was);
  }

  /// Undo: removes the favorite only if the swipe added it.
  Future<void> removeIfAdded(
    String fileId,
    FavoritePreviousState previous,
  ) async {
    if (previous.wasFavorite) return;
    await (delete(favorites)..where((f) => f.fileId.equals(fileId))).go();
  }

  Future<bool> isFavorite(String fileId) async =>
      (await (select(
        favorites,
      )..where((f) => f.fileId.equals(fileId))).getSingleOrNull()) !=
      null;
}
