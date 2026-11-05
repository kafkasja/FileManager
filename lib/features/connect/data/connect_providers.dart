import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/android/files_channel.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/files/staging_dir.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/platform/host_platform.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/core/platform/windows/desktop_shell_provider.dart';
import 'package:kfm/core/platform/windows/index_roots.dart';
import 'package:kfm/features/background_jobs/data/android_presence_port.dart';
import 'package:kfm/features/background_jobs/data/background_jobs_providers.dart';
import 'package:kfm/features/background_jobs/data/presence_share_background.dart';
import 'package:kfm/features/connect/data/accept_gate.dart';
import 'package:kfm/features/connect/data/camera_access.dart';
import 'package:kfm/features/connect/data/client_session_store.dart';
import 'package:kfm/features/connect/data/device_identity_repository_impl.dart';
import 'package:kfm/features/connect/data/discovery.dart';
import 'package:kfm/features/connect/data/known_devices_dao.dart';
import 'package:kfm/features/connect/data/known_pair_limiter.dart';
import 'package:kfm/features/connect/data/middleware/allow_list.dart';
import 'package:kfm/features/connect/data/middleware/authenticate.dart';
import 'package:kfm/features/connect/data/offer_copy.dart';
import 'package:kfm/features/connect/data/offer_service.dart';
import 'package:kfm/features/connect/data/pair_nonce_store.dart';
import 'package:kfm/features/connect/data/pairing_client.dart';
import 'package:kfm/features/connect/data/pairing_secret_store.dart';
import 'package:kfm/features/connect/data/path_guard.dart';
import 'package:kfm/features/connect/data/remote_trash_service.dart';
import 'package:kfm/features/connect/data/routes/file_routes.dart';
import 'package:kfm/features/connect/data/routes/inbox_routes.dart';
import 'package:kfm/features/connect/data/routes/offer_routes.dart';
import 'package:kfm/features/connect/data/routes/pair_routes.dart';
import 'package:kfm/features/connect/data/routes/roots_routes.dart';
import 'package:kfm/features/connect/data/routes/session_routes.dart';
import 'package:kfm/features/connect/data/routes/upload_routes.dart';
import 'package:kfm/features/connect/data/secret_store.dart';
import 'package:kfm/features/connect/data/server_pipeline.dart';
import 'package:kfm/features/connect/data/share_background.dart';
import 'package:kfm/features/connect/data/share_change_tracker.dart';
import 'package:kfm/features/connect/data/share_offers_dao.dart';
import 'package:kfm/features/connect/data/share_scope_store.dart';
import 'package:kfm/features/connect/data/share_server.dart';
import 'package:kfm/features/connect/data/shared_folder_fs.dart';
import 'package:kfm/features/connect/data/upload_store.dart';
import 'package:kfm/features/connect/data/windows_share_check.dart';
import 'package:kfm/features/connect/domain/connection_request.dart';
import 'package:kfm/features/connect/domain/device_identity.dart';
import 'package:kfm/features/connect/domain/known_device.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:kfm/features/connect/domain/share_offer.dart';
import 'package:kfm/features/connect/domain/share_scope.dart';
import 'package:kfm/features/transfers/data/transfer_providers.dart'
    show transferPreprocessorProvider;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connect_providers.g.dart';

/// Secure storage for the device identity (TASK-N1).
@Riverpod(keepAlive: true)
SecretStore secretStore(Ref ref) => PlatformSecretStore();

/// The device model, the default share name. Android: maker + model;
/// elsewhere the host name.
@Riverpod(keepAlive: true)
Future<String> deviceModelName(Ref ref) async {
  try {
    if (Platform.isAndroid) {
      final model = (await FilesChannel().deviceModel()).trim();
      if (model.isNotEmpty) return model;
    }
    return Platform.localHostname;
  } on Object {
    return 'KFM';
  }
}

