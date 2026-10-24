// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(tagRepository)
final tagRepositoryProvider = TagRepositoryProvider._();

final class TagRepositoryProvider
    extends $FunctionalProvider<TagRepository, TagRepository, TagRepository>
    with $Provider<TagRepository> {
  TagRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tagRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tagRepositoryHash();

  @$internal
  @override
  $ProviderElement<TagRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TagRepository create(Ref ref) {
    return tagRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TagRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TagRepository>(value),
    );
  }
}

String _$tagRepositoryHash() => r'5b46df521e48e8d1d005d0c1a65954f04c715a64';

@ProviderFor(favoritesRepository)
final favoritesRepositoryProvider = FavoritesRepositoryProvider._();

final class FavoritesRepositoryProvider
    extends
        $FunctionalProvider<
          FavoritesRepository,
          FavoritesRepository,
          FavoritesRepository
        >
    with $Provider<FavoritesRepository> {
  FavoritesRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoritesRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoritesRepositoryHash();

  @$internal
  @override
  $ProviderElement<FavoritesRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FavoritesRepository create(Ref ref) {
    return favoritesRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FavoritesRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FavoritesRepository>(value),
    );
  }
}

String _$favoritesRepositoryHash() =>
    r'8e892e26840561c480a261d3806785bd62eebf9d';

/// All tags by id, kept loaded so the swipe path reads them synchronously.

@ProviderFor(tagsById)
final tagsByIdProvider = TagsByIdProvider._();

/// All tags by id, kept loaded so the swipe path reads them synchronously.

final class TagsByIdProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<int, Tag>>,
          Map<int, Tag>,
          Stream<Map<int, Tag>>
        >
    with $FutureModifier<Map<int, Tag>>, $StreamProvider<Map<int, Tag>> {
  /// All tags by id, kept loaded so the swipe path reads them synchronously.
  TagsByIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tagsByIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tagsByIdHash();

  @$internal
  @override
  $StreamProviderElement<Map<int, Tag>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<int, Tag>> create(Ref ref) {
    return tagsById(ref);
  }
}

String _$tagsByIdHash() => r'7410b8316236af6a52c61698972e84ceb68b23d9';

/// Lives for the app's lifetime (watched in `App`).

@ProviderFor(fileIdRekeyer)
final fileIdRekeyerProvider = FileIdRekeyerProvider._();

/// Lives for the app's lifetime (watched in `App`).

final class FileIdRekeyerProvider
    extends $FunctionalProvider<FileIdRekeyer, FileIdRekeyer, FileIdRekeyer>
    with $Provider<FileIdRekeyer> {
  /// Lives for the app's lifetime (watched in `App`).
  FileIdRekeyerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fileIdRekeyerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fileIdRekeyerHash();

  @$internal
  @override
  $ProviderElement<FileIdRekeyer> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FileIdRekeyer create(Ref ref) {
    return fileIdRekeyer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FileIdRekeyer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FileIdRekeyer>(value),
    );
  }
}

String _$fileIdRekeyerHash() => r'aad83444832102c6160ebc0f23fbd4d6f08cb316';
