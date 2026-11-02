import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';

import 'package:kfm/app/theme/theme_providers.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/data/discovery.dart';
import 'package:kfm/features/connect/data/share_background.dart';
import 'package:kfm/features/connect/data/share_server.dart';
import 'package:kfm/features/connect/domain/connection_request.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'share_server_controller.g.dart';

/// Starts and stops "Share this device" (TASK-N1). The share screen calls
/// [startSharing] when opened and [stopSharing] on dispose. N5b: on
/// Android sharing keeps running in the background behind an ongoing
/// notification ([ShareBackground]); without it (iOS, or the system refused
/// the service) N5's app-lifecycle stop applies. Errors land in
/// [ShareServerState.error] (rule 8).
@Riverpod(keepAlive: true)
class ShareServerController extends _$ShareServerController {
  /// Bumped by every start/stop, so a start that finishes after a stop
  /// (screen closed while "Preparing…") shuts its server down again.
  int _generation = 0;

  /// N5: hidden/paused/detached stops sharing on phones (no server keeps
  /// running in the background). Only set while running.
  AppLifecycleListener? _lifecycle;

  /// N5b: connected-device names → notification text; Stop requests from
  /// the notification. Only set while the background service runs.
  StreamSubscription<List<ClientSession>>? _sessionsSub;
  StreamSubscription<void>? _stopRequestsSub;
  ShareNotificationTexts? _shown;

  @override
  ShareServerState build() {
    ref.onDispose(() {
      _stopWatchingLifecycle();
      unawaited(_stopBackground());
    });
    return ShareServerState.stopped;
  }

  /// Starts the background service; on failure falls back to N5's
  /// stop-on-background. Returns how long sharing now lasts.
  Future<ShareKeepAlive> _keepAlive(int gen) async {
    final background = ref.read(shareBackgroundProvider);
    if (background.supported) {
      try {
        final sessions = ref.read(clientSessionStoreProvider);
        await _showNotification(sessions.sessions);
        if (gen != _generation) {
          await background.stop();
          return ShareKeepAlive.whileOnScreen;
        }
        _sessionsSub = sessions.changes.listen(
          (list) => unawaited(_showNotification(list)),
        );
        _stopRequestsSub = background.stopRequests.listen(
          (_) => unawaited(stopSharing()),
        );
        return ShareKeepAlive.background;
      } on Object catch (e) {
        // Shown as "stops when you leave the app" on the share screen.
        developer.log('background sharing refused: $e', name: 'kfm.connect');
        _shown = null;
      }
    }
    if (ref.read(lifecycleStopsSharingProvider)) {
      _watchLifecycle();
      return ShareKeepAlive.whileAppOpen;
    }
    return ShareKeepAlive.whileOnScreen;
  }

  Future<void> _showNotification(List<ClientSession> sessions) async {
    final texts = shareNotificationTexts(_notificationL10n(), [
      for (final s in sessions) s.clientName,
    ]);
    if (texts == _shown) return;
    _shown = texts;
    try {
      await ref.read(shareBackgroundProvider).show(texts);
    } on Object catch (e) {
      if (_sessionsSub == null) rethrow; // first start: caller falls back
      // An update failed: the old text stays; sharing goes on.
      developer.log(
        'sharing notification update failed: $e',
        name: 'kfm.connect',
      );
    }
  }

  AppLocalizations _notificationL10n() {
    final locale =
        ref.read(appLocaleProvider).value ??
        WidgetsBinding.instance.platformDispatcher.locale;
    final supported = AppLocalizations.supportedLocales.any(
      (l) => l.languageCode == locale.languageCode,
    );
    return lookupAppLocalizations(
      supported ? locale : AppLocalizations.supportedLocales.first,
    );
  }

  Future<void> _stopBackground() async {
    final hadService = _shown != null || _sessionsSub != null;
    // Not awaited: the Stop request arrives through _stopRequestsSub
    // itself, and awaiting a subscription's cancel from inside its own
    // event never completes (sharing would stay "running" on screen).
    unawaited(_sessionsSub?.cancel());
    unawaited(_stopRequestsSub?.cancel());
    _sessionsSub = null;
    _stopRequestsSub = null;
    _shown = null;
    // Stop first (synchronously reachable from a widget's dispose).
    final stopping = hadService
        ? ref.read(shareBackgroundProvider).stop()
        : Future<void>.value();
    try {
      await stopping;
    } on Object catch (e) {
      developer.log(
        'stopping the sharing service failed: $e',
        name: 'kfm.connect',
      );
    }
  }

  void _watchLifecycle() {
    if (_lifecycle != null || !ref.read(lifecycleStopsSharingProvider)) return;
    _lifecycle = AppLifecycleListener(
      onStateChange: (s) {
        if (s == AppLifecycleState.hidden ||
            s == AppLifecycleState.paused ||
            s == AppLifecycleState.detached) {
          unawaited(stopSharing());
        }
      },
    );
  }

  void _stopWatchingLifecycle() {
    _lifecycle?.dispose();
    _lifecycle = null;
  }

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
      if (next.status == ShareServerStatus.running) {
        final keepAlive = await _keepAlive(gen);
        if (gen != _generation) return;
        state = next.withKeepAlive(keepAlive);
        unawaited(_advertise(state, gen));
      } else {
        state = next;
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
    _stopWatchingLifecycle();
    _generation++;
    final background = _stopBackground();
    ref.read(pairNonceStoreProvider).clear();
    ref.read(pairingSecretStoreProvider).clear();
    ref.read(knownPairLimiterProvider).clear();
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
    ref.read(shareScopeStoreProvider).clear();
    // N9: unfinished uploads end; their partials are deleted.
    unawaited(ref.read(uploadStoreProvider).clear());
    await ref.read(shareServerProvider).stop();
    await background;
    state = ShareServerState.stopped;
  }
}

/// The ongoing notification's texts for the connected [clientNames].
ShareNotificationTexts shareNotificationTexts(
  AppLocalizations l10n,
  List<String> clientNames,
) => ShareNotificationTexts(
  channel: l10n.shareNotificationChannel,
  title: clientNames.isEmpty
      ? l10n.shareNotificationWaiting
      : l10n.shareNotificationWith(clientNames.first, clientNames.length - 1),
  text: l10n.shareNotificationText,
  stop: l10n.shareNotificationStop,
);