/// The name other devices see: `connect.displayName`, or the device model
/// when it is empty.
Future<String> resolveShareDisplayName(Ref ref) async {
  final custom =
      (await ref
              .read(settingsRepositoryProvider)
              .read(AppSettings.connectDisplayName))
          .trim();
  if (custom.isNotEmpty) return custom;
  return await ref.read(deviceModelNameProvider.future);
}

/// 'android' | 'windows' | 'ios'.
String get currentPlatformName => Platform.operatingSystem;

@Riverpod(keepAlive: true)
DeviceIdentityRepository deviceIdentityRepository(Ref ref) =>
    DeviceIdentityRepositoryImpl(
      store: ref.watch(secretStoreProvider),
      displayName: () => resolveShareDisplayName(ref),
      platform: currentPlatformName,
    );

/// This install's identity; generated on first use (in an isolate).
@Riverpod(keepAlive: true)
Future<DeviceIdentity> deviceIdentity(Ref ref) =>
    ref.watch(deviceIdentityRepositoryProvider).loadOrCreate();

/// Pair nonces of the current sharing run (N2, N6).
@Riverpod(keepAlive: true)
PairNonceStore pairNonceStore(Ref ref) => PairNonceStore();

/// QR secret + short code of the current sharing run (N2).
@Riverpod(keepAlive: true)
PairingSecretStore pairingSecretStore(Ref ref) {
  final store = PairingSecretStore();
  ref.onDispose(store.clear);
  return store;
}

/// The pending accept decision of the current sharing run (N3).
@Riverpod(keepAlive: true)
AcceptGate acceptGate(Ref ref) {
  final gate = AcceptGate();
  ref.onDispose(gate.cancelAll);
  return gate;
}

/// Bearer-token sessions of the current sharing run (N3).
@Riverpod(keepAlive: true)
ClientSessionStore clientSessionStore(Ref ref) {
  final store = ClientSessionStore();
  ref.onDispose(store.clear);
  return store;
}

/// Folder allow-lists of the current sharing run (N4).
@Riverpod(keepAlive: true)
ShareScopeStore shareScopeStore(Ref ref) {
  final store = ShareScopeStore(
    sessions: ref.watch(clientSessionStoreProvider),
  );
  ref.onDispose(store.clear);
  return store;
}

/// One client's shared folders, for the share screen and the picker.
@riverpod
Stream<ShareScope> shareScope(Ref ref, String clientFingerprint) {
  final store = ref.watch(shareScopeStoreProvider);
  // Subscribed before the first value, so no change is lost in between.
  final out = StreamController<ShareScope>();
  final sub = store.changes
      .where((fp) => fp == clientFingerprint)
      .listen((_) => out.add(store.scopeOf(clientFingerprint)));
  out.add(store.scopeOf(clientFingerprint));
  ref.onDispose(() {
    unawaited(sub.cancel());
    unawaited(out.close());
  });
  return out.stream;
}

/// Uploads to this device (N9). N10: partials are loaded from their
/// `.json` on first use and survive restarts and stop sharing.
@Riverpod(keepAlive: true)
UploadStore uploadStore(Ref ref) {
  final store = UploadStore(staging: transferStagingDir);
  ref.onDispose(store.stop);
  return store;
}

/// Path canonicalisation + exclusions (N4).
@Riverpod(keepAlive: true)
PathGuard pathGuard(Ref ref) => PathGuard(windows: isWindowsHost);

/// The per-route allow-list wrapper every file route uses (N4; N7/N10/N11
/// wrap their handlers with `guarded`).
@Riverpod(keepAlive: true)
AllowListGuard allowListGuard(Ref ref) {
  final scopes = ref.watch(shareScopeStoreProvider);
  return AllowListGuard(
    scopeOf: scopes.scopeOf,
    source: () => ref.read(fileSourceProvider),
    paths: ref.watch(pathGuardProvider),
    grants: LazyOfferGrants(() => ref.read(offerServiceProvider)),
  );
}

