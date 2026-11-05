// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'swipe_folder_line.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// E4: "Show the file's folder" on the swipe card (default on).

@ProviderFor(swipeShowFolder)
final swipeShowFolderProvider = SwipeShowFolderProvider._();

/// E4: "Show the file's folder" on the swipe card (default on).

final class SwipeShowFolderProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// E4: "Show the file's folder" on the swipe card (default on).
  SwipeShowFolderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'swipeShowFolderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$swipeShowFolderHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return swipeShowFolder(ref);
  }
}

String _$swipeShowFolderHash() => r'e3286fb4209975507d907eb88cf2cf97c52a5b5f';
