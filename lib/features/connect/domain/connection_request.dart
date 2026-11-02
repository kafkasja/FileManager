import 'package:meta/meta.dart';

/// A verified pairing request waiting for the accept prompt (TASK-N3).
@immutable
class ConnectionRequest {
  const new({
    required this.requestId,
    required this.pairAttemptId,
    required this.remoteIp,
    required this.clientDeviceId,
    required this.clientName,
    required this.clientPlatform,
    required this.clientFingerprint,
    required this.remembered,
    required this.receivedAt,
    required this.words,
  });

  /// Server-generated, random.
  final String requestId;

  /// From `ClientHelloDto`; used by `/v1/pair/cancel`.
  final String pairAttemptId;
  final String remoteIp;

  /// Informational only.
  final String clientDeviceId;
  final String clientName;
  final String clientPlatform;

  /// Derived by the SERVER from the verified cert; never client-sent.
  final String clientFingerprint;

  /// True for `/v1/pair/known` (N6).
  final bool remembered;
  final DateTime receivedAt;

  /// The 4-word phrase (`fingerprintWords(serverFp, clientFp)`).
  final List<String> words;
}

/// Why a client pairs (TASK-N12). `send` sessions get an empty folder
/// scope and no connection prompt: they can only post send-files offers,
/// heartbeat and close.
enum SessionPurpose {
  connect,
  send;

  /// Null/unknown on the wire = [connect] (older builds).
  static SessionPurpose fromWire(Object? v) => v == 'send' ? send : connect;
}

/// How a pending request ended.
enum ConnectionDecision { accepted, declined, timedOut, cancelled }

/// An accepted client (TASK-N3). Memory only; the raw token is never kept.
@immutable
class ClientSession {
  const new({
    required this.sessionId,
    required this.clientFingerprint,
    required this.clientDeviceId,
    required this.clientName,
    required this.tokenHash,
    required this.createdAt,
    required this.lastUsedAt,
    this.purpose = SessionPurpose.connect,
  });

  final String sessionId;
  final String clientFingerprint;
  final String clientDeviceId;
  final String clientName;

  /// `sha256(token)` hex.
  final String tokenHash;
  final DateTime createdAt;
  final DateTime lastUsedAt;

  /// N12: a `send` session reaches no shared folder.
  final SessionPurpose purpose;

  bool get sendOnly => purpose == SessionPurpose.send;

  ClientSession touched(DateTime now) => ClientSession(
    sessionId: sessionId,
    clientFingerprint: clientFingerprint,
    clientDeviceId: clientDeviceId,
    clientName: clientName,
    tokenHash: tokenHash,
    createdAt: createdAt,
    lastUsedAt: now,
    purpose: purpose,
  );
}
