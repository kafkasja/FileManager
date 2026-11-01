// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connect_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Secure storage for the device identity (TASK-N1).

@ProviderFor(secretStore)
final secretStoreProvider = SecretStoreProvider._();

/// Secure storage for the device identity (TASK-N1).

final class SecretStoreProvider
    extends $FunctionalProvider<SecretStore, SecretStore, SecretStore>
    with $Provider<SecretStore> {
  /// Secure storage for the device identity (TASK-N1).
  SecretStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'secretStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$secretStoreHash();

  @$internal
  @override
  $ProviderElement<SecretStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SecretStore create(Ref ref) {
    return secretStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SecretStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SecretStore>(value),
    );
  }
}

String _$secretStoreHash() => r'c9a67bc20d70bf1a594f67754ad376008c57c0f4';

/// The device model, the default share name. Android: maker + model;
/// elsewhere the host name.

@ProviderFor(deviceModelName)
final deviceModelNameProvider = DeviceModelNameProvider._();

/// The device model, the default share name. Android: maker + model;
/// elsewhere the host name.

final class DeviceModelNameProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// The device model, the default share name. Android: maker + model;
  /// elsewhere the host name.
  DeviceModelNameProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceModelNameProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceModelNameHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return deviceModelName(ref);
  }
}

String _$deviceModelNameHash() => r'6ca548bf3aa2e81a422f30dca3dab43ec46f47ca';

@ProviderFor(deviceIdentityRepository)
final deviceIdentityRepositoryProvider = DeviceIdentityRepositoryProvider._();

final class DeviceIdentityRepositoryProvider
    extends
        $FunctionalProvider<
          DeviceIdentityRepository,
          DeviceIdentityRepository,
          DeviceIdentityRepository
        >
    with $Provider<DeviceIdentityRepository> {
  DeviceIdentityRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceIdentityRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceIdentityRepositoryHash();

  @$internal
  @override
  $ProviderElement<DeviceIdentityRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DeviceIdentityRepository create(Ref ref) {
    return deviceIdentityRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeviceIdentityRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeviceIdentityRepository>(value),
    );
  }
}

String _$deviceIdentityRepositoryHash() =>
    r'c06998c2a378097f5aefb9fffc2e7855fecc9f5a';

/// This install's identity; generated on first use (in an isolate).

@ProviderFor(deviceIdentity)
final deviceIdentityProvider = DeviceIdentityProvider._();

/// This install's identity; generated on first use (in an isolate).

final class DeviceIdentityProvider
    extends
        $FunctionalProvider<
          AsyncValue<DeviceIdentity>,
          DeviceIdentity,
          FutureOr<DeviceIdentity>
        >
    with $FutureModifier<DeviceIdentity>, $FutureProvider<DeviceIdentity> {
  /// This install's identity; generated on first use (in an isolate).
  DeviceIdentityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceIdentityProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceIdentityHash();

  @$internal
  @override
  $FutureProviderElement<DeviceIdentity> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DeviceIdentity> create(Ref ref) {
    return deviceIdentity(ref);
  }
}

String _$deviceIdentityHash() => r'c93321a233d919d0ca6af5dfe3e9553458a90e5f';

/// Pair nonces of the current sharing run (N2, N6).

@ProviderFor(pairNonceStore)
final pairNonceStoreProvider = PairNonceStoreProvider._();

/// Pair nonces of the current sharing run (N2, N6).

final class PairNonceStoreProvider
    extends $FunctionalProvider<PairNonceStore, PairNonceStore, PairNonceStore>
    with $Provider<PairNonceStore> {
  /// Pair nonces of the current sharing run (N2, N6).
  PairNonceStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pairNonceStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pairNonceStoreHash();

  @$internal
  @override
  $ProviderElement<PairNonceStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PairNonceStore create(Ref ref) {
    return pairNonceStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PairNonceStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PairNonceStore>(value),
    );
  }
}

String _$pairNonceStoreHash() => r'2555070de6bfcb1a2fbdc4104b178958b2bd71e0';

/// Every route the share server serves. N2/N3/N4/N7/N10 append theirs here.

@ProviderFor(shareServerRoutes)
final shareServerRoutesProvider = ShareServerRoutesProvider._();

/// Every route the share server serves. N2/N3/N4/N7/N10 append theirs here.

final class ShareServerRoutesProvider
    extends
        $FunctionalProvider<
          List<ServerRoute>,
          List<ServerRoute>,
          List<ServerRoute>
        >
    with $Provider<List<ServerRoute>> {
  /// Every route the share server serves. N2/N3/N4/N7/N10 append theirs here.
  ShareServerRoutesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shareServerRoutesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shareServerRoutesHash();

  @$internal
  @override
  $ProviderElement<List<ServerRoute>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<ServerRoute> create(Ref ref) {
    return shareServerRoutes(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ServerRoute> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ServerRoute>>(value),
    );
  }
}

String _$shareServerRoutesHash() => r'babb82fee8f944364673f711a86f51279fe260e1';

@ProviderFor(shareServer)
final shareServerProvider = ShareServerProvider._();

final class ShareServerProvider
    extends $FunctionalProvider<ShareServer, ShareServer, ShareServer>
    with $Provider<ShareServer> {
  ShareServerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shareServerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shareServerHash();

  @$internal
  @override
  $ProviderElement<ShareServer> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ShareServer create(Ref ref) {
    return shareServer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShareServer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShareServer>(value),
    );
  }
}

String _$shareServerHash() => r'f1417c8b7aa7f4157e242f23e1055111c4927810';
