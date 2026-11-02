import 'dart:async';

import 'package:kfm/features/connect/data/camera_access.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/data/discovery.dart';
import 'package:kfm/features/connect/data/pairing_client.dart';
import 'package:kfm/features/connect/domain/connection_request.dart';
import 'package:kfm/features/connect/domain/pairing.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:kfm/features/connect/domain/remote_connection_state.dart';
import 'package:kfm/features/connect/ui/known_devices_providers.dart';
import 'package:kfm/features/connect/ui/remote_connection_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connect_controller.g.dart';

/// What the Connect screen shows (TASK-N2).
sealed class ConnectState {
  const new();
}

/// "Scan QR" / "Type code".
final class ConnectChoose extends ConnectState {
  const new();
}

final class ConnectScanning extends ConnectState {
  const new();
}

/// Camera permission refused: explanation + "Type code".
final class ConnectCameraDenied extends ConnectState {
  const new({required this.permanently});

  final bool permanently;
}

/// Nearby list + "Enter address".
final class ConnectPickDevice extends ConnectState {
  const new();
}

/// The 8-character field for [target].
final class ConnectEnterCode extends ConnectState {
  const new({required this.target, this.name, this.fingerprintHint});

  final ShareAddress target;

  /// Null for a typed address.
  final String? name;
  final String? fingerprintHint;
}

/// Probing / SPAKE2 running.
final class ConnectWorking extends ConnectState {
  const new(this.name);

  final String? name;
}

/// `POST /v1/pair` sent: the other device decides (N3). Both devices show
/// [words].
final class ConnectWaiting extends ConnectState {
  const new(
    this.name, {
    this.words = const [],
    this.remember = true,
    this.showRemember = true,
  });

  final String name;
  final List<String> words;

  /// N6 "Remember this device" (default on): saved after an accept.
  final bool remember;

  /// False for a remembered device's reconnect (already remembered).
  final bool showRemember;
}

/// Paired: mirrors [RemoteConnected] of the keepAlive
/// `RemoteConnectionController` (N5), which owns the connection, so it
/// survives closing this screen.
final class ConnectConnected extends ConnectState {
  const new({
    required this.peerName,
    required this.roots,
    this.sendOnly = false,
  });

  final String peerName;
  final List<RootDto> roots;

  /// N12: connected only to send files.
  final bool sendOnly;
}

/// The connection ended for [reason] (not this device's Disconnect); the
/// token is dropped.
final class ConnectDisconnected extends ConnectState {
  const new(this.name, {this.reason = DisconnectReason.unauthorized});

  final String name;
  final DisconnectReason reason;
}

final class ConnectFailed extends ConnectState {
  const new(this.failure, {this.name, this.retry, this.reconnectFingerprint});

  final PairingFailure failure;
  final String? name;

  /// Where "Try again" goes.
  final ConnectState? retry;

  /// N6: "Try again" reconnects to this remembered device instead.
  final String? reconnectFingerprint;
}

/// Result of a scanned QR value.
enum ScanOutcome { started, notKfm, unsupportedVersion, ignored }

@riverpod
class ConnectController extends _$ConnectController {
  PairingCancel? _cancel;

  /// N6: "Remember this device" of the running pairing.
  bool _remember = true;

  /// The running pairing is a remembered device's reconnect.
  bool _known = false;

  /// N12: `send` pairs a send-only session (the "Send to…" flow).
  SessionPurpose _purpose = SessionPurpose.connect;

  /// N12: how the next pairing connects.
  // A method, not a setter: the flow sets it before starting a pairing.
  // ignore: use_setters_to_change_properties
  void setPurpose(SessionPurpose purpose) => _purpose = purpose;

  @override
  ConnectState build() {
    ref
      ..onDispose(() {
        // Only a pairing in progress ends with the screen; the connection
        // itself belongs to RemoteConnectionController (N5).
        _cancel?.cancel();
        _cancel = null;
      })
      ..listen(remoteConnectionControllerProvider, (_, next) {
        switch (next) {
          case RemoteConnected(:final peerName, :final roots, :final sendOnly):
            _set(
              ConnectConnected(
                peerName: peerName,
                roots: roots,
                sendOnly: sendOnly,
              ),
            );
          case RemoteDisconnected(reason: DisconnectReason.userClosed):
            _set(const ConnectChoose());
          case RemoteDisconnected(:final peerName, :final reason):
            _set(ConnectDisconnected(peerName, reason: reason));
          case RemoteIdle():
            break;
        }
      });
    return switch (ref.read(remoteConnectionControllerProvider)) {
      RemoteConnected(:final peerName, :final roots, :final sendOnly) =>
        ConnectConnected(peerName: peerName, roots: roots, sendOnly: sendOnly),
      _ => const ConnectChoose(),
    };
  }

  void choose() => _set(const ConnectChoose());

  /// Asks for the camera only now (never at start).
  Future<void> scan() async {
    final camera = ref.read(cameraAccessProvider);
    final result = await camera.request();
    if (!ref.mounted) return;
    _set(switch (result) {
      CameraPermission.granted => const ConnectScanning(),
      CameraPermission.denied => const ConnectCameraDenied(permanently: false),
      CameraPermission.permanentlyDenied => const ConnectCameraDenied(
        permanently: true,
      ),
    });
  }

