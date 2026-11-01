import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:kfm/features/connect/data/loopback_media_proxy.dart';
import 'package:kfm/features/connect/data/pairing_client.dart';
import 'package:kfm/features/connect/data/pinned_client.dart';
import 'package:kfm/features/connect/data/remote_errors.dart';
import 'package:kfm/features/connect/domain/files_protocol.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:kfm/features/connect/domain/remote_connection_state.dart';
import 'package:kfm/features/connect/ui/remote_thumbnail_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'remote_connection_controller.g.dart';

/// Heartbeat period while the app is in the foreground (TASK-N5).
const Duration kHeartbeatInterval = Duration(seconds: 5);

/// One heartbeat request gives up after this.
const Duration kHeartbeatTimeout = Duration(seconds: 4);

/// Failed heartbeat ticks in a row before the link counts as lost.
const int kHeartbeatMaxFailures = 3;

/// While roots are shared, they are re-read every this many beats (N4
/// edits show up without a pull); while none are shared, every beat.
const int kRootsRefreshEveryBeats = 3;

/// Whether the controller follows the app lifecycle itself (a binding is
/// needed); unit tests turn it off and call `onLifecycle`.
@Riverpod(keepAlive: true)
bool remoteFollowsAppLifecycle(Ref ref) => true;

/// Thumbnails of the connected device's files (N5): memory only, cleared
/// on every disconnect.
@Riverpod(keepAlive: true)
RemoteThumbnailCache remoteThumbnailCache(Ref ref) => RemoteThumbnailCache();

/// TASK-N7 live sync: the latest change token of the connected device's
/// shared roots, from the heartbeat (`GET /v1/session` → `SessionDto`).
/// Null while not connected or when the other device sends none (older
/// version, 204). Remote browse screens refresh when it changes.
@Riverpod(keepAlive: true)
class RemoteChangeToken extends _$RemoteChangeToken {
  @override
  String? build() => null;

  // A method, not a setter: callers publish a heartbeat result.
  // ignore: use_setters_to_change_properties
  void publish(String? token) => state = token;
}

/// Lenient: a malformed token is ignored rather than failing the beat.
SessionDto _decodeSession(Map<String, Object?> json) {
  try {
    return SessionDto.fromJson(json);
  } on FormatException {
    return const SessionDto();
  }
}

/// The connection of this device to a sharing device (TASK-N5). Owns the
/// pinned client after pairing, so it outlives the Connect screen; N7's
/// remote browsing uses [http]. A 5 s `GET /v1/session` heartbeat runs in
/// the foreground: 401 → unauthorized, refused → the other device stopped,
/// 3 failed ticks (each retried once at once) → network lost. Every end
/// drops the token and closes the client.
@Riverpod(keepAlive: true)
class RemoteConnectionController extends _$RemoteConnectionController {
  RemoteHttp? _http;
  Timer? _timer;
  AppLifecycleListener? _lifecycle;
  bool _beating = false;
  bool _refreshingRoots = false;
  bool _foreground = true;
  int _failures = 0;
  int _beatsSinceRoots = 0;
  LoopbackMediaProxy? _proxy;
  Future<void>? _proxyStarted;
  int _epoch = 0;

  /// Read in build: `onDispose` may not use `ref`.
  late RemoteThumbnailCache _thumbs;

  @override
  RemoteConnectionState build() {
    _thumbs = ref.read(remoteThumbnailCacheProvider);
    ref.onDispose(() => _teardown(sendClose: false));
    return const RemoteIdle();
  }

  /// The pinned client of the live connection; null when not connected.
  RemoteHttp? get http => _http;

  /// Bumped on every disconnect: part of every `RemoteThumbnailProvider`
  /// key, so no image decoded for an old connection is reused.
  int get epoch => _epoch;

  /// The loopback proxy the video player streams remote files through
  /// (N5; N7's viewer uses it). Started on first use; closed (all handles
  /// dead) on every disconnect. Throws [StateError] when not connected.
  Future<LoopbackMediaProxy> mediaProxy() async {
    if (_http == null) throw StateError('not connected');
    var proxy = _proxy;
    if (proxy == null) {
      proxy = _proxy = LoopbackMediaProxy(
        http: () => _http ?? (throw StateError('not connected')),
        onUnauthorized: reportUnauthorized,
      );
      _proxyStarted = proxy.start();
    }
    await _proxyStarted;
    return proxy;
  }

  /// Takes over a fresh pairing result (replaces any older connection).
  void connect(PairingSuccess result) {
    _teardown(sendClose: true);
    ref.read(remoteChangeTokenProvider.notifier).publish(null);
    _http = result.http;
    _failures = 0;
    _beatsSinceRoots = 0;
    _foreground = true;
    state = RemoteConnected(
      peerName: result.peerName,
      peerFingerprint: result.peerFingerprint,
      roots: result.accepted.roots,
    );
    if (ref.read(remoteFollowsAppLifecycleProvider)) {
      _lifecycle = AppLifecycleListener(onStateChange: onLifecycle);
    }
    _startTimer();
  }

  /// "Disconnect": tells the other device (best effort, 3 s), then ends.
  Future<void> disconnect() async {
    final http = _http;
    if (http == null) return;
    final s = state;
    _stopTimer();
    try {
      await http.postJson<void>(
        ApiRoutes.sessionClose,
        const <String, Object?>{},
        decode: (_) {},
        timeout: const Duration(seconds: 3),
      );
    } on Object {
      // The other device may already be gone; the session dies anyway.
    }
    if (!identical(http, _http)) return;
    _end(DisconnectReason.userClosed, peerName: _nameOf(s));
  }

