/// Ids of files on a connected device (N5/N7): `remote:<fp>:<serverId>`.
///
/// The peer fingerprint is hex (no ':'); the server id is the other device's
/// own `FileRef.id` and may itself contain ':' (`path:/storage/...`,
/// `ms:12`), so parsing splits at the second ':' only.
library;

const String _prefix = 'remote:';

/// `remote:<peerFingerprint>:<serverId>`.
String remoteFileId(String peerFingerprint, String serverId) {
  if (peerFingerprint.isEmpty || peerFingerprint.contains(':')) {
    throw FormatException('Bad peer fingerprint', peerFingerprint);
  }
  if (serverId.isEmpty) throw const FormatException('Empty server id');
  return '$_prefix$peerFingerprint:$serverId';
}

/// Splits a [remoteFileId] back into its parts. Throws [FormatException]
/// when [id] isn't a remote file id.
({String peerFingerprint, String serverId}) parseRemoteFileId(String id) {
  if (!id.startsWith(_prefix)) {
    throw FormatException('Not a remote file id', id);
  }
  final rest = id.substring(_prefix.length);
  final colon = rest.indexOf(':');
  if (colon <= 0 || colon == rest.length - 1) {
    throw FormatException('Bad remote file id', id);
  }
  return (
    peerFingerprint: rest.substring(0, colon),
    serverId: rest.substring(colon + 1),
  );
}
