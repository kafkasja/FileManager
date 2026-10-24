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
