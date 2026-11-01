import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/connect/domain/remote_file_id.dart';

void main() {
  test('round-trips server ids that contain colons', () {
    for (final serverId in ['ms:12', 'path:/storage/emulated/0/a:b.jpg']) {
      final id = remoteFileId('abcd01', serverId);
      expect(id, 'remote:abcd01:$serverId');
      final parsed = parseRemoteFileId(id);
      expect(parsed.peerFingerprint, 'abcd01');
      expect(parsed.serverId, serverId);
    }
  });

  test('rejects malformed ids', () {
    for (final bad in [
      'ms:12',
      'remote:',
      'remote:abcd',
      'remote::ms:1',
      'remote:abcd:',
    ]) {
      expect(() => parseRemoteFileId(bad), throwsFormatException, reason: bad);
    }
  });

  test('rejects a fingerprint with a colon or an empty server id', () {
    expect(() => remoteFileId('a:b', 'ms:1'), throwsFormatException);
    expect(() => remoteFileId('', 'ms:1'), throwsFormatException);
    expect(() => remoteFileId('ab', ''), throwsFormatException);
  });
}
