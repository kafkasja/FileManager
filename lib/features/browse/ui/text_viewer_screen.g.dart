// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'text_viewer_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Reads the start of [file] (at most `kTextViewerMaxBytes`) and decodes
/// it (in an isolate unless it is small).

@ProviderFor(textPreview)
final textPreviewProvider = TextPreviewFamily._();

/// Reads the start of [file] (at most `kTextViewerMaxBytes`) and decodes
/// it (in an isolate unless it is small).

final class TextPreviewProvider
    extends
        $FunctionalProvider<
          AsyncValue<TextPreview>,
          TextPreview,
          FutureOr<TextPreview>
        >
    with $FutureModifier<TextPreview>, $FutureProvider<TextPreview> {
  /// Reads the start of [file] (at most `kTextViewerMaxBytes`) and decodes
  /// it (in an isolate unless it is small).
  TextPreviewProvider._({
    required TextPreviewFamily super.from,
    required FileRef super.argument,
  }) : super(
         retry: null,
         name: r'textPreviewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$textPreviewHash();

  @override
  String toString() {
    return r'textPreviewProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<TextPreview> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TextPreview> create(Ref ref) {
    final argument = this.argument as FileRef;
    return textPreview(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TextPreviewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$textPreviewHash() => r'88cc7da779409d5500a73e5179fe63b35b9c8346';

/// Reads the start of [file] (at most `kTextViewerMaxBytes`) and decodes
/// it (in an isolate unless it is small).

final class TextPreviewFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<TextPreview>, FileRef> {
  TextPreviewFamily._()
    : super(
        retry: null,
        name: r'textPreviewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Reads the start of [file] (at most `kTextViewerMaxBytes`) and decodes
  /// it (in an isolate unless it is small).

  TextPreviewProvider call(FileRef file) =>
      TextPreviewProvider._(argument: file, from: this);

  @override
  String toString() => r'textPreviewProvider';
}
