// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_index_dao.dart';

// ignore_for_file: type=lint
mixin _$MediaIndexDaoMixin on DatabaseAccessor<AppDatabase> {
  $MediaIndexTable get mediaIndex => attachedDatabase.mediaIndex;
  $TagsTable get tags => attachedDatabase.tags;
  $FileTagsTable get fileTags => attachedDatabase.fileTags;
  $FavoritesTable get favorites => attachedDatabase.favorites;
  $ReviewedLabelsTable get reviewedLabels => attachedDatabase.reviewedLabels;
  $MediaLocationsTable get mediaLocations => attachedDatabase.mediaLocations;
  $SmartGroupsTable get smartGroups => attachedDatabase.smartGroups;
  $SmartGroupItemsTable get smartGroupItems => attachedDatabase.smartGroupItems;
  $AiLabelsTable get aiLabels => attachedDatabase.aiLabels;
  $ImageSignalsTable get imageSignals => attachedDatabase.imageSignals;
  $CloudDestinationsTable get cloudDestinations =>
      attachedDatabase.cloudDestinations;
  $CloudItemsTable get cloudItems => attachedDatabase.cloudItems;
  MediaIndexDaoManager get managers => MediaIndexDaoManager(this);
}

class MediaIndexDaoManager {
  final _$MediaIndexDaoMixin _db;
  MediaIndexDaoManager(this._db);
  $$MediaIndexTableTableManager get mediaIndex =>
      $$MediaIndexTableTableManager(_db.attachedDatabase, _db.mediaIndex);
  $$TagsTableTableManager get tags =>
      $$TagsTableTableManager(_db.attachedDatabase, _db.tags);
  $$FileTagsTableTableManager get fileTags =>
      $$FileTagsTableTableManager(_db.attachedDatabase, _db.fileTags);
  $$FavoritesTableTableManager get favorites =>
      $$FavoritesTableTableManager(_db.attachedDatabase, _db.favorites);
  $$ReviewedLabelsTableTableManager get reviewedLabels =>
      $$ReviewedLabelsTableTableManager(
        _db.attachedDatabase,
        _db.reviewedLabels,
      );
  $$MediaLocationsTableTableManager get mediaLocations =>
      $$MediaLocationsTableTableManager(
        _db.attachedDatabase,
        _db.mediaLocations,
      );
  $$SmartGroupsTableTableManager get smartGroups =>
      $$SmartGroupsTableTableManager(_db.attachedDatabase, _db.smartGroups);
  $$SmartGroupItemsTableTableManager get smartGroupItems =>
      $$SmartGroupItemsTableTableManager(
        _db.attachedDatabase,
        _db.smartGroupItems,
      );
  $$AiLabelsTableTableManager get aiLabels =>
      $$AiLabelsTableTableManager(_db.attachedDatabase, _db.aiLabels);
  $$ImageSignalsTableTableManager get imageSignals =>
      $$ImageSignalsTableTableManager(_db.attachedDatabase, _db.imageSignals);
  $$CloudDestinationsTableTableManager get cloudDestinations =>
      $$CloudDestinationsTableTableManager(
        _db.attachedDatabase,
        _db.cloudDestinations,
      );
  $$CloudItemsTableTableManager get cloudItems =>
      $$CloudItemsTableTableManager(_db.attachedDatabase, _db.cloudItems);
}
