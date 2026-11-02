import 'package:kfm/features/connect/data/client_session_store.dart';
import 'package:kfm/features/connect/data/known_devices_dao.dart';
import 'package:kfm/features/connect/data/share_scope_store.dart';
import 'package:kfm/features/connect/domain/known_device.dart';

/// Removal and revocation of remembered devices (TASK-N6).
class RememberedDevicesService {
  new({
    required this._repo,
    required this._sessions,
    required this._scopes,
    required this._connectedPeer,
    required this._disconnect,
    required this._stopSharing,
    required this._resetIdentity,
    this._removeUploads,
  });

  final KnownDevicesRepository _repo;
  final ClientSessionStore _sessions;
  final ShareScopeStore _scopes;

  /// Fingerprint of the device this one is connected to (client side).
  final String? Function() _connectedPeer;
  final Future<void> Function() _disconnect;
  final Future<void> Function() _stopSharing;

  /// New key, cert, deviceId and root-id salt; invalidates the identity.
  final Future<void> Function() _resetIdentity;

  /// N10: deletes that device's partial uploads to us.
  final Future<void> Function(String fingerprint)? _removeUploads;

  /// Deletes the row and ends everything that device has with us at once:
  /// its live session (its next request gets 401), its shared folders, and
  /// our connection to it.
  Future<void> remove(KnownDevice device) async {
    await _repo.remove(device.id);
    await _revoke(device.fingerprint);
  }

  /// [remove] for every row (temporary ones too).
  Future<void> removeAll() async {
    final all = await _repo.all();
    await _repo.removeAll();
    for (final d in all) {
      await _revoke(d.fingerprint);
    }
  }

  /// "Reset this device's identity": stops sharing, makes a new identity
  /// (every peer's stored fingerprint for us stops matching) and forgets
  /// every device.
  Future<void> resetIdentity() async {
    await _stopSharing();
    if (_connectedPeer() != null) await _disconnect();
    await _resetIdentity();
    await removeAll();
  }

  Future<void> _revoke(String fp) async {
    _sessions.revokeByFingerprint(fp);
    _scopes.remove(fp);
    await _removeUploads?.call(fp);
    if (_connectedPeer() == fp) await _disconnect();
  }
}
