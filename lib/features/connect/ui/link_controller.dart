import 'dart:async';
import 'dart:developer' as developer;

import 'package:kfm/app/notification_l10n.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/platform/host_platform.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/data/crypto/identity_proof.dart';
import 'package:kfm/features/connect/data/link_invite_store.dart';
import 'package:kfm/features/connect/data/link_scope.dart';
import 'package:kfm/features/connect/data/pairing_client.dart';
import 'package:kfm/features/connect/data/remote_errors.dart';
import 'package:kfm/features/connect/data/share_server.dart';
import 'package:kfm/features/connect/data/shared_folder_fs.dart';
import 'package:kfm/features/connect/domain/connection_request.dart';
import 'package:kfm/features/connect/domain/link.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:kfm/features/connect/domain/remote_connection_state.dart';
import 'package:kfm/features/connect/domain/share_scope.dart';
import 'package:kfm/features/connect/ui/remote_connection_controller.dart';
import 'package:kfm/features/connect/ui/share_server_controller.dart';
import 'package:kfm/features/external_storage/data/places_repository.dart';
import 'package:kfm/features/external_storage/domain/storage_place.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'link_controller.g.dart';

/// Timeout of `POST /v1/link` (the peer connects back meanwhile).
const Duration kLinkRequestTimeout = Duration(seconds: 20);

/// The link this device is part of (TASK-E1), beyond what the two
/// sessions show: this side's own perms, the peer's (shown only) and
/// whether the reverse half works.
@immutable
final class LinkInfo {
  const new({
    required this.peerFingerprint,
    required this.peerName,
    required this.mine,
    this.theirs,
    this.reverseReachable = false,
    this.initiator = false,
  });

  final String peerFingerprint;
  final String peerName;

  /// What this device lets the peer do.
  final LinkPerms mine;

  /// What the peer says it lets this device do (display only).
  final LinkPerms? theirs;
  final bool reverseReachable;

  /// This device scanned / typed (it asked for the back-link).
  final bool initiator;

  LinkInfo copyWith({
    LinkPerms? mine,
    LinkPerms? theirs,
    bool? reverseReachable,
  }) => LinkInfo(
    peerFingerprint: peerFingerprint,
    peerName: peerName,
    mine: mine ?? this.mine,
    theirs: theirs ?? this.theirs,
    reverseReachable: reverseReachable ?? this.reverseReachable,
    initiator: initiator,
  );
}

/// TASK-E1 two-way link: both devices run a server and each is the
/// other's client. Owns the server's lifetime while a link is active (not
/// a widget's dispose), the back-link (`/v1/link` → `/v1/link/join`), each
/// side's own perms (scope + take prompt) and the link's end on either
/// side. `RemoteConnectionController` stays single-peer.
@Riverpod(keepAlive: true)
class LinkController extends _$LinkController {
  /// Screens that show this device's code (they keep the server running).
  int _holds = 0;

  /// The peer this device's client is connected to (to see its end).
  String? _connectedPeer;

  @override
  LinkInfo? build() {
    ref.listen(remoteConnectionControllerProvider, (prev, next) {
      switch (next) {
        case RemoteConnected(:final peerFingerprint):
          _connectedPeer = peerFingerprint;
        case RemoteDisconnected(:final reason):
          final fp = _connectedPeer;
          _connectedPeer = null;
          if (fp != null && state?.peerFingerprint == fp) {
            _end(fp, closedByUser: reason == DisconnectReason.userClosed);
          }
        case RemoteIdle():
          _connectedPeer = null;
      }
    });
    return null;
  }

  /// Sharing stopped (Stop, the notification, the tray): the link ends.
  /// `ShareServerController` calls it (no listener here, so reading the
  /// menus doesn't start the sharing machinery).
  void onSharingStopped() {
    if (state case final s?) _end(s.peerFingerprint, closedByUser: true);
  }

  // ---- server lifetime --------------------------------------------------

  /// A screen showing this device's code opened (it starts sharing itself).
  void holdServer() {
    _holds++;
  }

  /// That screen closed: sharing stops unless a link still needs it.
  void releaseServer() {
    if (_holds > 0) _holds--;
    _maybeStop();
  }

  bool get _needsServer => _holds > 0 || state != null;

  void _maybeStop() {
    if (_needsServer) return;
    final c = ref.read(shareServerControllerProvider);
    if (c.status == ShareServerStatus.stopped) return;
    unawaited(ref.read(shareServerControllerProvider.notifier).stopSharing());
  }

  // ---- perms --------------------------------------------------------------

  /// This device's stored choice for [fp] (remembered row), else the
  /// defaults (both on: the user decision).
  Future<LinkPerms> storedPerms(String fp) async {
    try {
      final row = await ref
          .read(knownDevicesRepositoryProvider)
          .byFingerprint(fp);
      if (row != null && !row.isTemporary) {
        return LinkPerms(see: row.letSee, takeFreely: row.letTakeFreely);
      }
    } on Object catch (e) {
      developer.log('link perms not read: $e', name: 'kfm.connect');
    }
    return const LinkPerms();
  }

