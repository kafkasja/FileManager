import 'package:kfm/features/connect/data/remote_file_source.dart';
import 'package:kfm/features/session/domain/session_source.dart';
import 'package:kfm/features/swipe/data/swipe_action_dispatcher.dart';
import 'package:kfm/features/transfers/data/transfer_engine.dart';
import 'package:kfm/features/transfers/data/transfers_dao.dart';
import 'package:kfm/features/transfers/domain/transfer_job.dart';

/// N9 swipe `sendToDevice`, run inside the undo row's transaction: one
/// open job per device, swipe session and target collects the sends. A
/// local session uploads into the action's `<rootId>/<path>` on that
/// device; that device's own (remote) session downloads into
/// `<downloads>/<device>`. The engine picks the row up after the commit.
SwipeSendQueue swipeSendQueue(
  TransfersDao dao, {
  required String downloadsRoot,
  DateTime Function()? clock,
}) => (session, file, action) async {
  final deviceId =
      action.deviceId ?? (throw StateError('send without a device'));
  final now = (clock ?? DateTime.now)();
  final f = (
    sourceFileId: file.id,
    name: file.name,
    sizeBytes: file.sizeBytes,
    sourceModifiedAtMs: file.modifiedAt.millisecondsSinceEpoch,
  );
  if (session.sourceId != kLocalSourceId) {
    final name =
        await dao.deviceName(deviceId) ??
        (throw StateError('device $deviceId is not remembered'));
    return await dao.appendToSessionJob(
      deviceId: deviceId,
      direction: TransferDirection.download,
      targetPath: defaultDownloadFolder(downloadsRoot, name),
      swipeSessionId: session.id,
      f: f,
      now: now,
    );
  }
  final target = splitRemoteFolder(
    action.targetFolder ?? (throw StateError('send without a folder')),
  );
  return await dao.appendToSessionJob(
    deviceId: deviceId,
    direction: TransferDirection.upload,
    targetRootId: target.rootId,
    targetPath: target.path,
    swipeSessionId: session.id,
    f: f,
    now: now,
  );
};
