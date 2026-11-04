import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:kfm/features/connect/domain/device_identity.dart';
import 'package:meta/meta.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

enum ShareServerStatus { stopped, starting, running, error }

/// What the share screen shows (TASK-N1).
@immutable
class ShareServerState {
  const new({
    required this.status,
    this.addresses = const [],
    this.port,
    this.fingerprint,
    this.error,
    this.discoveryError,
    this.keepAlive = ShareKeepAlive.whileOnScreen,
  });

  final ShareServerStatus status;

  /// Wi-Fi + hotspot only, Wi-Fi first, at most [kMaxAdvertisedAddresses].
  final List<LocalAddress> addresses;
  final int? port;

  /// This device's cert fingerprint while running (debug view, N2's QR).
  final String? fingerprint;
  final Object? error;

  /// mDNS advertising failed (N2); QR and manual address still work.
  final Object? discoveryError;

  /// What ends sharing besides Stop (N5b).
  final ShareKeepAlive keepAlive;

  ShareServerState withDiscoveryError(Object? e) => ShareServerState(
    status: status,
    addresses: addresses,
    port: port,
    fingerprint: fingerprint,
    error: error,
    discoveryError: e,
    keepAlive: keepAlive,
  );

  ShareServerState withKeepAlive(ShareKeepAlive k) => ShareServerState(
    status: status,
    addresses: addresses,
    port: port,
    fingerprint: fingerprint,
    error: error,
    discoveryError: discoveryError,
    keepAlive: k,
  );

  static const stopped = ShareServerState(status: ShareServerStatus.stopped);
}

/// How long sharing lasts while running (N5b).
enum ShareKeepAlive {
  /// Until the share screen closes (desktop: behind other windows too).
  whileOnScreen,

  /// Until the share screen closes or the app goes to the background
  /// (iOS; Android when the foreground service couldn't start).
  whileAppOpen,

  /// Also in the background, behind the ongoing notification (Android).
  background,
}

/// No Wi-Fi or hotspot address to share on.
class NoLocalNetworkException implements Exception {
  const new();

  @override
  String toString() => 'NoLocalNetworkException';
}

/// An address the server is reachable on, with its prefix for the
/// same-subnet check.
@immutable
class LocalAddress {
  const new(this.address, this.prefixLength, this.interfaceName);

  final InternetAddress address;

  /// 24 when the OS doesn't report it (dart:io never does).
  final int prefixLength;
  final String interfaceName;

  @override
  bool operator ==(Object other) =>
      other is LocalAddress &&
      other.address == address &&
      other.prefixLength == prefixLength &&
      other.interfaceName == interfaceName;

  @override
  int get hashCode => Object.hash(address, prefixLength, interfaceName);

  @override
  String toString() => '$interfaceName ${address.address}/$prefixLength';
}

/// At most this many addresses are advertised (QR, N2).
const int kMaxAdvertisedAddresses = 3;

/// One network interface as [localShareAddresses] sees it.
typedef InterfaceInfo = ({String name, List<InternetAddress> addresses});

/// Lists IPv4 interfaces (injectable for tests).
typedef InterfaceLister = Future<List<InterfaceInfo>> Function();

Future<List<InterfaceInfo>> _listInterfaces() async => [
  for (final i in await NetworkInterface.list(type: InternetAddressType.IPv4))
    (name: i.name, addresses: i.addresses),
];

/// RFC 1918 (10/8, 172.16/12, 192.168/16).
bool isPrivateIpv4(InternetAddress a) {
  if (a.type != InternetAddressType.IPv4) return false;
  final b = a.rawAddress;
  return b[0] == 10 ||
      (b[0] == 172 && b[1] >= 16 && b[1] <= 31) ||
      (b[0] == 192 && b[1] == 168);
}

final RegExp _androidWifi = RegExp(r'^wlan\d+$');
final RegExp _androidHotspot = RegExp(r'^(ap|swlan)\d+$');

/// Windows adapters that are never a real Wi-Fi/LAN (until PL1 decides).
final RegExp _windowsVirtual = RegExp(
  'vethernet|virtualbox|vmware|hyper-v|loopback|bluetooth|wsl|docker|'
  'tailscale|zerotier|vpn|tap|tun',
  caseSensitive: false,
);

