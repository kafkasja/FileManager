// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'background_scheduler.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Null off Android (no job needed); `main.dart` overrides it on Android.
/// Tests override with a fake.

@ProviderFor(backgroundScheduler)
final backgroundSchedulerProvider = BackgroundSchedulerProvider._();

/// Null off Android (no job needed); `main.dart` overrides it on Android.
/// Tests override with a fake.

final class BackgroundSchedulerProvider
    extends
        $FunctionalProvider<
          BackgroundScheduler?,
          BackgroundScheduler?,
          BackgroundScheduler?
        >
    with $Provider<BackgroundScheduler?> {
  /// Null off Android (no job needed); `main.dart` overrides it on Android.
  /// Tests override with a fake.
  BackgroundSchedulerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backgroundSchedulerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backgroundSchedulerHash();

  @$internal
  @override
  $ProviderElement<BackgroundScheduler?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BackgroundScheduler? create(Ref ref) {
    return backgroundScheduler(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackgroundScheduler? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackgroundScheduler?>(value),
    );
  }
}

String _$backgroundSchedulerHash() =>
    r'3d96872e003d46df8abc4493b3052a80632f2977';
