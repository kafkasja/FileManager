// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'known_devices_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Reconnect to remembered devices (TASK-N6); N9/N10 call `reconnect`.

@ProviderFor(knownDeviceConnector)
final knownDeviceConnectorProvider = KnownDeviceConnectorProvider._();

/// Reconnect to remembered devices (TASK-N6); N9/N10 call `reconnect`.

final class KnownDeviceConnectorProvider
    extends
        $FunctionalProvider<
          KnownDeviceConnector,
          KnownDeviceConnector,
          KnownDeviceConnector
        >
    with $Provider<KnownDeviceConnector> {
  /// Reconnect to remembered devices (TASK-N6); N9/N10 call `reconnect`.
  KnownDeviceConnectorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'knownDeviceConnectorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$knownDeviceConnectorHash();

  @$internal
  @override
  $ProviderElement<KnownDeviceConnector> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  KnownDeviceConnector create(Ref ref) {
    return knownDeviceConnector(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KnownDeviceConnector value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KnownDeviceConnector>(value),
    );
  }
}

String _$knownDeviceConnectorHash() =>
    r'8a4742a31e4f531b8119d4ecb9d356890dd8b9a3';

/// Remove / Remove all / Reset this device's identity (TASK-N6).

@ProviderFor(rememberedDevicesService)
final rememberedDevicesServiceProvider = RememberedDevicesServiceProvider._();

/// Remove / Remove all / Reset this device's identity (TASK-N6).

final class RememberedDevicesServiceProvider
    extends
        $FunctionalProvider<
          RememberedDevicesService,
          RememberedDevicesService,
          RememberedDevicesService
        >
    with $Provider<RememberedDevicesService> {
  /// Remove / Remove all / Reset this device's identity (TASK-N6).
  RememberedDevicesServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'rememberedDevicesServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$rememberedDevicesServiceHash();

  @$internal
  @override
  $ProviderElement<RememberedDevicesService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RememberedDevicesService create(Ref ref) {
    return rememberedDevicesService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RememberedDevicesService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RememberedDevicesService>(value),
    );
  }
}

String _$rememberedDevicesServiceHash() =>
    r'7d9e2b9218ba1023cf03ea8fc76535cd32a5bd87';
