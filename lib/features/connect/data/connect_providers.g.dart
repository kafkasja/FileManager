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

/// QR secret + short code of the current sharing run (N2).

@ProviderFor(pairingSecretStore)
final pairingSecretStoreProvider = PairingSecretStoreProvider._();

/// QR secret + short code of the current sharing run (N2).

final class PairingSecretStoreProvider
    extends
        $FunctionalProvider<
          PairingSecretStore,
          PairingSecretStore,
          PairingSecretStore
        >
    with $Provider<PairingSecretStore> {
  /// QR secret + short code of the current sharing run (N2).
  PairingSecretStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pairingSecretStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pairingSecretStoreHash();

  @$internal
  @override
  $ProviderElement<PairingSecretStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PairingSecretStore create(Ref ref) {
    return pairingSecretStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PairingSecretStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PairingSecretStore>(value),
    );
  }
}

String _$pairingSecretStoreHash() =>
    r'925cecd2be29d730143e563923bfb9ecebe41bd5';

/// What happens to a verified pairing request. N2 holds it and answers
/// `timed_out` (no accept prompt yet); N3 replaces this with the prompt.

@ProviderFor(pairHandOff)
final pairHandOffProvider = PairHandOffProvider._();

/// What happens to a verified pairing request. N2 holds it and answers
/// `timed_out` (no accept prompt yet); N3 replaces this with the prompt.

final class PairHandOffProvider
    extends $FunctionalProvider<PairHandOff, PairHandOff, PairHandOff>
    with $Provider<PairHandOff> {
  /// What happens to a verified pairing request. N2 holds it and answers
  /// `timed_out` (no accept prompt yet); N3 replaces this with the prompt.
  PairHandOffProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pairHandOffProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pairHandOffHash();

  @$internal
  @override
  $ProviderElement<PairHandOff> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PairHandOff create(Ref ref) {
    return pairHandOff(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PairHandOff value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PairHandOff>(value),
    );
  }
}

String _$pairHandOffHash() => r'7c76a8b4d377b2f071b7714fe4d81f428c9b7f25';

/// mDNS advertise + browse (N2).

@ProviderFor(shareDiscovery)
final shareDiscoveryProvider = ShareDiscoveryProvider._();

/// mDNS advertise + browse (N2).

final class ShareDiscoveryProvider
    extends $FunctionalProvider<ShareDiscovery, ShareDiscovery, ShareDiscovery>
    with $Provider<ShareDiscovery> {
  /// mDNS advertise + browse (N2).
  ShareDiscoveryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shareDiscoveryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shareDiscoveryHash();

  @$internal
  @override
  $ProviderElement<ShareDiscovery> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ShareDiscovery create(Ref ref) {
    return shareDiscovery(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShareDiscovery value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShareDiscovery>(value),
    );
  }
}

String _$shareDiscoveryHash() => r'06ee902ee823958346f61d79668a20d99fc69b38';

/// Nearby sharing devices while the Connect screen lists them.

@ProviderFor(nearbyDevices)
final nearbyDevicesProvider = NearbyDevicesProvider._();

/// Nearby sharing devices while the Connect screen lists them.

final class NearbyDevicesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<NearbyDevice>>,
          List<NearbyDevice>,
          Stream<List<NearbyDevice>>
        >
    with
        $FutureModifier<List<NearbyDevice>>,
        $StreamProvider<List<NearbyDevice>> {
  /// Nearby sharing devices while the Connect screen lists them.
  NearbyDevicesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nearbyDevicesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nearbyDevicesHash();

  @$internal
  @override
  $StreamProviderElement<List<NearbyDevice>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<NearbyDevice>> create(Ref ref) {
    return nearbyDevices(ref);
  }
}

String _$nearbyDevicesHash() => r'd146f1ccef04a5f40aa43eb464296eed6debe1be';

/// The connecting side of pairing (N2).

@ProviderFor(pairingClient)
final pairingClientProvider = PairingClientProvider._();

/// The connecting side of pairing (N2).

final class PairingClientProvider
    extends $FunctionalProvider<PairingClient, PairingClient, PairingClient>
    with $Provider<PairingClient> {
  /// The connecting side of pairing (N2).
  PairingClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pairingClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pairingClientHash();

  @$internal
  @override
  $ProviderElement<PairingClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PairingClient create(Ref ref) {
    return pairingClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PairingClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PairingClient>(value),
    );
  }
}

String _$pairingClientHash() => r'77f3a335daee3c3dd0a6062fc0af2364d290a790';

/// Camera permission for "Scan QR".

@ProviderFor(cameraAccess)
final cameraAccessProvider = CameraAccessProvider._();

/// Camera permission for "Scan QR".

final class CameraAccessProvider
    extends $FunctionalProvider<CameraAccess, CameraAccess, CameraAccess>
    with $Provider<CameraAccess> {
  /// Camera permission for "Scan QR".
  CameraAccessProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cameraAccessProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cameraAccessHash();

  @$internal
  @override
  $ProviderElement<CameraAccess> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CameraAccess create(Ref ref) {
    return cameraAccess(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CameraAccess value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CameraAccess>(value),
    );
  }
}

String _$cameraAccessHash() => r'e2a5b19d99a79e0546291460a0c93d9c5312f0a4';

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

String _$shareServerRoutesHash() => r'05e51149b90215ac7c5104e7543f682063998c81';

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
