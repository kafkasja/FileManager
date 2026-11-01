import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/features/connect/data/remote_file_source.dart';
import 'package:kfm/features/connect/domain/remote_connection_state.dart';
import 'package:kfm/features/connect/ui/remote_connection_controller.dart';
import 'package:kfm/features/tags/data/tag_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'remote_source_provider.g.dart';

/// Whether the device with [peerFingerprint] is connected now.
@riverpod
bool remotePeerConnected(Ref ref, String peerFingerprint) =>
    switch (ref.watch(remoteConnectionControllerProvider)) {
      RemoteConnected(peerFingerprint: final fp) => fp == peerFingerprint,
      _ => false,
    };

/// The files of the device with [peerFingerprint] (TASK-N7). Lives as long
/// as the app; it reads the live connection's client per call, so while that
/// device isn't connected every call throws `FileOpFailure.unavailable`.
/// Its id changes (remote move / rename) re-key B's tags, favorites and
/// reviewed labels like local ones (F3 → `FileIdRekeyer`).
@Riverpod(keepAlive: true)
RemoteFileSource remoteSource(Ref ref, String peerFingerprint) {
  final controller = ref.read(remoteConnectionControllerProvider.notifier);
  final source = RemoteFileSource(
    peerFingerprint: peerFingerprint,
    http: () => switch (ref.read(remoteConnectionControllerProvider)) {
      RemoteConnected(peerFingerprint: final fp) when fp == peerFingerprint =>
        controller.http,
      _ => null,
    },
    onUnauthorized: controller.reportUnauthorized,
  );
  final sub = source.idChanges.listen(
    (c) => ref
        .read(fileIdRekeyerProvider)
        .rekey(
          c.oldId,
          c.newRef.id,
          newModifiedMs: c.newRef.modifiedAt.millisecondsSinceEpoch,
        )
        .fireAndForget(),
  );
  ref.onDispose(() async {
    await sub.cancel();
    await source.dispose();
  });
  return source;
}