  /// Applies [perms] for [fp] on this device's server: the take prompt
  /// rule and the scope (all storage, the remembered "Limit to folders",
  /// or nothing). [persist]: also stored on the remembered row.
  Future<void> applyPerms(
    String fp,
    LinkPerms perms, {
    bool persist = false,
  }) async {
    ref.read(linkPermsStoreProvider).set(fp, perms);
    if (state case final s? when s.peerFingerprint == fp) {
      state = s.copyWith(mine: perms);
    }
    if (persist) {
      ref
          .read(knownDevicesRepositoryProvider)
          .setLinkPerms(fp, see: perms.see, takeFreely: perms.takeFreely)
          .fireAndForget();
    }
    final scopes = ref.read(shareScopeStoreProvider);
    if (!perms.see) {
      scopes.set(fp, ShareScope.empty);
      return;
    }
    try {
      final stored = await ref.read(storedScopeLoaderProvider)(fp);
      if (stored.roots.isNotEmpty) {
        // "Limit to folders…" (the old N4/N6 folders).
        scopes.set(fp, ShareScope(stored.roots));
        return;
      }
    } on Object catch (e) {
      developer.log('stored folders not loaded: $e', name: 'kfm.connect');
    }
    scopes.set(fp, ShareScope(await _allRoots()));
  }

  Future<List<SharedRoot>> _allRoots() async {
    final l10n = ref.read(notificationL10nProvider);
    final primary = ref.read(sharedFolderFsProvider).primaryRoot;
    // Not awaited: an unwatched provider's future may never complete
    // (Riverpod 3 pauses it); the places known now are enough.
    final places = ref.read(placesProvider).value ?? const <StoragePlace>[];
    return await allStorageRoots(
      primaryRoot: primary,
      primaryLabel: primaryRootLabel(l10n, primary, windows: isWindowsHost),
      places: places,
      salt: await ref.read(deviceIdentityRepositoryProvider).rootIdSalt(),
      guard: ref.read(pathGuardProvider),
      l10n: l10n,
    );
  }

  /// `beforeIssue` of every accepted connect pairing on this device's
  /// server: the perms the link dialog stored (or the remembered ones).
  Future<void> prepareSession(String fp) async {
    final perms =
        ref.read(linkPermsStoreProvider).of(fp) ?? await storedPerms(fp);
    await applyPerms(fp, perms);
  }

  // ---- the device that scanned (A) ---------------------------------------

  /// A pairing finished on this device (QR, code or a remembered
  /// reconnect): connect, then ask the peer to connect back. [perms]: the
  /// waiting screen's checkboxes (null = the stored or default ones).
  Future<void> onPaired(PairingSuccess result, {LinkPerms? perms}) async {
    ref.read(remoteConnectionControllerProvider.notifier).connect(result);
    if (result.sendOnly) return;
    final fp = result.peerFingerprint;
    final mine = perms ?? await storedPerms(fp);
    if (!ref.mounted) return;
    state = LinkInfo(
      peerFingerprint: fp,
      peerName: result.peerName,
      mine: mine,
      initiator: true,
    );
    ref.read(linkPermsStoreProvider).set(fp, mine);
    await _backLink(result, mine);
  }

  Future<void> _backLink(PairingSuccess result, LinkPerms mine) async {
    final fp = result.peerFingerprint;
    var reverse = false;
    LinkPerms? theirs;
    try {
      final share = ref.read(shareServerControllerProvider.notifier);
      if (ref.read(shareServerControllerProvider).status !=
          ShareServerStatus.running) {
        await share.startSharing();
      }
      final port = ref.read(shareServerControllerProvider).port;
      if (port == null ||
          ref.read(shareServerControllerProvider).status !=
              ShareServerStatus.running) {
        throw StateError('no server');
      }
      final invite = ref
          .read(linkInviteStoreProvider)
          .issue(peerFingerprint: fp, remoteIp: result.http.base.host);
      final res = await result.http.postJson(
        ApiRoutes.link,
        LinkRequestDto(
          port: port,
          invite: b64url(invite),
          perms: mine,
        ).toJson(),
        decode: LinkResponseDto.fromJson,
        timeout: kLinkRequestTimeout,
      );
      reverse = res.reverse;
      theirs = res.perms;
    } on RemoteApiException catch (e) {
      // 404: an older peer without links (one-way, N12b sends back).
      developer.log('back-link refused: ${e.status}', name: 'kfm.connect');
    } on Object catch (e) {
      developer.log('back-link failed: $e', name: 'kfm.connect');
    }
    if (!ref.mounted) return;
    if (state case final s? when s.peerFingerprint == fp) {
      state = s.copyWith(reverseReachable: reverse, theirs: theirs);
    }
    if (!reverse) _maybeStop();
  }

