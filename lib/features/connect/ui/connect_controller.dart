import 'dart:async';

import 'package:kfm/features/connect/data/camera_access.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/data/discovery.dart';
import 'package:kfm/features/connect/data/pairing_client.dart';
import 'package:kfm/features/connect/data/remote_errors.dart';
import 'package:kfm/features/connect/domain/pairing.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
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
  const new(this.name, {this.words = const []});

  final String name;
  final List<String> words;
}

/// Paired. Until N5's `RemoteConnectionController` exists the screen keeps
/// the pinned client here and shows "Connected". [roots] starts with the
/// accept answer and is refreshed (`GET /v1/roots`) while empty.
final class ConnectConnected extends ConnectState {
  const new(this.result, {required this.roots});

  final PairingSuccess result;
  final List<RootDto> roots;
}

/// The other device ended the session (a request got 401): the token is
/// dropped.
final class ConnectDisconnected extends ConnectState {
  const new(this.name);

  final String name;
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

/// How often the client asks for roots while none are shared (N3).
const Duration kRootsPollInterval = Duration(seconds: 5);

@riverpod
class ConnectController extends _$ConnectController {
  PairingCancel? _cancel;
  PairingSuccess? _connected;
  Timer? _rootsPoll;
  bool _refreshing = false;

  @override
  ConnectState build() {
    ref.onDispose(() {
      _cancel?.cancel();
      _cancel = null;
      // N5 takes the connection over; until then closing the screen ends it.
      _dropConnection();
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

  /// Withdraws a running pairing (and a request waiting for the other
  /// device's accept prompt, `/v1/pair/cancel`).
  void cancel() {
    _cancel?.cancel();
    _cancel = null;
    _set(const ConnectChoose());
  }

  /// Closes the connection (until N5 owns it) and starts over.
  void disconnect() {
    _dropConnection();
    _set(const ConnectChoose());
  }

  /// Pull-to-refresh / 5 s poll of the shared roots while the list is
  /// empty. A 401 means the other device ended the session.
  Future<void> refreshRoots() async {
    final c = _connected;
    if (c == null || _refreshing) return;
    _refreshing = true;
    try {
      final r = await c.http.getJson(
        ApiRoutes.roots,
        decode: RootsResponseDto.fromJson,
      );
      if (!ref.mounted || !identical(c, _connected)) return;
      _set(ConnectConnected(c, roots: r.roots));
      if (r.roots.isNotEmpty) _stopPoll();
    } on RemoteApiException catch (e) {
      if (!ref.mounted || !identical(c, _connected)) return;
      if (e.code == ApiErrorCode.unauthorized) {
        _dropConnection();
        _set(ConnectDisconnected(c.peerName));
      }
      // 404 until N4 serves /v1/roots; anything else: N5's heartbeat decides.
    } on Object {
      // Network blips: N5's heartbeat decides when the link is gone.
    } finally {
      _refreshing = false;
    }
  }

  void _dropConnection() {
    _stopPoll();
    final c = _connected;
    _connected = null;
    if (c != null) {
      // Memory only: the token dies with the connection (N3).
      c.http
        ..bearerToken = null
        ..close();
    }
  }

  void _stopPoll() {
    _rootsPoll?.cancel();
    _rootsPoll = null;
  }

  void retry() {
    final s = state;
    _set(s is ConnectFailed ? (s.retry ?? const ConnectChoose()) : s);
  }

  void _waiting(String name, List<String> words) {
    if (!ref.mounted || _cancel == null) return;
    _set(ConnectWaiting(name, words: words));
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
      _dropConnection();
      _connected = result;
      final roots = result.accepted.roots;
      _set(ConnectConnected(result, roots: roots));
      if (roots.isEmpty) {
        _rootsPoll = Timer.periodic(
          kRootsPollInterval,
          (_) => unawaited(refreshRoots()),
        );
      }
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
