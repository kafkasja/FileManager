import 'dart:async';

import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/features/connect/data/discovery.dart';
import 'package:kfm/features/connect/data/known_devices_dao.dart';
import 'package:kfm/features/connect/data/pairing_client.dart';
import 'package:kfm/features/connect/domain/connection_request.dart';
import 'package:kfm/features/connect/domain/known_device.dart';
import 'package:kfm/features/connect/domain/pairing.dart';
import 'package:kfm/features/connect/domain/protocol.dart';

/// Timeout of the best-effort `GET /v1/info` after a pairing (peer
/// platform for the remembered-devices list).
const Duration kPeerInfoTimeout = Duration(seconds: 2);

/// `host:port` of [base].
String hostPortOf(Uri base) => '${base.host}:${base.port}';

/// Parses a stored `host:port`; null when malformed.
ShareAddress? parseHostPort(String text) {
  final i = text.lastIndexOf(':');
  if (i <= 0) return null;
  final port = int.tryParse(text.substring(i + 1));
  if (port == null || port < 1 || port > 65535) return null;
  return (host: text.substring(0, i), port: port);
}

/// Reconnects to remembered devices without a QR (TASK-N6) and saves the
/// peer after a QR/code pairing. N9/N10 call [reconnect].
class KnownDeviceConnector {
  new({
    required this._repo,
    required this._client,
    required this._nearby,
    required this._connect,
  });

  final KnownDevicesRepository _repo;
  final PairingClient _client;

  /// The current mDNS list (may be empty when nobody browses).
  final List<NearbyDevice> Function() _nearby;

  /// Hands a result to `RemoteConnectionController.connect`.
  final void Function(PairingSuccess result) _connect;

  /// Where to look for [device]: mDNS entries whose TXT `fp` matches (a
  /// hint; the pin decides), then its stored addresses. No duplicates.
  static List<ShareAddress> candidatesFor(
    KnownDevice device,
    List<NearbyDevice> nearby,
  ) {
    final out = <ShareAddress>[];
    for (final n in nearby) {
      if (n.fingerprintHint == device.fingerprint && !out.contains(n.address)) {
        out.add(n.address);
      }
    }
    for (final a in device.lastAddresses) {
      final parsed = parseHostPort(a);
      if (parsed != null && !out.contains(parsed)) out.add(parsed);
    }
    return out;
  }

  /// Pairs with the remembered device [fingerprint] (`/v1/pair/known`)
  /// and refreshes its row (`touch`). Throws [PairingException]
  /// (`notAllowed` for a device we don't know).
  Future<PairingSuccess> pair(
    String fingerprint, {
    PairingWaiting? onWaiting,
    PairingCancel? cancel,
    SessionPurpose purpose = SessionPurpose.connect,
  }) async {
    final device = await _repo.byFingerprint(fingerprint);
    if (device == null) {
      throw const PairingException(PairingFailure.notAllowed);
    }
    final result = await _client.pairKnown(
      fingerprint: fingerprint,
      name: device.name,
      candidates: candidatesFor(device, _nearby()),
      onWaiting: onWaiting,
      cancel: cancel,
      purpose: purpose,
    );
    // Shown via the write queue's error stream when it fails.
    _repo.touch(fingerprint, [hostPortOf(result.http.base)]).fireAndForget();
    return result;
  }

  /// The one entry point N9/N10 use: returns once connected, or throws
  /// [PairingException] for the caller to show (rule 8).
  /// N12: [purpose] send pairs a send-only session (no prompt there).
  Future<void> reconnect(
    String fingerprint, {
    SessionPurpose purpose = SessionPurpose.connect,
  }) async {
    final result = await pair(fingerprint, purpose: purpose);
    _connect(result);
  }

  /// Client side, after an accepted QR/code pairing with "Remember this
  /// device" on: saves the peer (it served us, so `canShareToUs`). The
  /// platform comes from a best-effort pinned `GET /v1/info`.
  Future<KnownDevice> rememberServer(PairingSuccess result) async {
    var platform = '';
    var name = result.peerName;
    try {
      final info = await result.http
          .getJson(ApiRoutes.info, decode: ServerInfoDto.fromJson)
          .timeout(kPeerInfoTimeout);
      platform = info.platform;
      if (name.trim().isEmpty) name = info.name;
    } on Object {
      // Best effort: the list shows no platform.
    }
    return await _repo.saveAfterPairing(
      PairedPeer(
        fingerprint: result.peerFingerprint,
        peerDeviceId: result.accepted.serverDeviceId,
        name: name,
        platform: platform,
        addresses: [hostPortOf(result.http.base)],
        canShareToUs: true,
      ),
      temporary: false,
    );
  }
}
