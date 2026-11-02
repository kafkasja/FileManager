// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'handed.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// keepAlive stream like `themeModeProvider`.

@ProviderFor(handedness)
final handednessProvider = HandednessProvider._();

/// keepAlive stream like `themeModeProvider`.

final class HandednessProvider
    extends
        $FunctionalProvider<
          AsyncValue<Handedness>,
          Handedness,
          Stream<Handedness>
        >
    with $FutureModifier<Handedness>, $StreamProvider<Handedness> {
  /// keepAlive stream like `themeModeProvider`.
  HandednessProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'handednessProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$handednessHash();

  @$internal
  @override
  $StreamProviderElement<Handedness> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Handedness> create(Ref ref) {
    return handedness(ref);
  }
}

String _$handednessHash() => r'30bfffb4091f4a51b437518cdff6dd6dcbb2abd1';
