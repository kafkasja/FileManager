// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'form_factor.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The one switch between the phone and the desktop UI. `desktop` on
/// Windows (and later macOS/Linux) hosts, `mobile` everywhere else. Tests
/// override it (the test config runs the app as Android on any host).

@ProviderFor(formFactor)
final formFactorProvider = FormFactorProvider._();

/// The one switch between the phone and the desktop UI. `desktop` on
/// Windows (and later macOS/Linux) hosts, `mobile` everywhere else. Tests
/// override it (the test config runs the app as Android on any host).

final class FormFactorProvider
    extends $FunctionalProvider<FormFactor, FormFactor, FormFactor>
    with $Provider<FormFactor> {
  /// The one switch between the phone and the desktop UI. `desktop` on
  /// Windows (and later macOS/Linux) hosts, `mobile` everywhere else. Tests
  /// override it (the test config runs the app as Android on any host).
  FormFactorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'formFactorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$formFactorHash();

  @$internal
  @override
  $ProviderElement<FormFactor> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FormFactor create(Ref ref) {
    return formFactor(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FormFactor value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FormFactor>(value),
    );
  }
}

String _$formFactorHash() => r'1b0d570bb507078050e7d090113b960eb3ef6d06';
