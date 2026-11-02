import 'dart:async';

import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/data/known_device_connector.dart';
import 'package:kfm/features/connect/data/remembered_devices_service.dart';
import 'package:kfm/features/connect/data/share_server.dart';
import 'package:kfm/features/connect/domain/remote_connection_state.dart';
import 'package:kfm/features/connect/ui/remote_connection_controller.dart';
import 'package:kfm/features/connect/ui/share_server_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'known_devices_providers.g.dart';

/// Reconnect to remembered devices (TASK-N6); N9/N10 call `reconnect`.
@Riverpod(keepAlive: true)
KnownDeviceConnector knownDeviceConnector(Ref ref) => KnownDeviceConnector(
  repo: ref.watch(knownDevicesRepositoryProvider),
  client: ref.watch(pairingClientProvider),
  // Only while someone browses (the remembered-devices screen): reading
  // it otherwise would start a browse just to drop it.
  nearby: () => ref.exists(nearbyDevicesProvider)
      ? ref.read(nearbyDevicesProvider).value ?? const []
      : const [],
  connect: (result) =>
      ref.read(remoteConnectionControllerProvider.notifier).connect(result),
);

/// Remove / Remove all / Reset this device's identity (TASK-N6).
@Riverpod(keepAlive: true)
RememberedDevicesService rememberedDevicesService(Ref ref) =>
    RememberedDevicesService(
      repo: ref.watch(knownDevicesRepositoryProvider),
      sessions: ref.watch(clientSessionStoreProvider),
      scopes: ref.watch(shareScopeStoreProvider),
      connectedPeer: () =>
          switch (ref.read(remoteConnectionControllerProvider)) {
            RemoteConnected(:final peerFingerprint) => peerFingerprint,
            _ => null,
          },
      disconnect: () =>
          ref.read(remoteConnectionControllerProvider.notifier).disconnect(),
      stopSharing: () async {
        if (ref.read(shareServerControllerProvider).status !=
            ShareServerStatus.stopped) {
          await ref.read(shareServerControllerProvider.notifier).stopSharing();
        }
      },
      resetIdentity: () async {
        await ref.read(deviceIdentityRepositoryProvider).reset();
        ref.invalidate(deviceIdentityProvider);
      },
      // Not awaited: removal and revocation never wait on file I/O.
      removeUploads: (fp) async =>
          unawaited(ref.read(uploadStoreProvider).removeOwner(fp)),
    );
