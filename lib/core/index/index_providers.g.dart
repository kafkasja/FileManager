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

/// Live MediaStore changes (Android), directory watchers over the index
/// roots (Windows, PL1). Empty elsewhere and in tests.

@ProviderFor(mediaChanges)
final mediaChangesProvider = MediaChangesProvider._();

/// Live MediaStore changes (Android), directory watchers over the index
/// roots (Windows, PL1). Empty elsewhere and in tests.

final class MediaChangesProvider
    extends
        $FunctionalProvider<
          Raw<Stream<MediaChange>>,
          Raw<Stream<MediaChange>>,
          Raw<Stream<MediaChange>>
        >
    with $Provider<Raw<Stream<MediaChange>>> {
  /// Live MediaStore changes (Android), directory watchers over the index
  /// roots (Windows, PL1). Empty elsewhere and in tests.
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

String _$mediaChangesHash() => r'80d403b7cbe8c774b795367f7d96af345bf31714';

/// N7: Files-table changes (non-media files) from the native observer.
/// Empty off Android and in tests. The observer runs only while listened
/// (the share server's `ShareChangeTracker`).

@ProviderFor(filesTableChanges)
final filesTableChangesProvider = FilesTableChangesProvider._();

/// N7: Files-table changes (non-media files) from the native observer.
/// Empty off Android and in tests. The observer runs only while listened
/// (the share server's `ShareChangeTracker`).

final class FilesTableChangesProvider
    extends
        $FunctionalProvider<
          Raw<Stream<FilesTableChange>>,
          Raw<Stream<FilesTableChange>>,
          Raw<Stream<FilesTableChange>>
        >
    with $Provider<Raw<Stream<FilesTableChange>>> {
  /// N7: Files-table changes (non-media files) from the native observer.
  /// Empty off Android and in tests. The observer runs only while listened
  /// (the share server's `ShareChangeTracker`).
  FilesTableChangesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filesTableChangesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filesTableChangesHash();

  @$internal
  @override
  $ProviderElement<Raw<Stream<FilesTableChange>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Raw<Stream<FilesTableChange>> create(Ref ref) {
    return filesTableChanges(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Raw<Stream<FilesTableChange>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Raw<Stream<FilesTableChange>>>(
        value,
      ),
    );
  }
}

String _$filesTableChangesHash() => r'ee1553228e1967196c2969c96b215512f02a09c7';

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

String _$mediaIndexerHash() => r'8afa575831af07294b43cdfbc3575f03822e0401';

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
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
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
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return mediaIndexChanges(ref);
  }
}

String _$mediaIndexChangesHash() => r'd90f8857232154c1cc2f73138647765ab3d65e93';

/// Like [mediaIndexChanges], plus tag and favorite changes (B9).

@ProviderFor(indexAndTagChanges)
final indexAndTagChangesProvider = IndexAndTagChangesProvider._();

/// Like [mediaIndexChanges], plus tag and favorite changes (B9).

final class IndexAndTagChangesProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// Like [mediaIndexChanges], plus tag and favorite changes (B9).
  IndexAndTagChangesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'indexAndTagChangesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$indexAndTagChangesHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return indexAndTagChanges(ref);
  }
}

String _$indexAndTagChangesHash() =>
    r'a227a0fd573cd4b1cf16ea09f35041feef01e76e';

/// Like [mediaIndexChanges], plus smart group members and EXIF rows (C5)
/// and AI labels (C3, the Documents group; C4 content search) and C2's
/// image signals (C4 `blurry`).

@ProviderFor(indexAndGroupChanges)
final indexAndGroupChangesProvider = IndexAndGroupChangesProvider._();

/// Like [mediaIndexChanges], plus smart group members and EXIF rows (C5)
/// and AI labels (C3, the Documents group; C4 content search) and C2's
/// image signals (C4 `blurry`).

final class IndexAndGroupChangesProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// Like [mediaIndexChanges], plus smart group members and EXIF rows (C5)
  /// and AI labels (C3, the Documents group; C4 content search) and C2's
  /// image signals (C4 `blurry`).
  IndexAndGroupChangesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'indexAndGroupChangesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$indexAndGroupChangesHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return indexAndGroupChanges(ref);
  }
}

String _$indexAndGroupChangesHash() =>
    r'c6dbe138414bfa9fe297d19e9bfbe1103432986a';

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

String _$thumbnailCacheHash() => r'935b33cf9905e43f200b1be6f2822c44139eec0e';