  /// `/v1/link/join` passed every check: B's session on this device with
  /// this side's perms (no second prompt: this device asked for it).
  Future<PairAcceptedDto> onJoin(
    ClientHelloDto hello,
    LinkInvite invite,
    String remoteIp,
  ) async {
    final fp = invite.peerFingerprint;
    final perms = state?.peerFingerprint == fp
        ? state!.mine
        : await storedPerms(fp);
    await applyPerms(fp, perms);
    final issued = ref
        .read(clientSessionStoreProvider)
        .issue(
          clientFingerprint: fp,
          clientDeviceId: hello.clientDeviceId,
          clientName: hello.clientName,
        );
    final id = await ref.read(deviceIdentityRepositoryProvider).loadOrCreate();
    return PairAcceptedDto(
      token: issued.token,
      serverDeviceId: id.deviceId,
      roots: ref.read(shareScopeStoreProvider).scopeOf(fp).toDtos(),
    );
  }

  // ---- the device that showed its code (B) -------------------------------

  /// `POST /v1/link` from the paired client: connect back to it, pinned
  /// to the key it proved in the pairing.
  Future<LinkResponseDto> onLinkRequest(
    ClientSession session,
    LinkRequestDto dto,
    String remoteIp,
  ) async {
    final fp = session.clientFingerprint;
    final mine =
        ref.read(linkPermsStoreProvider).of(fp) ?? await storedPerms(fp);
    if (!ref.mounted) return LinkResponseDto(reverse: false, perms: mine);
    state = LinkInfo(
      peerFingerprint: fp,
      peerName: session.clientName,
      mine: mine,
      theirs: dto.perms,
    );
    try {
      final result = await ref
          .read(pairingClientProvider)
          .joinLink(
            host: remoteIp,
            port: dto.port,
            fingerprint: fp,
            name: session.clientName,
            invite: fromB64url(dto.invite)!,
          );
      if (!ref.mounted || state?.peerFingerprint != fp) {
        result.http.close();
        return LinkResponseDto(reverse: false, perms: mine);
      }
      ref.read(remoteConnectionControllerProvider.notifier).connect(result);
      state = state!.copyWith(reverseReachable: true);
      return LinkResponseDto(reverse: true, perms: mine);
    } on Object catch (e) {
      // Emulator NAT, a firewall, a Public network: one way only.
      developer.log('reverse link failed: $e', name: 'kfm.connect');
      return LinkResponseDto(reverse: false, perms: mine);
    }
  }

  // ---- the end ------------------------------------------------------------

  /// "Disconnect" on either side: tells the peer (`/v1/link/close`, which
  /// ends both halves there), then ends both here.
  Future<void> disconnect() async {
    final s = state;
    final remote = ref.read(remoteConnectionControllerProvider.notifier);
    if (s == null) {
      await remote.disconnect();
      return;
    }
    final http = remote.http;
    if (http != null && _connectedPeer == s.peerFingerprint) {
      try {
        await http.postJson<void>(
          ApiRoutes.linkClose,
          const <String, Object?>{},
          decode: (_) {},
          timeout: const Duration(seconds: 3),
        );
      } on Object {
        // Gone already; its heartbeat ends its half.
      }
    }
    // Ends this device's client too (its session/close).
    _end(s.peerFingerprint, closedByUser: true);
  }

  /// `POST /v1/link/close` from the peer.
  Future<void> onPeerClosed(ClientSession session) async {
    final fp = session.clientFingerprint;
    if (state?.peerFingerprint != fp) {
      // Not (or no longer) linked: just its session.
      ref.read(clientSessionStoreProvider).revoke(session.sessionId);
      return;
    }
    _end(fp, closedByUser: true);
    if (_connectedPeer == fp) {
      await ref.read(remoteConnectionControllerProvider.notifier).disconnect();
    }
  }

  /// Ends both halves with [fp] on this device. A user's close also drops
  /// the take grants and stops a server only the link needed. A lost
  /// network keeps the grants (a resumed transfer doesn't ask again), and
  /// the device that showed its code keeps sharing, so the other one (or
  /// its paused transfers, N10) can reconnect; the one that scanned starts
  /// its server again with the next back-link.
  void _end(String fp, {required bool closedByUser}) {
    final s = state;
    if (s?.peerFingerprint != fp) return;
    state = null;
    ref.read(clientSessionStoreProvider).revokeByFingerprint(fp);
    if (closedByUser) {
      ref.read(takeGateProvider).clearPeer(fp);
      ref.read(linkPermsStoreProvider).remove(fp);
    }
    if (_connectedPeer == fp) {
      unawaited(
        ref.read(remoteConnectionControllerProvider.notifier).disconnect(),
      );
    }
    if (closedByUser || s!.initiator) _maybeStop();
  }
}
