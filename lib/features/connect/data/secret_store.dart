import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The few secure-storage calls KFM needs (TASK-N1), behind an interface so
/// tests use [InMemorySecretStore].
abstract interface class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Android: AES key wrapped by the Android Keystore (data in the
/// `FlutterSecureStorage` shared-prefs file, excluded from backup).
/// Windows: DPAPI, current user. iOS: Keychain.
class PlatformSecretStore implements SecretStore {
  new([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Tests and debugging.
class InMemorySecretStore implements SecretStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}
