// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_repository.dart';

// ignore_for_file: type=lint
mixin _$TagRepositoryMixin on DatabaseAccessor<AppDatabase> {
  $TagsTable get tags => attachedDatabase.tags;
  $FileTagsTable get fileTags => attachedDatabase.fileTags;
  TagRepositoryManager get managers => TagRepositoryManager(this);
}

class TagRepositoryManager {
  final _$TagRepositoryMixin _db;
  TagRepositoryManager(this._db);
  $$TagsTableTableManager get tags =>
      $$TagsTableTableManager(_db.attachedDatabase, _db.tags);
  $$FileTagsTableTableManager get fileTags =>
      $$FileTagsTableTableManager(_db.attachedDatabase, _db.fileTags);
}
