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

/// Every favorite file id (B9: ♡ state in the preview and ⋮ menu).

@ProviderFor(favoriteIds)
final favoriteIdsProvider = FavoriteIdsProvider._();

/// Every favorite file id (B9: ♡ state in the preview and ⋮ menu).

final class FavoriteIdsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Set<String>>,
          Set<String>,
          Stream<Set<String>>
        >
    with $FutureModifier<Set<String>>, $StreamProvider<Set<String>> {
  /// Every favorite file id (B9: ♡ state in the preview and ⋮ menu).
  FavoriteIdsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoriteIdsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoriteIdsHash();

  @$internal
  @override
  $StreamProviderElement<Set<String>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Set<String>> create(Ref ref) {
    return favoriteIds(ref);
  }
}

String _$favoriteIdsHash() => r'6afba2752b107841be6eb54484bd9ac8ede430ee';

/// B9: one file's tag ids, live (the Tags sheet).

@ProviderFor(fileTagIds)
final fileTagIdsProvider = FileTagIdsFamily._();

/// B9: one file's tag ids, live (the Tags sheet).

final class FileTagIdsProvider
    extends
        $FunctionalProvider<AsyncValue<Set<int>>, Set<int>, Stream<Set<int>>>
    with $FutureModifier<Set<int>>, $StreamProvider<Set<int>> {
  /// B9: one file's tag ids, live (the Tags sheet).
  FileTagIdsProvider._({
    required FileTagIdsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'fileTagIdsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fileTagIdsHash();

  @override
  String toString() {
    return r'fileTagIdsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Set<int>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Set<int>> create(Ref ref) {
    final argument = this.argument as String;
    return fileTagIds(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FileTagIdsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fileTagIdsHash() => r'867043a4df8bf17dc69723ccfe1753fe7adb1148';

/// B9: one file's tag ids, live (the Tags sheet).

final class FileTagIdsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Set<int>>, String> {
  FileTagIdsFamily._()
    : super(
        retry: null,
        name: r'fileTagIdsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// B9: one file's tag ids, live (the Tags sheet).

  FileTagIdsProvider call(String fileId) =>
      FileTagIdsProvider._(argument: fileId, from: this);

  @override
  String toString() => r'fileTagIdsProvider';
}

/// B9: visible files per tag (what each tag's view would show).

@ProviderFor(tagCounts)
final tagCountsProvider = TagCountsProvider._();

/// B9: visible files per tag (what each tag's view would show).

final class TagCountsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<int, int>>,
          Map<int, int>,
          Stream<Map<int, int>>
        >
    with $FutureModifier<Map<int, int>>, $StreamProvider<Map<int, int>> {
  /// B9: visible files per tag (what each tag's view would show).
  TagCountsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tagCountsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tagCountsHash();

  @$internal
  @override
  $StreamProviderElement<Map<int, int>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<Map<int, int>> create(Ref ref) {
    return tagCounts(ref);
  }
}

String _$tagCountsHash() => r'e7de8e6989aeea0dfe522a08bd1e110f9fa6854d';

/// B9: up to 4 newest visible favorites (the Favorites card).

@ProviderFor(favoriteThumbs)
final favoriteThumbsProvider = FavoriteThumbsProvider._();

/// B9: up to 4 newest visible favorites (the Favorites card).

final class FavoriteThumbsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<FileRef>>,
          List<FileRef>,
          FutureOr<List<FileRef>>
        >
    with $FutureModifier<List<FileRef>>, $FutureProvider<List<FileRef>> {
  /// B9: up to 4 newest visible favorites (the Favorites card).
  FavoriteThumbsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'favoriteThumbsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$favoriteThumbsHash();

  @$internal
  @override
  $FutureProviderElement<List<FileRef>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<FileRef>> create(Ref ref) {
    return favoriteThumbs(ref);
  }
}

String _$favoriteThumbsHash() => r'b463b02f514111c623cef7709eae496746089969';
