import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/connect/data/loopback_media_proxy.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:kfm/features/connect/domain/remote_file_id.dart';

import 'fake_remote_http.dart';

final _video = FileRef(
  id: remoteFileId('ab' * 32, 'ms:7'),
  uri: '',
  name: 'cat.mp4',
  kind: FileKind.video,
  sizeBytes: 10,
  modifiedAt: DateTime.utc(2026),
  folderPath: '',
  origin: FileOrigin.remote,
);

/// TASK-E1d3: a remote video asks its owner first (`POST /v1/take`).
void main() {
  test('granted → prepare returns; the id sent is the server id', () async {
    Object? sent;
    final http = FakeRemoteHttp()
      ..on('POST', ApiRoutes.take, (call) {
        sent = call.body;
        return const {'granted': true};
      });
    await LoopbackMediaProxy(http: () => http).prepare(_video);
    expect(sent, {
      'ids': ['ms:7'],
    });
  });

  test('declined → permissionDenied; an older device (404) never asks', () {
    final declined = FakeRemoteHttp()
      ..fail('POST', ApiRoutes.take, ApiErrorCode.declined);
    expect(
      LoopbackMediaProxy(http: () => declined).prepare(_video),
      throwsA(
        isA<FileOpException>().having(
          (e) => e.failure,
          'failure',
          FileOpFailure.permissionDenied,
        ),
      ),
    );
    final old = FakeRemoteHttp()
      ..fail('POST', ApiRoutes.take, ApiErrorCode.notFound);
    expect(LoopbackMediaProxy(http: () => old).prepare(_video), completes);
  });
}
