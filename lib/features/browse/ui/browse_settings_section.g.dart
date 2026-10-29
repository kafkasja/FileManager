// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'browse_settings_section.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// A size label on every photo/video tile in Browse.

@ProviderFor(browseShowSizes)
final browseShowSizesProvider = BrowseShowSizesProvider._();

/// A size label on every photo/video tile in Browse.

final class BrowseShowSizesProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// A size label on every photo/video tile in Browse.
  BrowseShowSizesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'browseShowSizesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$browseShowSizesHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return browseShowSizes(ref);
  }
}

String _$browseShowSizesHash() => r'dfe9fe21d5ef99a09e34ce6ff78a256b70cec39d';

/// Big files (`FileGridTile.bigFileBytes`, 100 MB+) get a colored size
/// label.

@ProviderFor(browseHighlightBig)
final browseHighlightBigProvider = BrowseHighlightBigProvider._();

/// Big files (`FileGridTile.bigFileBytes`, 100 MB+) get a colored size
/// label.

final class BrowseHighlightBigProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// Big files (`FileGridTile.bigFileBytes`, 100 MB+) get a colored size
  /// label.
  BrowseHighlightBigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'browseHighlightBigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$browseHighlightBigHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return browseHighlightBig(ref);
  }
}

String _$browseHighlightBigHash() =>
    r'a1cd2d06e7ce664b392cf812b6f8553df4732f5f';
