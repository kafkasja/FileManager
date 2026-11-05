// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'link_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The linked device (TASK-E1), or null: this device's connection to a
/// peer (not send-only) and/or a peer connected to this device's server.
/// The connection wins when both exist for different peers (one link at a
/// time, `RemoteConnectionController` is single-peer).

@ProviderFor(currentLink)
final currentLinkProvider = CurrentLinkProvider._();

/// The linked device (TASK-E1), or null: this device's connection to a
/// peer (not send-only) and/or a peer connected to this device's server.
/// The connection wins when both exist for different peers (one link at a
/// time, `RemoteConnectionController` is single-peer).

final class CurrentLinkProvider
    extends $FunctionalProvider<DeviceLink?, DeviceLink?, DeviceLink?>
    with $Provider<DeviceLink?> {
  /// The linked device (TASK-E1), or null: this device's connection to a
  /// peer (not send-only) and/or a peer connected to this device's server.
  /// The connection wins when both exist for different peers (one link at a
  /// time, `RemoteConnectionController` is single-peer).
  CurrentLinkProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentLinkProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentLinkHash();

  @$internal
  @override
  $ProviderElement<DeviceLink?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DeviceLink? create(Ref ref) {
    return currentLink(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeviceLink? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeviceLink?>(value),
    );
  }
}

String _$currentLinkHash() => r'a834c0480fcac1a29b3c98cef26aeecb90b4dd83';

/// The Devices rows (desktop nav pane): the linked device first, then the
/// remembered devices (temporary rows hidden) with their status.

@ProviderFor(deviceRows)
final deviceRowsProvider = DeviceRowsProvider._();

/// The Devices rows (desktop nav pane): the linked device first, then the
/// remembered devices (temporary rows hidden) with their status.

final class DeviceRowsProvider
    extends
        $FunctionalProvider<List<DeviceRow>, List<DeviceRow>, List<DeviceRow>>
    with $Provider<List<DeviceRow>> {
  /// The Devices rows (desktop nav pane): the linked device first, then the
  /// remembered devices (temporary rows hidden) with their status.
  DeviceRowsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceRowsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceRowsHash();

  @$internal
  @override
  $ProviderElement<List<DeviceRow>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<DeviceRow> create(Ref ref) {
    return deviceRows(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<DeviceRow> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<DeviceRow>>(value),
    );
  }
}

String _$deviceRowsHash() => r'13b260d124beb5afef8727435765859ca76aa575';
