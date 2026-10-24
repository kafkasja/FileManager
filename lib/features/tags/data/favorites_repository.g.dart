// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorites_repository.dart';

// ignore_for_file: type=lint
mixin _$FavoritesRepositoryMixin on DatabaseAccessor<AppDatabase> {
  $FavoritesTable get favorites => attachedDatabase.favorites;
  FavoritesRepositoryManager get managers => FavoritesRepositoryManager(this);
}

class FavoritesRepositoryManager {
  final _$FavoritesRepositoryMixin _db;
  FavoritesRepositoryManager(this._db);
  $$FavoritesTableTableManager get favorites =>
      $$FavoritesTableTableManager(_db.attachedDatabase, _db.favorites);
}