  void typeCode() => _set(const ConnectPickDevice());

  void pickDevice(NearbyDevice device) => _set(
    ConnectEnterCode(
      target: device.address,
      name: device.name,
      fingerprintHint: device.fingerprintHint,
    ),
  );

  void enterAddress(ShareAddress address) =>
      _set(ConnectEnterCode(target: address));

  /// A scanned (or, in debug builds, pasted) QR value.
  ScanOutcome onScanned(String raw) {
    if (state is! ConnectScanning) return ScanOutcome.ignored;
    final PairingOffer offer;
    try {
      offer = PairingOffer.parse(raw);
    } on UnsupportedVersionException {
      return ScanOutcome.unsupportedVersion;
    } on FormatException {
      return ScanOutcome.notKfm;
    }
    final retry = state;
    unawaited(
      _run(
        offer.deviceName,
        retry,
        (cancel) => ref
            .read(pairingClientProvider)
            .pairWithQr(
              offer,
              onWaiting: _waiting,
              cancel: cancel,
              purpose: _purpose,
            ),
      ),
    );
    return ScanOutcome.started;
  }

  void submitCode(ShortCode code) {
    final s = state;
    if (s is! ConnectEnterCode) return;
    unawaited(
      _run(
        s.name,
        s,
        (cancel) => ref
            .read(pairingClientProvider)
            .pairWithCode(
              base: Uri(
                scheme: 'https',
                host: s.target.host,
                port: s.target.port,
              ),
              code: code,
              expectedFingerprint: s.fingerprintHint,
              onWaiting: _waiting,
              cancel: cancel,
              purpose: _purpose,
            ),
      ),
    );
  }

  /// N6: reconnects to the remembered device [fingerprint] without a QR
  /// (the other device still decides, unless it set "Always allow").
  void reconnect(String fingerprint, {required String name}) {
    unawaited(
      _run(
        name,
        const ConnectChoose(),
        (cancel) => ref
            .read(knownDeviceConnectorProvider)
            .pair(
              fingerprint,
              onWaiting: _waiting,
              cancel: cancel,
              purpose: _purpose,
            ),
        reconnectFingerprint: fingerprint,
      ),
    );
  }

  /// N6: the waiting screen's "Remember this device" checkbox.
  void setRemember({required bool remember}) {
    _remember = remember;
    final s = state;
    if (s is ConnectWaiting) {
      _set(
        ConnectWaiting(
          s.name,
          words: s.words,
          remember: remember,
          showRemember: s.showRemember,
        ),
      );
    }
  }

  /// Withdraws a running pairing (and a request waiting for the other
  /// device's accept prompt, `/v1/pair/cancel`).
  void cancel() {
    _cancel?.cancel();
    _cancel = null;
    _set(const ConnectChoose());
  }

  /// Ends the connection (tells the other device) and starts over.
  Future<void> disconnect() async {
    await ref.read(remoteConnectionControllerProvider.notifier).disconnect();
    _set(const ConnectChoose());
  }

  /// Pull-to-refresh of the shared roots (the heartbeat refreshes them
  /// too). A 401 ends the connection.
  Future<void> refreshRoots() =>
      ref.read(remoteConnectionControllerProvider.notifier).refreshRoots();

  void retry() {
    final s = state;
    if (s is ConnectFailed) {
      if (s.reconnectFingerprint case final fp?) {
        reconnect(fp, name: s.name ?? '');
        return;
      }
      _set(s.retry ?? const ConnectChoose());
      return;
    }
    _set(s);
  }

  void _waiting(String name, List<String> words) {
    if (!ref.mounted || _cancel == null) return;
    _set(
      ConnectWaiting(
        name,
        words: words,
        remember: _remember,
        showRemember: !_known,
      ),
    );
  }

  Future<void> _run(
    String? name,
    ConnectState retry,
    Future<PairingSuccess> Function(PairingCancel cancel) body, {
    String? reconnectFingerprint,
  }) async {
    _cancel?.cancel();
    final cancel = _cancel = PairingCancel();
    _remember = true;
    _known = reconnectFingerprint != null;
    _set(ConnectWorking(name));
    try {
      final result = await body(cancel);
      if (!ref.mounted || cancel.isCancelled) {
        result.http.close();
        return;
      }
      _cancel = null;
      // The listener in build() turns this into ConnectConnected.
      ref.read(remoteConnectionControllerProvider.notifier).connect(result);
      if (reconnectFingerprint == null && _remember) {
        // N6: a failed save shows through the write queue's error stream.
        unawaited(
          ref
              .read(knownDeviceConnectorProvider)
              .rememberServer(result)
              .then<void>((_) {}, onError: (Object _) {}),
        );
      }
    } on PairingException catch (e) {
      if (!ref.mounted || cancel.isCancelled) return;
      _cancel = null;
      final waitingName = switch (state) {
        ConnectWaiting(:final name) => name,
        _ => name,
      };
      _set(
        ConnectFailed(
          e.failure,
          name: waitingName,
          retry: retry,
          reconnectFingerprint: reconnectFingerprint,
        ),
      );
    }
  }

  void _set(ConnectState s) {
    if (ref.mounted) state = s;
  }
}
