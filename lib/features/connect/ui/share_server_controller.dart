import 'dart:async';
import 'dart:developer' as developer;

import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/data/discovery.dart';
import 'package:kfm/features/connect/data/share_server.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'share_server_controller.g.dart';

/// Starts and stops "Share this device" (TASK-N1). The share screen calls
/// [startSharing] when opened and [stopSharing] on dispose; N5 adds the
/// app-lifecycle hook here. Errors land in [ShareServerState.error] (rule 8).
@Riverpod(keepAlive: true)
class ShareServerController extends _$ShareServerController {
  /// Bumped by every start/stop, so a start that finishes after a stop
  /// (screen closed while "Preparing…") shuts its server down again.
  int _generation = 0;

  @override
  ShareServerState build() => ShareServerState.stopped;

  Future<void> startSharing() async {
    if (state.status == ShareServerStatus.running ||
        state.status == ShareServerStatus.starting) {
      return;
    }
    final gen = ++_generation;
    state = const ShareServerState(status: ShareServerStatus.starting);
    final server = ref.read(shareServerProvider);
    try {
      final next = await server.start();
      if (gen != _generation) {
        await server.stop();
        return;
      }
      if (next.status == ShareServerStatus.running) {
        await _startPairing(next);
        if (gen != _generation) {
          ref.read(pairingSecretStoreProvider).clear();
          await server.stop();
          return;
        }
      }
      state = next;
      if (next.status == ShareServerStatus.running) {
        unawaited(_advertise(next, gen));
      }
    } on Object catch (e) {
      if (gen != _generation) return;
      ref.read(pairingSecretStoreProvider).clear();
      await server.stop();
      state = ShareServerState(status: ShareServerStatus.error, error: e);
    }
  }

  /// New QR secret + short code for this run (N2).
  Future<void> _startPairing(ShareServerState running) async {
    final id = await ref.read(deviceIdentityRepositoryProvider).loadOrCreate();
    final port = running.port ?? 0;
    ref
        .read(pairingSecretStoreProvider)
        .start(
          addresses: [
            for (final a in running.addresses)
              (host: a.address.address, port: port),
          ],
          serverFingerprint: id.fingerprint,
          deviceName: id.displayName,
        );
  }

  /// Best effort: QR and manual entry don't need mDNS. A failure is shown
  /// as a hint on the share screen (rule 8).
  Future<void> _advertise(ShareServerState running, int gen) async {
    try {
      final id = await ref
          .read(deviceIdentityRepositoryProvider)
          .loadOrCreate();
      await ref
          .read(shareDiscoveryProvider)
          .advertise(
            ShareAdvert(
              deviceId: id.deviceId,
              name: id.displayName,
              fingerprint: id.fingerprint,
              port: running.port ?? 0,
            ),
          );
      if (gen != _generation) {
        await ref.read(shareDiscoveryProvider).stopAdvertising();
      }
    } on Object catch (e) {
      if (gen == _generation && state.status == ShareServerStatus.running) {
        state = state.withDiscoveryError(e);
      }
    }
  }

  /// Safe to call from a widget's `dispose`: the state changes only after
  /// the first await (Riverpod forbids changes while the tree finalizes).
  Future<void> stopSharing() async {
    _generation++;
    ref.read(pairNonceStoreProvider).clear();
    ref.read(pairingSecretStoreProvider).clear();
    final discovery = ref.read(shareDiscoveryProvider);
    try {
      await discovery.stopAdvertising();
    } on Object catch (e) {
      // Sharing stops anyway; nothing left to show it on.
      developer.log('mDNS unregister failed: $e', name: 'kfm.connect');
    }
    // After the first await (PendingRequest changes): the pending prompt
    // ends as `cancelled`; every token dies with the run.
    ref.read(acceptGateProvider).cancelAll();
    ref.read(clientSessionStoreProvider).clear();
    await ref.read(shareServerProvider).stop();
    state = ShareServerState.stopped;
  }
}
