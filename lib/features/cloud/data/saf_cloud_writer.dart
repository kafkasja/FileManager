import 'package:kfm/core/files/android/files_channel.dart';
import 'package:kfm/features/cloud/domain/cloud_writer.dart';

/// [CloudDestinationWriter] on `CloudSaf.kt` (TASK-X3).
class SafCloudWriter implements CloudDestinationWriter {
  new(this._channel, {Stream<({String jobKey, int bytes})>? progress})
    : _progress = progress ?? FilesChannel.cloudProgress().asBroadcastStream();

  final FilesChannel _channel;
  final Stream<({String jobKey, int bytes})> _progress;

  @override
  Stream<({String jobKey, int bytes})> get progress => _progress;

  @override
  Future<String> create(String location, String name, String? mime) =>
      _guard(() => _channel.cloudCreate(location, name, mime));

  @override
  Future<CloudWriteResult> write({
    required String source,
    required String remoteUri,
    required String jobKey,
  }) => _guard(() async {
    final r = await _channel.cloudCopy(
      source: source,
      doc: remoteUri,
      jobKey: jobKey,
    );
    return CloudWriteResult(sha256: r.sha256, bytes: r.bytes);
  });

  @override
  Future<CloudWriteResult> readBack(String remoteUri) => _guard(() async {
    final r = await _channel.cloudHash(remoteUri);
    return CloudWriteResult(sha256: r.sha256, bytes: r.bytes);
  });

  @override
  Future<int?> sizeOf(String remoteUri) =>
      _guard(() => _channel.cloudStat(remoteUri));

  @override
  Future<void> deleteDocument(String remoteUri) =>
      _guard(() => _channel.cloudDelete(remoteUri));

  @override
  Future<void> cancel(String jobKey) =>
      _guard(() => _channel.cloudCancel(jobKey));

  static Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on FilesChannelException catch (e) {
      throw CloudWriteException(switch (e.code) {
        'NOT_FOUND' => CloudWriteFailure.notFound,
        'PERMISSION' => CloudWriteFailure.permission,
        'NO_SPACE' => CloudWriteFailure.noSpace,
        'CANCELLED' => CloudWriteFailure.cancelled,
        _ => CloudWriteFailure.io,
      }, e.message);
    }
  }
}