/// Send-files offers (TASK-N12).
@Riverpod(keepAlive: true)
OfferRepository offerRepository(Ref ref) => OfferRepository(
  ShareOffersDao(ref.watch(appDatabaseProvider)),
  ref.watch(dbWriteQueueProvider),
);

/// The platform's downloads folder: Android `/storage/emulated/0/Download`,
/// elsewhere `~/Downloads` (PL1).
String platformDownloadsFolder() {
  if (Platform.isAndroid) return '/storage/emulated/0/Download';
  final home =
      Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '';
  return '$home/Downloads'.replaceAll(r'\', '/');
}

/// E1: `Downloads/KFM`, where received files go unless the user picked
/// another folder (Settings → receive folder).
String defaultReceiveFolder() => '${platformDownloadsFolder()}/KFM';

/// E1: the user's receive folder setting ('' = default). Loaded once;
/// [set] writes it (only the settings row changes it; it is never part of
/// a backup).
@Riverpod(keepAlive: true)
class ReceiveFolderSetting extends _$ReceiveFolderSetting {
  @override
  String build() {
    unawaited(
      ref.read(settingsRepositoryProvider).read(AppSettings.receiveFolder).then(
        (v) {
          if (ref.mounted && v != state) state = v;
        },
        onError: (Object _) {},
      ),
    );
    return '';
  }

  /// Saves [folder] ('' = the default) for new receives.
  Future<void> set(String folder) async {
    state = folder;
    await ref
        .read(settingsRepositoryProvider)
        .write(AppSettings.receiveFolder, folder);
  }
}

/// Where received files go (both directions; one folder per sender below
/// it): the receive folder setting, else [defaultReceiveFolder].
@Riverpod(keepAlive: true)
String receiveDownloadsRoot(Ref ref) {
  final custom = ref.watch(receiveFolderSettingProvider);
  return custom.isNotEmpty ? custom : defaultReceiveFolder();
}

/// The receiving side of send files (N12): offers, prompts, grants.
@Riverpod(keepAlive: true)
OfferService offerService(Ref ref) {
  final service = OfferService(
    repo: ref.watch(offerRepositoryProvider),
    devices: ref.watch(knownDevicesRepositoryProvider),
    sessions: () => ref.read(clientSessionStoreProvider),
    uploads: ref.watch(uploadStoreProvider),
    freeBytes: (path) => ref.read(fileSourceProvider).freeBytes(path),
    downloadsRoot: ref.read(receiveDownloadsRootProvider),
    // E1: the receive folder setting can change while the service lives.
    currentDownloadsRoot: () => ref.read(receiveDownloadsRootProvider),
    serverFingerprint: () async =>
        (await ref.read(deviceIdentityRepositoryProvider).loadOrCreate())
            .fingerprint,
    ownName: () async =>
        (await ref.read(deviceIdentityRepositoryProvider).loadOrCreate())
            .displayName,
    staging: transferStagingDir,
    prepareCopy: (f, offerId, seq) => prepareOfferCopy(
      f,
      dir: () async =>
          Directory('${(await transferStagingDir()).path}/offer-$offerId'),
      seq: seq,
      enabled: () => ref
          .read(settingsRepositoryProvider)
          .read(AppSettings.privacyStripLocation),
      prepare: (f) => ref
          .read(transferPreprocessorProvider)
          .prepare(f, ref.read(fileSourceProvider)),
    ),
  );
  ref.onDispose(service.dispose);
  return service;
}

/// Every offer this device's server holds, newest first (Transfers
/// Received / Offered cards).
@riverpod
Stream<List<ShareOffer>> shareOffers(Ref ref) =>
    ref.watch(offerRepositoryProvider).watchAll();

/// Incoming offers waiting for the receiver's decision (N12 prompter).
@Riverpod(keepAlive: true)
Stream<List<OfferPrompt>> offerPrompts(Ref ref) async* {
  final service = ref.watch(offerServiceProvider);
  yield service.prompts;
  yield* service.promptChanges;
}

/// The request the accept dialog shows (N3); null when none.
@Riverpod(keepAlive: true)
class PendingRequest extends _$PendingRequest {
  @override
  ConnectionRequest? build() {
    final gate = ref.watch(acceptGateProvider);
    final sub = gate.events.listen((_) => state = gate.pending);
    ref.onDispose(sub.cancel);
    return gate.pending;
  }

  /// The dialog's answer.
  void decide(String requestId, ConnectionDecision decision) =>
      ref.read(acceptGateProvider).decide(requestId, decision);
}

/// Clients with a live session, oldest first (share screen list).
@riverpod
Stream<List<ClientSession>> connectedClients(Ref ref) async* {
  final store = ref.watch(clientSessionStoreProvider);
  yield store.sessions;
  yield* store.changes;
}

/// Remembered devices (TASK-N6).
@Riverpod(keepAlive: true)
KnownDevicesRepository knownDevicesRepository(Ref ref) =>
    KnownDevicesRepository(
      KnownDevicesDao(ref.watch(appDatabaseProvider)),
      ref.watch(dbWriteQueueProvider),
    );

/// The remembered-devices list (temporary rows hidden).
@riverpod
Stream<List<KnownDevice>> knownDevices(Ref ref) =>
    ref.watch(knownDevicesRepositoryProvider).watchVisible();

/// Startup cleanup (N6): temporary rows not seen for 7 days. The app
/// watches it once.
@Riverpod(keepAlive: true)
Future<int> knownDevicesPurge(Ref ref) =>
    ref.watch(knownDevicesRepositoryProvider).purgeTemporary();

/// Failed `/v1/pair/known` calls per IP of the current sharing run (N6).
@Riverpod(keepAlive: true)
KnownPairLimiter knownPairLimiter(Ref ref) {
  final limiter = KnownPairLimiter();
  ref.onDispose(limiter.clear);
  return limiter;
}

/// Loads a remembered device's stored folders, re-checked on disk.
typedef StoredScopeLoader = Future<StoredScope> Function(String fingerprint);

@Riverpod(keepAlive: true)
StoredScopeLoader storedScopeLoader(Ref ref) => (fp) async {
  final salt = await ref.read(deviceIdentityRepositoryProvider).rootIdSalt();
  final fs = ref.read(sharedFolderFsProvider);
  return await ref
      .read(knownDevicesRepositoryProvider)
      .allowedRoots(
        fp,
        salt: salt,
        guard: ref.read(pathGuardProvider),
        exists: fs.exists,
      );
};

/// What happens to a verified pairing request: the accept prompt (N3).
/// N6: on accept, a remembered device's stored folders are seeded before
/// the answer lists the roots.
@Riverpod(keepAlive: true)
PairHandOff pairHandOff(Ref ref) => promptHandOff(
  gate: ref.watch(acceptGateProvider),
  sessions: ref.watch(clientSessionStoreProvider),
  serverDeviceId: () async =>
      (await ref.read(deviceIdentityRepositoryProvider).loadOrCreate())
          .deviceId,
  roots: (fp) => ref.read(shareScopeStoreProvider).scopeOf(fp).toDtos(),
  beforeIssue: (candidate) async {
    if (candidate.method == PairMethod.known) {
      // A failure shows through the write queue's error stream.
      ref
          .read(knownDevicesRepositoryProvider)
          .touch(candidate.clientFingerprint, const [])
          .fireAndForget();
    }
    await seedStoredScope(
      load: ref.read(storedScopeLoaderProvider),
      scopes: ref.read(shareScopeStoreProvider),
      clientFingerprint: candidate.clientFingerprint,
    );
  },
);

/// Seeds [clientFingerprint]'s scope from its stored folders (N6). A
/// failed read leaves the scope as it is: the share screen reads the same
/// folders and opens the picker instead (where the error shows).
Future<void> seedStoredScope({
  required StoredScopeLoader load,
  required ShareScopeStore scopes,
  required String clientFingerprint,
}) async {
  try {
    final stored = await load(clientFingerprint);
    if (stored.roots.isNotEmpty) {
      scopes.set(clientFingerprint, ShareScope(stored.roots));
    }
  } on Object catch (e) {
    developer.log('stored folders not loaded: $e', name: 'kfm.connect');
  }
}

/// mDNS advertise + browse (N2).
@Riverpod(keepAlive: true)
ShareDiscovery shareDiscovery(Ref ref) => NsdShareDiscovery();

/// Nearby sharing devices while the Connect screen lists them.
@riverpod
Stream<List<NearbyDevice>> nearbyDevices(Ref ref) =>
    ref.watch(shareDiscoveryProvider).browse();

/// The connecting side of pairing (N2).
@Riverpod(keepAlive: true)
PairingClient pairingClient(Ref ref) =>
    PairingClient(identity: ref.watch(deviceIdentityRepositoryProvider));

/// Camera permission for "Scan QR".
@Riverpod(keepAlive: true)
CameraAccess cameraAccess(Ref ref) => const PlatformCameraAccess();

/// Whether going to the background stops sharing (N5) when there's no
/// [shareBackground] service (iOS, or Android when the system refuses it).
/// On desktop the share screen stays usable behind other windows.
@Riverpod(keepAlive: true)
bool lifecycleStopsSharing(Ref ref) => Platform.isAndroid || Platform.isIOS;

/// PL1: Public-network check + firewall explainer before sharing binds on
/// Windows; null elsewhere.
@Riverpod(keepAlive: true)
WindowsShareCheck? windowsShareCheck(Ref ref) {
  if (!isWindowsHost) return null;
  final channel = ref.watch(windowsChannelProvider);
  final settings = ref.watch(settingsRepositoryProvider);
  return WindowsShareCheck(
    isPublic: channel.networkIsPublic,
    firewallExplained: () =>
        settings.read(AppSettings.windowsFirewallExplained),
    markFirewallExplained: () =>
        settings.write(AppSettings.windowsFirewallExplained, true),
  );
}

/// N5b: Android keeps sharing running in the background behind an ongoing
/// notification; PL1: Windows behind a tray icon.
///
/// X8: both go through [backgroundPresence], which also keeps transfers and
/// local jobs alive: one service / one tray icon.
@Riverpod(keepAlive: true)
ShareBackground shareBackground(Ref ref) {
  final port = ref.watch(presencePortProvider);
  if (port is AndroidPresencePort) {
    return PresenceShareBackground(
      ref.watch(backgroundPresenceProvider),
      showOffer: port.showOffer,
      cancelOffer: port.cancelOffer,
      notificationsAllowed: port.notificationsAllowed,
    );
  }
  final shell = ref.watch(desktopShellProvider);
  if (shell != null) {
    return PresenceShareBackground(
      ref.watch(backgroundPresenceProvider),
      // N12: an incoming offer brings the window to the front.
      showOffer: (_) => shell.showAndFocus(),
      cancelOffer: () async {},
      notificationsAllowed: () async => true,
    );
  }
  return const NoShareBackground();
}

/// Every route the share server serves. N2/N3/N4/N7/N10 append theirs here.
@Riverpod(keepAlive: true)
List<ServerRoute> shareServerRoutes(Ref ref) {
  final identity = ref.watch(deviceIdentityRepositoryProvider);
  return [
    ...coreRoutes(
      info: () async {
        final id = await identity.loadOrCreate();
        return ServerInfoDto(
          deviceId: id.deviceId,
          name: id.displayName,
          platform: id.platform,
          fingerprint: id.fingerprint,
          protocolVersion: kProtocolVersion,
        );
      },
      nonces: ref.watch(pairNonceStoreProvider),
    ),
    ...pairRoutes(
      secrets: ref.watch(pairingSecretStoreProvider),
      nonces: ref.watch(pairNonceStoreProvider),
      handOff: (candidate) => ref.read(pairHandOffProvider)(candidate),
    ),
    pairCancelRoute(ref.watch(acceptGateProvider)),
    rootsRoute(ref.watch(shareScopeStoreProvider)),
    ...sessionRoutes(
      ref.watch(clientSessionStoreProvider),
      changeToken: (fp) => ref.read(shareChangeTrackerProvider).tokenFor(fp),
      // N12b: offers this device makes to that client.
      inboxToken: (fp) => ref.read(offerServiceProvider).inboxTokenFor(fp),
    ),
    ...fileRoutes(
      FileRoutesEnv(
        guard: ref.watch(allowListGuardProvider),
        scopeOf: ref.watch(shareScopeStoreProvider).scopeOf,
        sessions: ref.watch(clientSessionStoreProvider),
        source: () => ref.read(fileSourceProvider),
        dao: () => ref.read(mediaIndexDaoProvider),
        addToIndex: (files) => ref.read(mediaIndexerProvider).addFiles(files),
        canSeeAllFiles: () =>
            ref.read(storageAccessControllerProvider).value?.canSeeAllFiles ??
            false,
        thumbnails: () => ref.read(thumbnailCacheProvider.future),
        trash: () => ref.read(remoteTrashServiceProvider),
      ),
    ),
    // N9: uploads into writable shared folders.
    ...uploadRoutes(
      UploadRoutesEnv(
        guard: ref.watch(allowListGuardProvider),
        sessions: ref.watch(clientSessionStoreProvider),
        uploads: ref.watch(uploadStoreProvider),
        source: () => ref.read(fileSourceProvider),
        addToIndex: (files) => ref.read(mediaIndexerProvider).addFiles(files),
        stagingFreeBytes: () async => await ref
            .read(fileSourceProvider)
            .freeBytes((await transferStagingDir()).path),
        grants: LazyOfferGrants(() => ref.read(offerServiceProvider)),
        publishMode: (target) async => uploadPublishFor(
          (await transferStagingDir()).path,
          target,
          isAndroid: Platform.isAndroid,
          isWindows: isWindowsHost,
        ),
      ),
    ),
    // N12: send-files offers (push).
    ...offerRoutes(() => ref.read(offerServiceProvider)),
    // N12b: offers to connected clients.
    ...inboxRoutes(() => ref.read(offerServiceProvider)),
    // N6: remembered devices reconnect without a QR.
    knownPairRoute(
      nonces: ref.watch(pairNonceStoreProvider),
      limiter: ref.watch(knownPairLimiterProvider),
      serverFingerprint: () async =>
          (await identity.loadOrCreate()).fingerprint,
      lookup: (fp) =>
          ref.read(knownDevicesRepositoryProvider).byFingerprint(fp),
      handOff: (candidate) => ref.read(pairHandOffProvider)(candidate),
    ),
  ];
}

@Riverpod(keepAlive: true)
ShareServer shareServer(Ref ref) {
  final server = ShareServer(
    ref.watch(deviceIdentityRepositoryProvider),
    (served) => buildSharePipeline(
      served: served,
      routes: ref.read(shareServerRoutesProvider),
      authenticate: authenticate(ref.read(clientSessionStoreProvider)),
      // N9: chunks have their own limit (kTransferChunkBytes); N12 offer
      // bodies too (kMaxOfferBodyBytes).
      sizeLimitExempt: (r) =>
          isUploadChunkRequest(r) || isOfferCreateRequest(r),
    ),
    preferredPort: () =>
        ref.read(settingsRepositoryProvider).read(AppSettings.sharePort),
    savePort: (port) =>
        ref.read(settingsRepositoryProvider).write(AppSettings.sharePort, port),
  );
  ref.onDispose(server.stop);
  return server;
}
