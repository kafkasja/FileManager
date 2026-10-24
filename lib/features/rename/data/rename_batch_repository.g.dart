// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rename_batch_repository.dart';

// ignore_for_file: type=lint
mixin _$RenameBatchRepositoryMixin on DatabaseAccessor<AppDatabase> {
  $SessionsTable get sessions => attachedDatabase.sessions;
  $RenameBatchesTable get renameBatches => attachedDatabase.renameBatches;
  $RenameBatchItemsTable get renameBatchItems =>
      attachedDatabase.renameBatchItems;
  RenameBatchRepositoryManager get managers =>
      RenameBatchRepositoryManager(this);
}

class RenameBatchRepositoryManager {
  final _$RenameBatchRepositoryMixin _db;
  RenameBatchRepositoryManager(this._db);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db.attachedDatabase, _db.sessions);
  $$RenameBatchesTableTableManager get renameBatches =>
      $$RenameBatchesTableTableManager(_db.attachedDatabase, _db.renameBatches);
  $$RenameBatchItemsTableTableManager get renameBatchItems =>
      $$RenameBatchItemsTableTableManager(
        _db.attachedDatabase,
        _db.renameBatchItems,
      );
}
