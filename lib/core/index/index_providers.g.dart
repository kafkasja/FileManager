// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'index_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(mediaIndexDao)
final mediaIndexDaoProvider = MediaIndexDaoProvider._();

final class MediaIndexDaoProvider
    extends $FunctionalProvider<MediaIndexDao, MediaIndexDao, MediaIndexDao>
    with $Provider<MediaIndexDao> {
  MediaIndexDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mediaIndexDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mediaIndexDaoHash();

  @$internal
  @override
  $ProviderElement<MediaIndexDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MediaIndexDao create(Ref ref) {
    return mediaIndexDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MediaIndexDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MediaIndexDao>(value),
    );
  }
}

String _$mediaIndexDaoHash() => r'a7e2075c534433612a7d3232400a34a91853d778';

/// Live MediaStore changes. Empty off Android and in tests.

@ProviderFor(mediaChanges)
final mediaChangesProvider = MediaChangesProvider._();

/// Live MediaStore changes. Empty off Android and in tests.

final class MediaChangesProvider
    extends
        $FunctionalProvider<
          Raw<Stream<MediaChange>>,
          Raw<Stream<MediaChange>>,
          Raw<Stream<MediaChange>>
        >
    with $Provider<Raw<Stream<MediaChange>>> {
  /// Live MediaStore changes. Empty off Android and in tests.
  MediaChangesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mediaChangesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mediaChangesHash();

  @$internal
  @override
  $ProviderElement<Raw<Stream<MediaChange>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Raw<Stream<MediaChange>> create(Ref ref) {
    return mediaChanges(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Raw<Stream<MediaChange>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Raw<Stream<MediaChange>>>(value),
    );
  }
}

String _$mediaChangesHash() => r'6f8f54411417c497e04da28059c176be279239f4';

/// Starts once storage access allows it (and rescans when it widens). The shell reads it so it exists for the app's lifetime.

@ProviderFor(mediaIndexer)
final mediaIndexerProvider = MediaIndexerProvider._();

/// Starts once storage access allows it (and rescans when it widens). The shell reads it so it exists for the app's lifetime.

final class MediaIndexerProvider
    extends $FunctionalProvider<MediaIndexer, MediaIndexer, MediaIndexer>
    with $Provider<MediaIndexer> {
  /// Starts once storage access allows it (and rescans when it widens). The shell reads it so it exists for the app's lifetime.
  MediaIndexerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mediaIndexerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mediaIndexerHash();

  @$internal
  @override
  $ProviderElement<MediaIndexer> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MediaIndexer create(Ref ref) {
    return mediaIndexer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MediaIndexer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MediaIndexer>(value),
    );
  }
}

String _$mediaIndexerHash() => r'ad2b6103602f02685c4e6fc33a3dd87c6b4fc37c';

@ProviderFor(indexStatus)
final indexStatusProvider = IndexStatusProvider._();

final class IndexStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<IndexStatus>,
          IndexStatus,
          Stream<IndexStatus>
        >
    with $FutureModifier<IndexStatus>, $StreamProvider<IndexStatus> {
  IndexStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'indexStatusProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$indexStatusHash();

  @$internal
  @override
  $StreamProviderElement<IndexStatus> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<IndexStatus> create(Ref ref) {
    return indexStatus(ref);
  }
}

String _$indexStatusHash() => r'85c07371b2ff93f8d435e69a1629284693c628d2';

/// One page of a view. Non-media is hidden while All files access is off
/// (the rows stay in the index). Views refresh on `mediaIndexChanges`.

@ProviderFor(indexPage)
final indexPageProvider = IndexPageFamily._();

/// One page of a view. Non-media is hidden while All files access is off
/// (the rows stay in the index). Views refresh on `mediaIndexChanges`.

final class IndexPageProvider
    extends
        $FunctionalProvider<
          AsyncValue<IndexPage>,
          IndexPage,
          FutureOr<IndexPage>
        >
    with $FutureModifier<IndexPage>, $FutureProvider<IndexPage> {
  /// One page of a view. Non-media is hidden while All files access is off
  /// (the rows stay in the index). Views refresh on `mediaIndexChanges`.
  IndexPageProvider._({
    required IndexPageFamily super.from,
    required (IndexQuery, {IndexCursor? after}) super.argument,
  }) : super(
         retry: null,
         name: r'indexPageProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$indexPageHash();

  @override
  String toString() {
    return r'indexPageProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<IndexPage> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<IndexPage> create(Ref ref) {
    final argument = this.argument as (IndexQuery, {IndexCursor? after});
    return indexPage(ref, argument.$1, after: argument.after);
  }

  @override
  bool operator ==(Object other) {
    return other is IndexPageProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$indexPageHash() => r'815c9b2150f5254986a717a7332a6115a171a00f';

/// One page of a view. Non-media is hidden while All files access is off
/// (the rows stay in the index). Views refresh on `mediaIndexChanges`.

final class IndexPageFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<IndexPage>,
          (IndexQuery, {IndexCursor? after})
        > {
  IndexPageFamily._()
    : super(
        retry: null,
        name: r'indexPageProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One page of a view. Non-media is hidden while All files access is off
  /// (the rows stay in the index). Views refresh on `mediaIndexChanges`.

  IndexPageProvider call(IndexQuery query, {IndexCursor? after}) =>
      IndexPageProvider._(argument: (query, after: after), from: this);

  @override
  String toString() => r'indexPageProvider';
}

/// Ticks (debounced) whenever the index changes.

@ProviderFor(mediaIndexChanges)
final mediaIndexChangesProvider = MediaIndexChangesProvider._();

/// Ticks (debounced) whenever the index changes.

final class MediaIndexChangesProvider
    extends $FunctionalProvider<AsyncValue<void>, void, Stream<void>>
    with $FutureModifier<void>, $StreamProvider<void> {
  /// Ticks (debounced) whenever the index changes.
  MediaIndexChangesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mediaIndexChangesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mediaIndexChangesHash();

  @$internal
  @override
  $StreamProviderElement<void> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<void> create(Ref ref) {
    return mediaIndexChanges(ref);
  }
}

String _$mediaIndexChangesHash() => r'9352106200798feb11189bccc6903e1e837ff799';

@ProviderFor(thumbnailCache)
final thumbnailCacheProvider = ThumbnailCacheProvider._();

final class ThumbnailCacheProvider
    extends
        $FunctionalProvider<
          AsyncValue<ThumbnailCache>,
          ThumbnailCache,
          FutureOr<ThumbnailCache>
        >
    with $FutureModifier<ThumbnailCache>, $FutureProvider<ThumbnailCache> {
  ThumbnailCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'thumbnailCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$thumbnailCacheHash();

  @$internal
  @override
  $FutureProviderElement<ThumbnailCache> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ThumbnailCache> create(Ref ref) {
    return thumbnailCache(ref);
  }
}

String _$thumbnailCacheHash() => r'999677d7aec443c684f94c30099c6eadb6092245';
