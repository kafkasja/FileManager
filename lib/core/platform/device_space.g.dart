// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_space.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(deviceSpaceSource)
final deviceSpaceSourceProvider = DeviceSpaceSourceProvider._();

final class DeviceSpaceSourceProvider
    extends
        $FunctionalProvider<
          DeviceSpaceSource,
          DeviceSpaceSource,
          DeviceSpaceSource
        >
    with $Provider<DeviceSpaceSource> {
  DeviceSpaceSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deviceSpaceSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deviceSpaceSourceHash();

  @$internal
  @override
  $ProviderElement<DeviceSpaceSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DeviceSpaceSource create(Ref ref) {
    return deviceSpaceSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeviceSpaceSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeviceSpaceSource>(value),
    );
  }
}

String _$deviceSpaceSourceHash() => r'268e65571b27463da227bd5894d29c193e32a2e8';
