// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selection_dao.dart';

// ignore_for_file: type=lint
mixin _$SelectionDaoMixin on DatabaseAccessor<AppDatabase> {
  $SelectionItemsTable get selectionItems => attachedDatabase.selectionItems;
  $SelectionSnapshotsTable get selectionSnapshots =>
      attachedDatabase.selectionSnapshots;
  $MediaIndexTable get mediaIndex => attachedDatabase.mediaIndex;
  SelectionDaoManager get managers => SelectionDaoManager(this);
}

class SelectionDaoManager {
  final _$SelectionDaoMixin _db;
  SelectionDaoManager(this._db);
  $$SelectionItemsTableTableManager get selectionItems =>
      $$SelectionItemsTableTableManager(
        _db.attachedDatabase,
        _db.selectionItems,
      );
  $$SelectionSnapshotsTableTableManager get selectionSnapshots =>
      $$SelectionSnapshotsTableTableManager(
        _db.attachedDatabase,
        _db.selectionSnapshots,
      );
  $$MediaIndexTableTableManager get mediaIndex =>
      $$MediaIndexTableTableManager(_db.attachedDatabase, _db.mediaIndex);
}
