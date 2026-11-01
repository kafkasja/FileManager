import 'package:kfm/features/connect/domain/protocol.dart';

/// A remote device answered with a non-2xx status (TASK-N1). Callers map it
/// to UI state (rule 8).
class RemoteApiException implements Exception {
  const new(this.status, this.error);

  final int status;
  final ApiErrorDto error;

  /// Null for a code this version doesn't know.
  ApiErrorCode? get code => ApiErrorCode.fromWire(error.code);

  @override
  String toString() => 'RemoteApiException($status, ${error.code})';
}

/// Why a remote device couldn't be reached.
enum RemoteUnavailableReason {
  /// Connection refused, reset, no route, DNS, TLS failure other than the pin.
  network,

  /// Connect or request timeout.
  timeout,

  /// The server presented a certificate with a different fingerprint.
  pinMismatch,

  /// The answer wasn't valid protocol JSON.
  badResponse,
}

/// The remote device couldn't be reached or didn't speak the protocol.
class RemoteUnavailableException implements Exception {
  const new(this.reason, [this.cause]);

  final RemoteUnavailableReason reason;

  /// The underlying error, for logs only (never contains bodies or headers).
  final Object? cause;

  @override
  String toString() => 'RemoteUnavailableException(${reason.name})';
}