/// The addresses KFM shares on: RFC 1918 **and** a Wi-Fi/hotspot interface.
/// Android: `wlan*` (Wi-Fi first), `ap*`, `swlan*`; mobile data (`rmnet*`,
/// `ccmni*`), VPN (`tun*`, `ppp*`) and everything else are dropped, even
/// with a 10.x address. Windows: every RFC 1918 address of a non-virtual
/// adapter (PL1 refines it). Never loopback, never public.
Future<List<LocalAddress>> localShareAddresses({
  InterfaceLister? list,
  String? operatingSystem,
}) async {
  final os = operatingSystem ?? Platform.operatingSystem;
  final interfaces = await (list ?? _listInterfaces)();
  final wifi = <LocalAddress>[];
  final other = <LocalAddress>[];
  for (final i in interfaces) {
    final int rank;
    switch (os) {
      case 'android':
      case 'ios': // PL2 decides the iOS names; en* is Wi-Fi there.
        if (_androidWifi.hasMatch(i.name) ||
            (os == 'ios' && RegExp(r'^en\d+$').hasMatch(i.name))) {
          rank = 0;
        } else if (_androidHotspot.hasMatch(i.name) ||
            (os == 'ios' && RegExp(r'^bridge\d+$').hasMatch(i.name))) {
          rank = 1;
        } else {
          continue;
        }
      default:
        if (_windowsVirtual.hasMatch(i.name)) continue;
        rank =
            RegExp(
              'wi-?fi|wlan|wireless',
              caseSensitive: false,
            ).hasMatch(i.name)
            ? 0
            : 1;
    }
    for (final a in i.addresses) {
      if (a.isLoopback || !isPrivateIpv4(a)) continue;
      (rank == 0 ? wifi : other).add(LocalAddress(a, 24, i.name));
    }
  }
  return [...wifi, ...other].take(kMaxAdvertisedAddresses).toList();
}

/// Builds the request handler for the addresses being served.
typedef PipelineFactory = Handler Function(List<LocalAddress> served);

/// The HTTPS server of "Share this device" (TASK-N1). Lifecycle only: the
/// routes come from [PipelineFactory] (`buildSharePipeline`).
class ShareServer {
  new(
    this._identity,
    this._pipeline, {
    Future<List<LocalAddress>> Function()? addresses,
    InternetAddress? bindAddress,
    this._preferredPort,
    this._savePort,
  }) : _addresses = addresses ?? localShareAddresses,
       _bindAddress = bindAddress ?? InternetAddress.anyIPv4;

  /// The last port used (N6 follow-up): remembered devices reconnect to
  /// their saved `ip:port`, which only works if the port stays the same.
  final Future<int?> Function()? _preferredPort;
  final Future<void> Function(int port)? _savePort;

  final DeviceIdentityRepository _identity;
  final PipelineFactory _pipeline;
  final Future<List<LocalAddress>> Function() _addresses;

  /// `anyIPv4` in the app (`privateNetworkOnly` rejects peers outside the
  /// served subnets); loopback in tests.
  final InternetAddress _bindAddress;
  HttpServer? _server;
  ShareServerState _running = ShareServerState.stopped;

  bool get isRunning => _server != null;

  /// Starts on the last used port when it's free, otherwise on a random
  /// free port (remembered for next time). Returns the error state when there's no
  /// Wi-Fi or hotspot (nothing listens then). Throws on bind/TLS failures.
  Future<ShareServerState> start() async {
    if (_server != null) return _running;
    final id = await _identity.loadOrCreate();
    final ctx = SecurityContext()
      ..useCertificateChainBytes(utf8.encode(id.certPem))
      ..usePrivateKeyBytes(utf8.encode(await _identity.privateKeyPem()));
    final addresses = await _addresses();
    if (addresses.isEmpty) {
      return const ShareServerState(
        status: ShareServerStatus.error,
        error: NoLocalNetworkException(),
      );
    }
    final server = await _bind(ctx);
    server
      ..idleTimeout = const Duration(seconds: 30)
      ..serverHeader = null;
    // Q1: a response body cut on purpose (Disconnect, a replaced session,
    // a scope edit) or a client gone mid-request ends in an async error
    // inside dart:io ("Content size below specified contentLength"; the
    // client sees the abort). shelf only catches those in the root zone;
    // this keeps them per connection in any zone instead of surfacing as
    // uncaught app errors.
    runZonedGuarded(
      () => shelf_io.serveRequests(
        server,
        _pipeline(addresses),
        poweredByHeader: null,
      ),
      (e, _) => developer.log(
        'share server: connection ended: ${e.runtimeType}',
        name: 'kfm.connect',
      ),
    );
    _server = server;
    return _running = ShareServerState(
      status: ShareServerStatus.running,
      addresses: addresses,
      port: server.port,
      fingerprint: id.fingerprint,
    );
  }

  Future<HttpServer> _bind(SecurityContext ctx) async {
    int? preferred;
    try {
      preferred = await _preferredPort?.call();
    } on Object {
      preferred = null; // a settings read failure only costs the reuse
    }
    if (preferred != null && preferred > 0 && preferred < 65536) {
      try {
        return await HttpServer.bindSecure(_bindAddress, preferred, ctx);
      } on SocketException {
        // Taken by another app: fall through to a random port.
      }
    }
    final server = await HttpServer.bindSecure(_bindAddress, 0, ctx);
    if (server.port != preferred) {
      try {
        await _savePort?.call(server.port);
      } on Object {
        // Not fatal: sharing works; the next run picks a new port again.
      }
    }
    return server;
  }

  /// Closes the port and drops open connections immediately.
  Future<void> stop() async {
    final s = _server;
    _server = null;
    _running = ShareServerState.stopped;
    await s?.close(force: true);
  }
}
