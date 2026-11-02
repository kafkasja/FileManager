// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfers_dao.dart';

// ignore_for_file: type=lint
mixin _$TransfersDaoMixin on DatabaseAccessor<AppDatabase> {
  $KnownDevicesTable get knownDevices => attachedDatabase.knownDevices;
  $SessionsTable get sessions => attachedDatabase.sessions;
  $TransfersTable get transfers => attachedDatabase.transfers;
  $TransferFilesTable get transferFiles => attachedDatabase.transferFiles;
  TransfersDaoManager get managers => TransfersDaoManager(this);
}

class TransfersDaoManager {
  final _$TransfersDaoMixin _db;
  TransfersDaoManager(this._db);
  $$KnownDevicesTableTableManager get knownDevices =>
      $$KnownDevicesTableTableManager(_db.attachedDatabase, _db.knownDevices);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db.attachedDatabase, _db.sessions);
  $$TransfersTableTableManager get transfers =>
      $$TransfersTableTableManager(_db.attachedDatabase, _db.transfers);
  $$TransferFilesTableTableManager get transferFiles =>
      $$TransferFilesTableTableManager(_db.attachedDatabase, _db.transferFiles);
}
