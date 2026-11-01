import 'dart:typed_data';

import 'package:meta/meta.dart';

/// This install's identity on the local network (TASK-N1). A peer **is** its
/// [fingerprint]; [deviceId] and [displayName] are display-only.
@immutable
class DeviceIdentity {
  const new({
    required this.deviceId,
    required this.displayName,
    required this.platform,
    required this.certPem,
    required this.fingerprint,
  });

  /// 128-bit hex, informational.
  final String deviceId;

  /// Settings `connect.displayName` (default: the device model).
  final String displayName;

  /// 'android' | 'windows' | 'ios'.
  final String platform;
  final String certPem;

  /// sha256(cert DER), lowercase hex.
  final String fingerprint;

  @override
  bool operator ==(Object other) =>
      other is DeviceIdentity &&
      other.deviceId == deviceId &&
      other.displayName == displayName &&
      other.platform == platform &&
      other.certPem == certPem &&
      other.fingerprint == fingerprint;

  @override
  int get hashCode =>
      Object.hash(deviceId, displayName, platform, certPem, fingerprint);
}

/// Long-term identity key + self-signed cert, kept in secure storage.
abstract interface class DeviceIdentityRepository {
  /// Generates and persists on first call (in an isolate); verifies key/cert
  /// consistency and regenerates everything on mismatch.
  Future<DeviceIdentity> loadOrCreate();

  /// PKCS#8 PEM; only ShareServer uses this.
  Future<String> privateKeyPem();

  /// 32 random bytes for N4's stable root ids.
  Future<Uint8List> rootIdSalt();

  /// ECDSA P-256 / SHA-256, deterministic k (RFC 6979), DER signature.
  Future<Uint8List> sign(Uint8List message);

  /// Deletes the blob and creates a new identity (N6 "Reset this device's
  /// identity").
  Future<DeviceIdentity> reset();
}
