// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'text_scale.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// keepAlive stream like `themeModeProvider`.

@ProviderFor(textSize)
final textSizeProvider = TextSizeProvider._();

/// keepAlive stream like `themeModeProvider`.

final class TextSizeProvider
    extends
        $FunctionalProvider<
          AsyncValue<AppTextSize>,
          AppTextSize,
          Stream<AppTextSize>
        >
    with $FutureModifier<AppTextSize>, $StreamProvider<AppTextSize> {
  /// keepAlive stream like `themeModeProvider`.
  TextSizeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'textSizeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$textSizeHash();

  @$internal
  @override
  $StreamProviderElement<AppTextSize> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<AppTextSize> create(Ref ref) {
    return textSize(ref);
  }
}

String _$textSizeHash() => r'e5a969a2663def92475f3c1b1e56f781a3b1fbfb';
