// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'known_devices_dao.dart';

// ignore_for_file: type=lint
mixin _$KnownDevicesDaoMixin on DatabaseAccessor<AppDatabase> {
  $KnownDevicesTable get knownDevices => attachedDatabase.knownDevices;
  KnownDevicesDaoManager get managers => KnownDevicesDaoManager(this);
}

class KnownDevicesDaoManager {
  final _$KnownDevicesDaoMixin _db;
  KnownDevicesDaoManager(this._db);
  $$KnownDevicesTableTableManager get knownDevices =>
      $$KnownDevicesTableTableManager(_db.attachedDatabase, _db.knownDevices);
}
