import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/domain/connection_request.dart';
import 'package:kfm/features/connect/domain/known_device.dart';
import 'package:kfm/features/connect/domain/link.dart';
import 'package:kfm/features/connect/domain/remote_connection_state.dart';
import 'package:kfm/features/connect/ui/link_controller.dart';
import 'package:kfm/features/connect/ui/remote_connection_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'link_providers.g.dart';

/// The linked device (TASK-E1), or null: this device's connection to a
/// peer (not send-only) and/or a peer connected to this device's server.
/// The connection wins when both exist for different peers (one link at a
/// time, `RemoteConnectionController` is single-peer).
@Riverpod(keepAlive: true)
DeviceLink? currentLink(Ref ref) {
  final remote = ref.watch(remoteConnectionControllerProvider);
  final clients =
      ref.watch(connectedClientsProvider).value ?? const <ClientSession>[];
  final store = ref.read(clientSessionStoreProvider);
  // E1d: this side's perms and the reverse half, from the link itself.
  final info = ref.watch(linkControllerProvider);
  LinkPerms mineFor(String fp) =>
      info?.peerFingerprint == fp ? info!.mine : const LinkPerms();
  bool reverseFor(String fp) =>
      info?.peerFingerprint != fp || info!.reverseReachable;
  final live = [
    for (final s in clients)
      if (!s.sendOnly && store.isResponsive(s)) s,
  ];
  if (remote
      case RemoteConnected(
        :final peerFingerprint,
        :final peerName,
        :final roots,
        :final sendOnly,
      )
      when !sendOnly) {
    return DeviceLink(
      peerFingerprint: peerFingerprint,
      peerName: peerName,
      connectedToThem: true,
      iSeeTheirs: roots.isNotEmpty,
      theyAreConnected: live.any((s) => s.clientFingerprint == peerFingerprint),
      mine: mineFor(peerFingerprint),
      reverseReachable: reverseFor(peerFingerprint),
    );
  }
  // Only a peer connected to this device (it shares; N12b sends back).
  if (live.length == 1) {
    final s = live.single;
    return DeviceLink(
      peerFingerprint: s.clientFingerprint,
      peerName: s.clientName,
      theyAreConnected: true,
      mine: mineFor(s.clientFingerprint),
      reverseReachable: reverseFor(s.clientFingerprint),
    );
  }
  return null;
}

/// The Devices rows (desktop nav pane): the linked device first, then the
/// remembered devices (temporary rows hidden) with their status.
@Riverpod(keepAlive: true)
List<DeviceRow> deviceRows(Ref ref) {
  final link = ref.watch(currentLinkProvider);
  final known = ref.watch(knownDevicesProvider).value ?? const <KnownDevice>[];
  final rows = <DeviceRow>[];
  if (link != null) {
    final platform = known
        .where((d) => d.fingerprint == link.peerFingerprint)
        .firstOrNull
        ?.platform;
    rows.add(
      DeviceRow(
        fingerprint: link.peerFingerprint,
        name: link.peerName,
        platform: platform ?? '',
        status: DeviceRowStatus.linked,
      ),
    );
  }
  for (final d in known) {
    if (d.fingerprint == link?.peerFingerprint) continue;
    rows.add(
      DeviceRow(
        fingerprint: d.fingerprint,
        name: d.name,
        platform: d.platform,
        // No mDNS browse runs just for this list (battery).
        status: DeviceRowStatus.remembered,
      ),
    );
  }
  return List.unmodifiable(rows);
}
