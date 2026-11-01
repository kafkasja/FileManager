// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'in_app_jobs.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Lives as long as the app (watched in `App.build`), so its listeners are
/// never paused.

@ProviderFor(inAppJobRunner)
final inAppJobRunnerProvider = InAppJobRunnerProvider._();

/// Lives as long as the app (watched in `App.build`), so its listeners are
/// never paused.

final class InAppJobRunnerProvider
    extends $FunctionalProvider<InAppJobRunner, InAppJobRunner, InAppJobRunner>
    with $Provider<InAppJobRunner> {
  /// Lives as long as the app (watched in `App.build`), so its listeners are
  /// never paused.
  InAppJobRunnerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inAppJobRunnerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inAppJobRunnerHash();

  @$internal
  @override
  $ProviderElement<InAppJobRunner> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  InAppJobRunner create(Ref ref) {
    return inAppJobRunner(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InAppJobRunner value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InAppJobRunner>(value),
    );
  }
}

String _$inAppJobRunnerHash() => r'592b2d342edee497b5b0c3b482ead39d92a32613';
