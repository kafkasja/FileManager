/// Whose files a swipe session swipes (TASK-N8): [kLocalSourceId] or
/// `'remote:<peerFingerprint>'` (U2 adds `'external:<volumeId>'`).
library;

/// This device's own files.
const String kLocalSourceId = 'local';

const String _remotePrefix = 'remote:';
const String _externalPrefix = 'external:';

/// U1/U2: the source id of an external place (`StoragePlace.id`).
String externalSourceId(String placeId) => '$_externalPrefix$placeId';

/// The place id of an external source id, else null.
String? placeOfSourceId(String sourceId) =>
    sourceId.startsWith(_externalPrefix) &&
        sourceId.length > _externalPrefix.length
    ? sourceId.substring(_externalPrefix.length)
    : null;

/// The source id of the connected device [peerFingerprint].
String remoteSourceId(String peerFingerprint) =>
    '$_remotePrefix$peerFingerprint';

/// The peer fingerprint of a remote source id, else null.
String? peerOfSourceId(String sourceId) =>
    sourceId.startsWith(_remotePrefix) && sourceId.length > _remotePrefix.length
    ? sourceId.substring(_remotePrefix.length)
    : null;

/// Source id of a file id: `remote:<fp>:<id>` → `remote:<fp>`, anything
/// else → [kLocalSourceId].
String sourceIdOfFile(String fileId) {
  if (!fileId.startsWith(_remotePrefix)) return kLocalSourceId;
  final rest = fileId.substring(_remotePrefix.length);
  final colon = rest.indexOf(':');
  return colon <= 0 ? kLocalSourceId : remoteSourceId(rest.substring(0, colon));
}
