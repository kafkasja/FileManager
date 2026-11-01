import 'dart:async';

import 'package:kfm/features/connect/data/camera_access.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/data/discovery.dart';
import 'package:kfm/features/connect/data/pairing_client.dart';
import 'package:kfm/features/connect/domain/pairing.dart';
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

/// `POST /v1/pair` sent: the other device decides (N3).
final class ConnectWaiting extends ConnectState {
  const new(this.name);

  final String name;
}

/// Paired. Until N5's `RemoteConnectionController` exists the screen keeps
/// the pinned client here and shows "Connected".
final class ConnectConnected extends ConnectState {
  const new(this.result);

  final PairingSuccess result;
}

final class ConnectFailed extends ConnectState {
  const new(this.failure, {this.name, this.retry});

  final PairingFailure failure;
  final String? name;

  /// Where "Try again" goes.
  final ConnectState? retry;
}

/// Result of a scanned QR value.
enum ScanOutcome { started, notKfm, unsupportedVersion, ignored }

@riverpod
class ConnectController extends _$ConnectController {
  PairingCancel? _cancel;
  PairingSuccess? _connected;

  @override
  ConnectState build() {
    ref.onDispose(() {
      _cancel?.cancel();
      _cancel = null;
      // N5 takes the connection over; until then closing the screen ends it.
      _connected?.http.close();
      _connected = null;
    });
    return const ConnectChoose();
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
            .pairWithQr(offer, onWaiting: _waiting, cancel: cancel),
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
            ),
      ),
    );
  }

  /// Withdraws a running pairing (N3 adds `/v1/pair/cancel`).
  void cancel() {
    _cancel?.cancel();
    _cancel = null;
    _set(const ConnectChoose());
  }

  /// Closes the connection (until N5 owns it) and starts over.
  void disconnect() {
    _connected?.http.close();
    _connected = null;
    _set(const ConnectChoose());
  }

  void retry() {
    final s = state;
    _set(s is ConnectFailed ? (s.retry ?? const ConnectChoose()) : s);
  }

  void _waiting(String name) {
    if (!ref.mounted || _cancel == null) return;
    _set(ConnectWaiting(name));
  }

  Future<void> _run(
    String? name,
    ConnectState retry,
    Future<PairingSuccess> Function(PairingCancel cancel) body,
  ) async {
    _cancel?.cancel();
    final cancel = _cancel = PairingCancel();
    _set(ConnectWorking(name));
    try {
      final result = await body(cancel);
      if (!ref.mounted || cancel.isCancelled) {
        result.http.close();
        return;
      }
      _cancel = null;
      _connected = result;
      _set(ConnectConnected(result));
    } on PairingException catch (e) {
      if (!ref.mounted || cancel.isCancelled) return;
      _cancel = null;
      final waitingName = switch (state) {
        ConnectWaiting(:final name) => name,
        _ => name,
      };
      _set(ConnectFailed(e.failure, name: waitingName, retry: retry));
    }
  }

  void _set(ConnectState s) {
    if (ref.mounted) state = s;
  }
}
