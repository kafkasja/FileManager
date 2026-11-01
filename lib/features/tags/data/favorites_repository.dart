import 'package:drift/drift.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/tables/tags_table.dart';
import 'package:kfm/features/undo/domain/previous_state.dart';

part 'favorites_repository.g.dart';

const _chunk = 500;

Iterable<List<T>> _chunks<T>(List<T> items) sync* {
  for (var i = 0; i < items.length; i += _chunk) {
    yield items.sublist(
      i,
      i + _chunk > items.length ? items.length : i + _chunk,
    );
  }
}

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

  Stream<bool> watchIsFavorite(String fileId) =>
      (select(favorites)..where((f) => f.fileId.equals(fileId))).watch().map(
        (rows) => rows.isNotEmpty,
      );

  // ---- B9 bulk writes (chunks of 500, one transaction each) ----

  /// Favorites [fileIds]; returns the ids newly favorited (for undo).
  Future<List<String>> addFiles(List<String> fileIds) {
    final ids = fileIds.toSet().toList();
    return transaction(() async {
      final added = <String>[];
      final now = _clock();
      for (final chunk in _chunks(ids)) {
        final existing = await (select(
          favorites,
        )..where((f) => f.fileId.isIn(chunk))).get();
        final had = {for (final r in existing) r.fileId};
        final missing = [
          for (final id in chunk)
            if (!had.contains(id)) id,
        ];
        if (missing.isEmpty) continue;
        await batch(
          (b) => b.insertAll(favorites, [
            for (final id in missing)
              FavoritesCompanion.insert(fileId: id, addedAt: now),
          ]),
        );
        added.addAll(missing);
      }
      return added;
    });
  }

  /// Unfavorites [fileIds]; returns the removed rows (for undo).
  Future<List<FavoriteRow>> removeFiles(List<String> fileIds) {
    final ids = fileIds.toSet().toList();
    return transaction(() async {
      final removed = <FavoriteRow>[];
      for (final chunk in _chunks(ids)) {
        final rows = await (select(
          favorites,
        )..where((f) => f.fileId.isIn(chunk))).get();
        if (rows.isEmpty) continue;
        await (delete(favorites)..where((f) => f.fileId.isIn(chunk))).go();
        removed.addAll(rows);
      }
      return removed;
    });
  }

  /// Undo of [removeFiles] (keeps added_at).
  Future<void> reinsert(List<FavoriteRow> rows) async {
    if (rows.isEmpty) return;
    await transaction(() async {
      for (final part in _chunks(rows)) {
        await batch(
          (b) => b.insertAll(favorites, part, mode: InsertMode.insertOrIgnore),
        );
      }
    });
  }

  /// Undo of [addFiles]: unfavorites exactly [fileIds].
  Future<void> removeIds(List<String> fileIds) async {
    if (fileIds.isEmpty) return;
    await transaction(() async {
      for (final chunk in _chunks(fileIds)) {
        await (delete(favorites)..where((f) => f.fileId.isIn(chunk))).go();
      }
    });
  }

  /// How many of [fileIds] are favorites.
  Future<int> countAmong(List<String> fileIds) async {
    final ids = fileIds.toSet().toList();
    final count = favorites.fileId.count();
    var total = 0;
    for (final chunk in _chunks(ids)) {
      final row =
          await (selectOnly(favorites)
                ..addColumns([count])
                ..where(favorites.fileId.isIn(chunk)))
              .getSingle();
      total += row.read(count) ?? 0;
    }
    return total;
  }
}
