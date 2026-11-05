import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderContainer;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:kfm/core/platform/screen_awake.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/data/pairing_secret_store.dart';
import 'package:kfm/features/connect/data/path_guard.dart';
import 'package:kfm/features/connect/data/secret_store.dart';
import 'package:kfm/features/connect/data/share_background.dart';
import 'package:kfm/features/connect/data/share_server.dart';
import 'package:kfm/features/connect/data/shared_folder_fs.dart';
import 'package:kfm/features/connect/domain/device_identity.dart';
import 'package:kfm/features/connect/domain/remote_connection_state.dart';
import 'package:kfm/features/connect/ui/remote_connection_controller.dart';
import 'package:shelf/shelf.dart';

import 'fake_discovery.dart';

/// Fakes for widget tests of the share screen (shared by the N1–N12 share
/// tests and the E1 black-screen tests).
class FakeAwake implements ScreenAwake {
  final List<bool> calls = [];

  @override
  Future<void> keepOn({required bool on}) async => calls.add(on);
}

class FakeServer extends ShareServer {
  new(DeviceIdentityRepository identity)
    : super(
        identity,
        (_) =>
            (_) => Response.ok(''),
      );

  ShareServerState next = ShareServerState(
    status: ShareServerStatus.running,
    addresses: [LocalAddress(InternetAddress('192.168.1.23'), 24, 'wlan0')],
    port: 45123,
    fingerprint: 'ab' * 32,
  );
  int starts = 0;
  int stops = 0;
  bool _running = false;

  @override
  bool get isRunning => _running;

  @override
  Future<ShareServerState> start() async {
    starts++;
    _running = next.status == ShareServerStatus.running;
    return next;
  }

  @override
  Future<void> stop() async {
    if (_running) stops++;
    _running = false;
  }
}

class FakeFolderFs implements SharedFolderFs {
  static const r = '/storage/emulated/0';
  static const Map<String, List<String>> folders = {
    r: ['$r/Android', '$r/DCIM', '$r/Download', '$r/Music'],
    '$r/DCIM': ['$r/DCIM/Camera'],
  };

  @override
  String get primaryRoot => r;

  @override
  Future<bool> exists(String path) async =>
      folders.containsKey(path) || folders.values.any((l) => l.contains(path));

  @override
  Future<List<String>> listSubfolders(String path) async =>
      folders[path] ?? const [];
}

class FakeIdentity implements DeviceIdentityRepository {
  @override
  Future<DeviceIdentity> loadOrCreate() async => const DeviceIdentity(
    deviceId: '00',
    displayName: 'Kaf phone',
    platform: 'android',
    certPem: '',
    fingerprint: 'ab',
  );

  @override
  Future<String> privateKeyPem() async => '';

  @override
  Future<Uint8List> rootIdSalt() async => Uint8List(32);

  @override
  Future<Uint8List> sign(Uint8List message) async => Uint8List(0);

  @override
  Future<DeviceIdentity> reset() => loadOrCreate();
}

class FakeBackground implements ShareBackground {
  final List<ShareNotificationTexts> shown = [];
  int stops = 0;
  bool refuse = false;
  final StreamController<void> requests = StreamController.broadcast();

  @override
  bool get supported => true;

  @override
  Future<void> show(ShareNotificationTexts texts) async {
    if (refuse) throw StateError('ForegroundServiceStartNotAllowed');
    shown.add(texts);
  }

  @override
  Future<void> stop() async => stops++;

  @override
  Stream<void> get stopRequests => requests.stream;

  @override
  Future<void> showOffer(OfferNotificationTexts texts) async {}

  @override
  Future<void> cancelOffer() async {}

  bool notifications = true;

  @override
  Future<bool> notificationsAllowed() async => notifications;
}

/// The overrides a share-screen widget test needs (fake server, discovery,
/// folders, identity; no background service).
({List<Override> overrides, FakeServer server}) shareTestOverrides() {
  final identity = FakeIdentity();
  final server = FakeServer(identity);
  return (
    server: server,
    overrides: [
      screenAwakeProvider.overrideWithValue(FakeAwake()),
      secretStoreProvider.overrideWithValue(InMemorySecretStore()),
      deviceIdentityRepositoryProvider.overrideWithValue(identity),
      shareServerProvider.overrideWithValue(server),
      shareDiscoveryProvider.overrideWithValue(FakeDiscovery()),
      sharedFolderFsProvider.overrideWithValue(FakeFolderFs()),
      lifecycleStopsSharingProvider.overrideWithValue(false),
      shareBackgroundProvider.overrideWithValue(const NoShareBackground()),
      pathGuardProvider.overrideWithValue(PathGuard(resolver: (p) async => p)),
      pairingSecretStoreProvider.overrideWithValue(
        PairingSecretStore(autoRefresh: false, clock: DateTime.now),
      ),
    ],
  );
}

/// Connected to "KAF-PC" (no network: screens only read the state).
class FakeConnected extends RemoteConnectionController {
  @override
  RemoteConnectionState build() => const RemoteConnected(
    peerName: 'KAF-PC',
    peerFingerprint: 'ee',
    roots: [],
  );

  /// The other device stopped (ends the engine's offer polling).
  void drop() => state = const RemoteDisconnected(
    peerName: 'KAF-PC',
    reason: DisconnectReason.remoteStopped,
  );
}

/// Ends [FakeConnected]'s link (tests call it before they finish).
void dropFakeConnection(ProviderContainer c) =>
    (c.read(remoteConnectionControllerProvider.notifier) as FakeConnected)
        .drop();
