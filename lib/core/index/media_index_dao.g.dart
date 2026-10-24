// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_index_dao.dart';

// ignore_for_file: type=lint
mixin _$MediaIndexDaoMixin on DatabaseAccessor<AppDatabase> {
  $MediaIndexTable get mediaIndex => attachedDatabase.mediaIndex;
  MediaIndexDaoManager get managers => MediaIndexDaoManager(this);
}

class MediaIndexDaoManager {
  final _$MediaIndexDaoMixin _db;
  MediaIndexDaoManager(this._db);
  $$MediaIndexTableTableManager get mediaIndex =>
      $$MediaIndexTableTableManager(_db.attachedDatabase, _db.mediaIndex);
}
