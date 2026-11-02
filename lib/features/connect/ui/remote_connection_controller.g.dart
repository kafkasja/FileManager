// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remote_connection_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the controller follows the app lifecycle itself (a binding is
/// needed); unit tests turn it off and call `onLifecycle`.

@ProviderFor(remoteFollowsAppLifecycle)
final remoteFollowsAppLifecycleProvider = RemoteFollowsAppLifecycleProvider._();

/// Whether the controller follows the app lifecycle itself (a binding is
/// needed); unit tests turn it off and call `onLifecycle`.

final class RemoteFollowsAppLifecycleProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether the controller follows the app lifecycle itself (a binding is
  /// needed); unit tests turn it off and call `onLifecycle`.
  RemoteFollowsAppLifecycleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'remoteFollowsAppLifecycleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$remoteFollowsAppLifecycleHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return remoteFollowsAppLifecycle(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$remoteFollowsAppLifecycleHash() =>
    r'757248d63fe5be849ebdc29e869d08316dbd7e41';

/// Thumbnails of the connected device's files (N5): memory only, cleared
/// on every disconnect.

@ProviderFor(remoteThumbnailCache)
final remoteThumbnailCacheProvider = RemoteThumbnailCacheProvider._();

/// Thumbnails of the connected device's files (N5): memory only, cleared
/// on every disconnect.

final class RemoteThumbnailCacheProvider
    extends
        $FunctionalProvider<
          RemoteThumbnailCache,
          RemoteThumbnailCache,
          RemoteThumbnailCache
        >
    with $Provider<RemoteThumbnailCache> {
  /// Thumbnails of the connected device's files (N5): memory only, cleared
  /// on every disconnect.
  RemoteThumbnailCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'remoteThumbnailCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$remoteThumbnailCacheHash();

  @$internal
  @override
  $ProviderElement<RemoteThumbnailCache> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RemoteThumbnailCache create(Ref ref) {
    return remoteThumbnailCache(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RemoteThumbnailCache value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RemoteThumbnailCache>(value),
    );
  }
}

String _$remoteThumbnailCacheHash() =>
    r'05ab75fdc3207259a55f9413158c92c55afd5b32';

/// TASK-N7 live sync: the latest change token of the connected device's
/// shared roots, from the heartbeat (`GET /v1/session` → `SessionDto`).
/// Null while not connected or when the other device sends none (older
/// version, 204). Remote browse screens refresh when it changes.

@ProviderFor(RemoteChangeToken)
final remoteChangeTokenProvider = RemoteChangeTokenProvider._();

/// TASK-N7 live sync: the latest change token of the connected device's
/// shared roots, from the heartbeat (`GET /v1/session` → `SessionDto`).
/// Null while not connected or when the other device sends none (older
/// version, 204). Remote browse screens refresh when it changes.
final class RemoteChangeTokenProvider
    extends $NotifierProvider<RemoteChangeToken, String?> {
  /// TASK-N7 live sync: the latest change token of the connected device's
  /// shared roots, from the heartbeat (`GET /v1/session` → `SessionDto`).
  /// Null while not connected or when the other device sends none (older
  /// version, 204). Remote browse screens refresh when it changes.
  RemoteChangeTokenProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'remoteChangeTokenProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$remoteChangeTokenHash();

  @$internal
  @override
  RemoteChangeToken create() => RemoteChangeToken();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$remoteChangeTokenHash() => r'101b491d5aec87516d276be778b91d4d69cb7c49';

/// TASK-N7 live sync: the latest change token of the connected device's
/// shared roots, from the heartbeat (`GET /v1/session` → `SessionDto`).
/// Null while not connected or when the other device sends none (older
/// version, 204). Remote browse screens refresh when it changes.

abstract class _$RemoteChangeToken extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// TASK-N12b: pending offers the connected (sharing) device makes to us,
/// read when the heartbeat's `inboxToken` changes. Empty while not
/// connected.

@ProviderFor(RemoteInbox)
final remoteInboxProvider = RemoteInboxProvider._();

/// TASK-N12b: pending offers the connected (sharing) device makes to us,
/// read when the heartbeat's `inboxToken` changes. Empty while not
/// connected.
final class RemoteInboxProvider
    extends $NotifierProvider<RemoteInbox, List<OfferDto>> {
  /// TASK-N12b: pending offers the connected (sharing) device makes to us,
  /// read when the heartbeat's `inboxToken` changes. Empty while not
  /// connected.
  RemoteInboxProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'remoteInboxProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$remoteInboxHash();

  @$internal
  @override
  RemoteInbox create() => RemoteInbox();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<OfferDto> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<OfferDto>>(value),
    );
  }
}

String _$remoteInboxHash() => r'35f0885b856f0482191673ef82e866189d576a8b';

/// TASK-N12b: pending offers the connected (sharing) device makes to us,
/// read when the heartbeat's `inboxToken` changes. Empty while not
/// connected.

abstract class _$RemoteInbox extends $Notifier<List<OfferDto>> {
  List<OfferDto> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<OfferDto>, List<OfferDto>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<OfferDto>, List<OfferDto>>,
              List<OfferDto>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The connection of this device to a sharing device (TASK-N5). Owns the
/// pinned client after pairing, so it outlives the Connect screen; N7's
/// remote browsing uses [http]. A 5 s `GET /v1/session` heartbeat runs in
/// the foreground: 401 → unauthorized, refused → the other device stopped,
/// 3 failed ticks (each retried once at once) → network lost. Every end
/// drops the token and closes the client.

@ProviderFor(RemoteConnectionController)
final remoteConnectionControllerProvider =
    RemoteConnectionControllerProvider._();

/// The connection of this device to a sharing device (TASK-N5). Owns the
/// pinned client after pairing, so it outlives the Connect screen; N7's
/// remote browsing uses [http]. A 5 s `GET /v1/session` heartbeat runs in
/// the foreground: 401 → unauthorized, refused → the other device stopped,
/// 3 failed ticks (each retried once at once) → network lost. Every end
/// drops the token and closes the client.
final class RemoteConnectionControllerProvider
    extends
        $NotifierProvider<RemoteConnectionController, RemoteConnectionState> {
  /// The connection of this device to a sharing device (TASK-N5). Owns the
  /// pinned client after pairing, so it outlives the Connect screen; N7's
  /// remote browsing uses [http]. A 5 s `GET /v1/session` heartbeat runs in
  /// the foreground: 401 → unauthorized, refused → the other device stopped,
  /// 3 failed ticks (each retried once at once) → network lost. Every end
  /// drops the token and closes the client.
  RemoteConnectionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'remoteConnectionControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$remoteConnectionControllerHash();

  @$internal
  @override
  RemoteConnectionController create() => RemoteConnectionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RemoteConnectionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RemoteConnectionState>(value),
    );
  }
}

String _$remoteConnectionControllerHash() =>
    r'548abf53c30ddde6e7473403e01697ff4154d429';

/// The connection of this device to a sharing device (TASK-N5). Owns the
/// pinned client after pairing, so it outlives the Connect screen; N7's
/// remote browsing uses [http]. A 5 s `GET /v1/session` heartbeat runs in
/// the foreground: 401 → unauthorized, refused → the other device stopped,
/// 3 failed ticks (each retried once at once) → network lost. Every end
/// drops the token and closes the client.

abstract class _$RemoteConnectionController
    extends $Notifier<RemoteConnectionState> {
  RemoteConnectionState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RemoteConnectionState, RemoteConnectionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RemoteConnectionState, RemoteConnectionState>,
              RemoteConnectionState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
