// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folders_settings_section.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// What dropping dragged files on a folder does (B4).

@ProviderFor(foldersDropAction)
final foldersDropActionProvider = FoldersDropActionProvider._();

/// What dropping dragged files on a folder does (B4).

final class FoldersDropActionProvider
    extends
        $FunctionalProvider<
          AsyncValue<DropAction>,
          DropAction,
          Stream<DropAction>
        >
    with $FutureModifier<DropAction>, $StreamProvider<DropAction> {
  /// What dropping dragged files on a folder does (B4).
  FoldersDropActionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'foldersDropActionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$foldersDropActionHash();

  @$internal
  @override
  $StreamProviderElement<DropAction> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<DropAction> create(Ref ref) {
    return foldersDropAction(ref);
  }
}

String _$foldersDropActionHash() => r'f40a7431bee68fb1c23ae787a1c0f68ac384d46a';
