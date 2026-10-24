// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'limited_access_banner.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Dismissed for the rest of this app run.

@ProviderFor(LimitedBannerDismissed)
final limitedBannerDismissedProvider = LimitedBannerDismissedProvider._();

/// Dismissed for the rest of this app run.
final class LimitedBannerDismissedProvider
    extends $NotifierProvider<LimitedBannerDismissed, bool> {
  /// Dismissed for the rest of this app run.
  LimitedBannerDismissedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'limitedBannerDismissedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$limitedBannerDismissedHash();

  @$internal
  @override
  LimitedBannerDismissed create() => LimitedBannerDismissed();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$limitedBannerDismissedHash() =>
    r'be1981a752d915500eaf308c0c732fd6acea2450';

/// Dismissed for the rest of this app run.

abstract class _$LimitedBannerDismissed extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
