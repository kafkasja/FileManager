import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:kfm/features/connect/domain/pairing.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:nsd/nsd.dart' as nsd;

/// A sharing device found on the LAN. Every field is a hint: the
/// fingerprint is authenticated only by SPAKE2 (TASK-N2).
@immutable
class NearbyDevice {
  const new({
    required this.name,
    required this.address,
    this.deviceId,
    this.fingerprintHint,
  });

  final String name;
  final ShareAddress address;
  final String? deviceId;

  /// TXT `fp`; a mismatch with the TLS cert stops pairing early.
  final String? fingerprintHint;

  @override
  bool operator ==(Object other) =>
      other is NearbyDevice &&
      other.name == name &&
      other.address == address &&
      other.deviceId == deviceId &&
      other.fingerprintHint == fingerprintHint;

  @override
  int get hashCode => Object.hash(name, address, deviceId, fingerprintHint);
}

/// What the sharing device advertises while sharing.
@immutable
class ShareAdvert {
  const new({
    required this.deviceId,
    required this.name,
    required this.fingerprint,
    required this.port,
  });

  final String deviceId;
  final String name;
  final String fingerprint;
  final int port;

  /// TXT `{v, id, name, fp}` (N1 → Discovery).
  Map<String, String> get txt => {
    'v': '$kProtocolVersion',
    'id': deviceId,
    'name': name,
    'fp': fingerprint,
  };
}

/// mDNS advertise + browse behind an interface (the package choice, `nsd`
/// or `bonsoir`, stays hidden; PL1 may swap it on Windows).
abstract interface class ShareDiscovery {
  /// Starts advertising `_kfmshare._tcp`; replaces an earlier advert.
  Future<void> advertise(ShareAdvert advert);

  Future<void> stopAdvertising();

  /// The current list of nearby sharing devices; browsing stops when the
  /// subscription is cancelled. Errors are delivered on the stream.
  Stream<List<NearbyDevice>> browse();
}

/// [ShareDiscovery] over the `nsd` plugin (Android NsdManager, Windows
/// DNS-SD, Apple Bonjour).
class NsdShareDiscovery implements ShareDiscovery {
  nsd.Registration? _registration;

  @override
  Future<void> advertise(ShareAdvert advert) async {
    await stopAdvertising();
    _registration = await nsd.register(
      nsd.Service(
        name: _serviceName(advert.name),
        type: DiscoveryIds.mdnsType,
        port: advert.port,
        txt: {
          for (final e in advert.txt.entries)
            e.key: Uint8List.fromList(utf8.encode(e.value)),
        },
      ),
    );
  }

  @override
  Future<void> stopAdvertising() async {
    final r = _registration;
    _registration = null;
    if (r != null) await nsd.unregister(r);
  }

  @override
  Stream<List<NearbyDevice>> browse() {
    late StreamController<List<NearbyDevice>> controller;
    nsd.Discovery? discovery;
    var cancelled = false;

    void publish() {
      final d = discovery;
      if (d == null || controller.isClosed) return;
      controller.add([
        for (final s in d.services)
          ?nearbyFromService(
            name: s.name,
            host: s.host,
            port: s.port,
            addresses: s.addresses,
            txt: s.txt,
          ),
      ]);
    }

    controller = StreamController<List<NearbyDevice>>(
      onListen: () async {
        try {
          final d = await nsd.startDiscovery(
            DiscoveryIds.mdnsType,
            ipLookupType: nsd.IpLookupType.v4,
          );
          if (cancelled) {
            await nsd.stopDiscovery(d);
            return;
          }
          discovery = d..addListener(publish);
          publish();
        } on Object catch (e, st) {
          if (kDebugMode) debugPrint('mDNS browse failed: $e');
          if (!controller.isClosed) controller.addError(e, st);
        }
      },
      onCancel: () async {
        cancelled = true;
        final d = discovery;
        discovery = null;
        if (d != null) {
          d.removeListener(publish);
          await nsd.stopDiscovery(d);
        }
      },
    );
    return controller.stream;
  }

  /// DNS-SD instance names are at most 63 bytes.
  static String _serviceName(String name) {
    final clean = name.trim().isEmpty ? 'KFM' : name.trim();
    var out = clean;
    while (utf8.encode(out).length > 63) {
      out = out.substring(0, out.length - 1);
    }
    return out;
  }
}

/// Builds a [NearbyDevice] from a resolved service; null when it has no
/// IPv4 address or port, or isn't protocol v1.
@visibleForTesting
NearbyDevice? nearbyFromService({
  required String? name,
  required String? host,
  required int? port,
  required List<InternetAddress>? addresses,
  required Map<String, Uint8List?>? txt,
}) {
  if (port == null || port < 1 || port > 65535) return null;
  String? field(String key) {
    final v = txt?[key];
    if (v == null) return null;
    try {
      return utf8.decode(v);
    } on FormatException {
      return null;
    }
  }

  final v = field('v');
  if (v != null && v != '$kProtocolVersion') return null;
  final ipv4 = addresses
      ?.where((a) => a.type == InternetAddressType.IPv4 && !a.isLoopback)
      .firstOrNull;
  final hostAddress =
      ipv4?.address ?? InternetAddress.tryParse(host ?? '')?.address;
  if (hostAddress == null) return null;
  final fp = field('fp')?.toLowerCase();
  return NearbyDevice(
    name: field('name') ?? name ?? hostAddress,
    address: (host: hostAddress, port: port),
    deviceId: field('id'),
    fingerprintHint: fp != null && RegExp(r'^[0-9a-f]{64}$').hasMatch(fp)
        ? fp
        : null,
  );
}

/// Parses a typed `ip:port` (manual entry); null when invalid. Only
/// literal IPv4 addresses (no DNS lookups, rule 7).
ShareAddress? parseManualAddress(String input) {
  final text = input.trim();
  final i = text.lastIndexOf(':');
  if (i <= 0) return null;
  final ip = InternetAddress.tryParse(text.substring(0, i));
  final port = int.tryParse(text.substring(i + 1));
  if (ip == null || ip.type != InternetAddressType.IPv4) return null;
  if (port == null || port < 1 || port > 65535) return null;
  return (host: ip.address, port: port);
}
