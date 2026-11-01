import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:meta/meta.dart';

/// Why a connection to another device ended (TASK-N5).
enum DisconnectReason {
  /// This device's "Disconnect" (or app exit).
  userClosed,

  /// The other device revoked the session or its token expired (401).
  unauthorized,

  /// The other device stopped sharing (connection refused after it worked).
  remoteStopped,

  /// No answer for 3 heartbeats in a row.
  networkLost,
}

/// The connection of this device (the client) to a sharing device.
/// Instances are never equal, so every change reaches listeners.
@immutable
sealed class RemoteConnectionState {
  const new();
}

final class RemoteIdle extends RemoteConnectionState {
  const new();
}

final class RemoteConnected extends RemoteConnectionState {
  const new({
    required this.peerName,
    required this.peerFingerprint,
    required this.roots,
  });

  final String peerName;
  final String peerFingerprint;

  /// The folders the other device shares with us (N4).
  final List<RootDto> roots;
}

final class RemoteDisconnected extends RemoteConnectionState {
  const new({required this.peerName, required this.reason});

  final String peerName;
  final DisconnectReason reason;
}
