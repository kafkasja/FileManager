// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connect_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ConnectController)
final connectControllerProvider = ConnectControllerProvider._();

final class ConnectControllerProvider
    extends $NotifierProvider<ConnectController, ConnectState> {
  ConnectControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'connectControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$connectControllerHash();

  @$internal
  @override
  ConnectController create() => ConnectController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConnectState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConnectState>(value),
    );
  }
}

String _$connectControllerHash() => r'c7d9029a22b84137a483b72d74479a2cece60045';

abstract class _$ConnectController extends $Notifier<ConnectState> {
  ConnectState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ConnectState, ConnectState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ConnectState, ConnectState>,
              ConnectState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
