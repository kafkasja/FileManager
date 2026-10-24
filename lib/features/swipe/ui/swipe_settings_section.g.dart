// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'swipe_settings_section.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Vibration on swipes (S4), cached so a swipe never waits for the DB.

@ProviderFor(hapticsEnabled)
final hapticsEnabledProvider = HapticsEnabledProvider._();

/// Vibration on swipes (S4), cached so a swipe never waits for the DB.

final class HapticsEnabledProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// Vibration on swipes (S4), cached so a swipe never waits for the DB.
  HapticsEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hapticsEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hapticsEnabledHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return hapticsEnabled(ref);
  }
}

String _$hapticsEnabledHash() => r'0c7e9b57a010e28a2458ddfe19d46a0f61c8ac02';

/// P7: the "Reviewed" badge on swipe cards.

@ProviderFor(showReviewedBadge)
final showReviewedBadgeProvider = ShowReviewedBadgeProvider._();

/// P7: the "Reviewed" badge on swipe cards.

final class ShowReviewedBadgeProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// P7: the "Reviewed" badge on swipe cards.
  ShowReviewedBadgeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'showReviewedBadgeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$showReviewedBadgeHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return showReviewedBadge(ref);
  }
}

String _$showReviewedBadgeHash() => r'ec4572e67a27ca1523d0a6a0bb280661d31f4f2a';

/// P9: buttons under the card instead of (or next to) swiping.

@ProviderFor(swipeButtonsMode)
final swipeButtonsModeProvider = SwipeButtonsModeProvider._();

/// P9: buttons under the card instead of (or next to) swiping.

final class SwipeButtonsModeProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// P9: buttons under the card instead of (or next to) swiping.
  SwipeButtonsModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'swipeButtonsModeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$swipeButtonsModeHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return swipeButtonsMode(ref);
  }
}

String _$swipeButtonsModeHash() => r'7b43f5f620763bba8073fc27e4c44bf798e583db';

/// P8: summary sheet after Done.

@ProviderFor(sessionSummaryEnabled)
final sessionSummaryEnabledProvider = SessionSummaryEnabledProvider._();

/// P8: summary sheet after Done.

final class SessionSummaryEnabledProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// P8: summary sheet after Done.
  SessionSummaryEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionSummaryEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionSummaryEnabledHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return sessionSummaryEnabled(ref);
  }
}

String _$sessionSummaryEnabledHash() =>
    r'7dc25b89b860fae26675a487de7b19d183be2170';

/// P4: the optional action bar under the card.

@ProviderFor(actionBarEnabled)
final actionBarEnabledProvider = ActionBarEnabledProvider._();

/// P4: the optional action bar under the card.

final class ActionBarEnabledProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// P4: the optional action bar under the card.
  ActionBarEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'actionBarEnabledProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$actionBarEnabledHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return actionBarEnabled(ref);
  }
}

String _$actionBarEnabledHash() => r'a30d2331bc938180a971d9e865e96a46580adb2f';