  /// Another caller (roots refresh, media proxy, N7) got a 401.
  void reportUnauthorized() {
    if (_http != null) _end(DisconnectReason.unauthorized);
  }

  /// Re-reads the shared roots (pull-to-refresh, and from the heartbeat).
  Future<void> refreshRoots() async {
    final http = _http;
    if (http == null || _refreshingRoots) return;
    _refreshingRoots = true;
    try {
      final r = await http.getJson(
        ApiRoutes.roots,
        decode: RootsResponseDto.fromJson,
      );
      if (!identical(http, _http)) return;
      _beatsSinceRoots = 0;
      if (state case RemoteConnected(:final peerName, :final peerFingerprint)) {
        state = RemoteConnected(
          peerName: peerName,
          peerFingerprint: peerFingerprint,
          roots: r.roots,
        );
      }
    } on RemoteApiException catch (e) {
      if (identical(http, _http) && e.code == ApiErrorCode.unauthorized) {
        _end(DisconnectReason.unauthorized);
      }
    } on Object {
      // Network blips: the heartbeat decides when the link is gone.
    } finally {
      _refreshingRoots = false;
    }
  }

  /// One heartbeat (the timer calls it; tests call it directly).
  @visibleForTesting
  Future<void> beat() async {
    final http = _http;
    if (http == null || _beating) return;
    _beating = true;
    try {
      await _beatOnce(http);
    } finally {
      _beating = false;
    }
  }

  Future<void> _beatOnce(RemoteHttp http) async {
    // A failed beat is retried once at once: after the other device
    // restarts, the first request may fail on a stale pooled socket.
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final session = await http
            .getJson(ApiRoutes.session, decode: _decodeSession)
            .timeout(kHeartbeatTimeout);
        if (!identical(http, _http)) return;
        _failures = 0;
        if (session.changeToken case final token?) {
          ref.read(remoteChangeTokenProvider.notifier).publish(token);
        }
        _beatsSinceRoots++;
        final roots = switch (state) {
          RemoteConnected(:final roots) => roots,
          _ => const <RootDto>[],
        };
        if (roots.isEmpty || _beatsSinceRoots >= kRootsRefreshEveryBeats) {
          unawaited(refreshRoots());
        }
        return;
      } on RemoteApiException catch (e) {
        if (!identical(http, _http)) return;
        if (e.code == ApiErrorCode.unauthorized) {
          _end(DisconnectReason.unauthorized);
          return;
        }
      } on RemoteUnavailableException catch (e) {
        if (!identical(http, _http)) return;
        if (e.reason == RemoteUnavailableReason.refused) {
          _end(DisconnectReason.remoteStopped);
          return;
        }
      } on TimeoutException {
        if (!identical(http, _http)) return;
      }
    }
    if (++_failures >= kHeartbeatMaxFailures) {
      _end(DisconnectReason.networkLost);
    }
  }

  /// Background: no heartbeat (and N7's requests stop with the UI). Back in
  /// the foreground: one beat at once. App exit: best-effort close.
  @visibleForTesting
  void onLifecycle(AppLifecycleState s) {
    switch (s) {
      case AppLifecycleState.hidden || AppLifecycleState.paused:
        _foreground = false;
        _stopTimer();
      case AppLifecycleState.resumed:
        if (_foreground || _http == null) return;
        _foreground = true;
        unawaited(beat());
        _startTimer();
      case AppLifecycleState.detached:
        final http = _http;
        if (http != null) {
          unawaited(
            http
                .postJson<void>(
                  ApiRoutes.sessionClose,
                  const <String, Object?>{},
                  decode: (_) {},
                  timeout: const Duration(seconds: 1),
                )
                .then<void>((_) {}, onError: (Object _) {}),
          );
        }
      case AppLifecycleState.inactive:
        break;
    }
  }

  void _startTimer() {
    _stopTimer();
    _timer = Timer.periodic(kHeartbeatInterval, (_) => unawaited(beat()));
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  String _nameOf(RemoteConnectionState s) => switch (s) {
    RemoteConnected(:final peerName) => peerName,
    RemoteDisconnected(:final peerName) => peerName,
    RemoteIdle() => '',
  };

  void _end(DisconnectReason reason, {String? peerName}) {
    final name = peerName ?? _nameOf(state);
    _teardown(sendClose: false);
    ref.read(remoteChangeTokenProvider.notifier).publish(null);
    state = RemoteDisconnected(peerName: name, reason: reason);
  }

  /// Drops the token (memory only, N3) and closes the client. With
  /// [sendClose] an older connection is told it ends (best effort).
  void _teardown({required bool sendClose}) {
    _stopTimer();
    _lifecycle?.dispose();
    _lifecycle = null;
    final proxy = _proxy;
    _proxy = null;
    _proxyStarted = null;
    if (proxy != null) {
      proxy.revokeAll();
      unawaited(proxy.close().catchError((Object _) {}));
    }
    if (_http != null) {
      _epoch++;
      _thumbs.clear();
    }
    final http = _http;
    _http = null;
    if (http == null) return;
    if (sendClose) {
      unawaited(
        http
            .postJson<void>(
              ApiRoutes.sessionClose,
              const <String, Object?>{},
              decode: (_) {},
              timeout: const Duration(seconds: 3),
            )
            .then<void>((_) {}, onError: (Object _) {})
            .whenComplete(() => _close(http)),
      );
    } else {
      _close(http);
    }
  }

  static void _close(RemoteHttp http) {
    http
      ..bearerToken = null
      ..close();
  }
}
