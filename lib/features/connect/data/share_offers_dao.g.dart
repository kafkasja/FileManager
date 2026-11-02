// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share_offers_dao.dart';

// ignore_for_file: type=lint
mixin _$ShareOffersDaoMixin on DatabaseAccessor<AppDatabase> {
  $ShareOffersTable get shareOffers => attachedDatabase.shareOffers;
  $ShareOfferFilesTable get shareOfferFiles => attachedDatabase.shareOfferFiles;
  ShareOffersDaoManager get managers => ShareOffersDaoManager(this);
}

class ShareOffersDaoManager {
  final _$ShareOffersDaoMixin _db;
  ShareOffersDaoManager(this._db);
  $$ShareOffersTableTableManager get shareOffers =>
      $$ShareOffersTableTableManager(_db.attachedDatabase, _db.shareOffers);
  $$ShareOfferFilesTableTableManager get shareOfferFiles =>
      $$ShareOfferFilesTableTableManager(
        _db.attachedDatabase,
        _db.shareOfferFiles,
      );
}
