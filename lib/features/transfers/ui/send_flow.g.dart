// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'send_flow.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PendingSend)
final pendingSendProvider = PendingSendProvider._();

final class PendingSendProvider
    extends $NotifierProvider<PendingSend, PendingSendFiles?> {
  PendingSendProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingSendProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingSendHash();

  @$internal
  @override
  PendingSend create() => PendingSend();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PendingSendFiles? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PendingSendFiles?>(value),
    );
  }
}

String _$pendingSendHash() => r'977fc9efdac5dc9de9958f1f7aeb26a544e04574';

abstract class _$PendingSend extends $Notifier<PendingSendFiles?> {
  PendingSendFiles? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PendingSendFiles?, PendingSendFiles?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PendingSendFiles?, PendingSendFiles?>,
              PendingSendFiles?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
