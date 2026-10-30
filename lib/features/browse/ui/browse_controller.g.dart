// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'browse_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// B2: the stored Browse sort field.

@ProviderFor(browseSortField)
final browseSortFieldProvider = BrowseSortFieldProvider._();

/// B2: the stored Browse sort field.

final class BrowseSortFieldProvider
    extends
        $FunctionalProvider<
          AsyncValue<FileSortField>,
          FileSortField,
          Stream<FileSortField>
        >
    with $FutureModifier<FileSortField>, $StreamProvider<FileSortField> {
  /// B2: the stored Browse sort field.
  BrowseSortFieldProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'browseSortFieldProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$browseSortFieldHash();

  @$internal
  @override
  $StreamProviderElement<FileSortField> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<FileSortField> create(Ref ref) {
    return browseSortField(ref);
  }
}

String _$browseSortFieldHash() => r'ad4b92f60bdf49216b4b8cce4518522a0cf35d26';

/// B2: the stored Browse sort direction.

@ProviderFor(browseSortDescending)
final browseSortDescendingProvider = BrowseSortDescendingProvider._();

/// B2: the stored Browse sort direction.

final class BrowseSortDescendingProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// B2: the stored Browse sort direction.
  BrowseSortDescendingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'browseSortDescendingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$browseSortDescendingHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return browseSortDescending(ref);
  }
}

String _$browseSortDescendingHash() =>
    r'6380fb5cf9f62f9718c1f57e106207f976127e3f';

/// What the Browse tab shows (TASK-B1). Kept while the tab is alive.

@ProviderFor(BrowseViewController)
final browseViewControllerProvider = BrowseViewControllerProvider._();

/// What the Browse tab shows (TASK-B1). Kept while the tab is alive.
final class BrowseViewControllerProvider
    extends $NotifierProvider<BrowseViewController, BrowseView> {
  /// What the Browse tab shows (TASK-B1). Kept while the tab is alive.
  BrowseViewControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'browseViewControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$browseViewControllerHash();

  @$internal
  @override
  BrowseViewController create() => BrowseViewController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BrowseView value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BrowseView>(value),
    );
  }
}

String _$browseViewControllerHash() =>
    r'319bea1122b3e9170b19c09213b53e9420effff8';

/// What the Browse tab shows (TASK-B1). Kept while the tab is alive.

abstract class _$BrowseViewController extends $Notifier<BrowseView> {
  BrowseView build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<BrowseView, BrowseView>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BrowseView, BrowseView>,
              BrowseView,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Keyset-paged results for any [IndexQuery] (Browse, B8 search, B9
/// collections). Contract for B7's paged viewer: `items`, `hasMore`,
/// [loadMore]. Reloads (debounced) when the index changes, keeping as many
/// rows as were loaded so the scroll position holds.

@ProviderFor(FilePages)
final filePagesProvider = FilePagesFamily._();

/// Keyset-paged results for any [IndexQuery] (Browse, B8 search, B9
/// collections). Contract for B7's paged viewer: `items`, `hasMore`,
/// [loadMore]. Reloads (debounced) when the index changes, keeping as many
/// rows as were loaded so the scroll position holds.
final class FilePagesProvider
    extends $AsyncNotifierProvider<FilePages, FilePagesState> {
  /// Keyset-paged results for any [IndexQuery] (Browse, B8 search, B9
  /// collections). Contract for B7's paged viewer: `items`, `hasMore`,
  /// [loadMore]. Reloads (debounced) when the index changes, keeping as many
  /// rows as were loaded so the scroll position holds.
  FilePagesProvider._({
    required FilePagesFamily super.from,
    required IndexQuery super.argument,
  }) : super(
         retry: null,
         name: r'filePagesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$filePagesHash();

  @override
  String toString() {
    return r'filePagesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  FilePages create() => FilePages();

  @override
  bool operator ==(Object other) {
    return other is FilePagesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$filePagesHash() => r'504618ee54348eb6efd7eebbdd1248d90704643e';

/// Keyset-paged results for any [IndexQuery] (Browse, B8 search, B9
/// collections). Contract for B7's paged viewer: `items`, `hasMore`,
/// [loadMore]. Reloads (debounced) when the index changes, keeping as many
/// rows as were loaded so the scroll position holds.

final class FilePagesFamily extends $Family
    with
        $ClassFamilyOverride<
          FilePages,
          AsyncValue<FilePagesState>,
          FilePagesState,
          FutureOr<FilePagesState>,
          IndexQuery
        > {
  FilePagesFamily._()
    : super(
        retry: null,
        name: r'filePagesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Keyset-paged results for any [IndexQuery] (Browse, B8 search, B9
  /// collections). Contract for B7's paged viewer: `items`, `hasMore`,
  /// [loadMore]. Reloads (debounced) when the index changes, keeping as many
  /// rows as were loaded so the scroll position holds.

  FilePagesProvider call(IndexQuery query) =>
      FilePagesProvider._(argument: query, from: this);

  @override
  String toString() => r'filePagesProvider';
}

/// Keyset-paged results for any [IndexQuery] (Browse, B8 search, B9
/// collections). Contract for B7's paged viewer: `items`, `hasMore`,
/// [loadMore]. Reloads (debounced) when the index changes, keeping as many
/// rows as were loaded so the scroll position holds.

abstract class _$FilePages extends $AsyncNotifier<FilePagesState> {
  late final _$args = ref.$arg as IndexQuery;
  IndexQuery get query => _$args;

  FutureOr<FilePagesState> build(IndexQuery query);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<FilePagesState>, FilePagesState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<FilePagesState>, FilePagesState>,
              AsyncValue<FilePagesState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// How many files [query] shows now (chip counts). 0 when nothing of it is
/// visible without All files access. Refreshes with the index (debounced).

@ProviderFor(browseCount)
final browseCountProvider = BrowseCountFamily._();

/// How many files [query] shows now (chip counts). 0 when nothing of it is
/// visible without All files access. Refreshes with the index (debounced).

final class BrowseCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// How many files [query] shows now (chip counts). 0 when nothing of it is
  /// visible without All files access. Refreshes with the index (debounced).
  BrowseCountProvider._({
    required BrowseCountFamily super.from,
    required IndexQuery super.argument,
  }) : super(
         retry: null,
         name: r'browseCountProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$browseCountHash();

  @override
  String toString() {
    return r'browseCountProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    final argument = this.argument as IndexQuery;
    return browseCount(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BrowseCountProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$browseCountHash() => r'1063a31378824053bec2013239b8605bea23b5a6';

/// How many files [query] shows now (chip counts). 0 when nothing of it is
/// visible without All files access. Refreshes with the index (debounced).

final class BrowseCountFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int>, IndexQuery> {
  BrowseCountFamily._()
    : super(
        retry: null,
        name: r'browseCountProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// How many files [query] shows now (chip counts). 0 when nothing of it is
  /// visible without All files access. Refreshes with the index (debounced).

  BrowseCountProvider call(IndexQuery query) =>
      BrowseCountProvider._(argument: query, from: this);

  @override
  String toString() => r'browseCountProvider';
}

/// Folder mode: child folders of [parent] (null = volumes) for [scope].

@ProviderFor(browseFolders)
final browseFoldersProvider = BrowseFoldersFamily._();

/// Folder mode: child folders of [parent] (null = volumes) for [scope].

final class BrowseFoldersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<FolderEntry>>,
          List<FolderEntry>,
          FutureOr<List<FolderEntry>>
        >
    with
        $FutureModifier<List<FolderEntry>>,
        $FutureProvider<List<FolderEntry>> {
  /// Folder mode: child folders of [parent] (null = volumes) for [scope].
  BrowseFoldersProvider._({
    required BrowseFoldersFamily super.from,
    required (IndexQuery, {String? parent}) super.argument,
  }) : super(
         retry: null,
         name: r'browseFoldersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$browseFoldersHash();

  @override
  String toString() {
    return r'browseFoldersProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<FolderEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<FolderEntry>> create(Ref ref) {
    final argument = this.argument as (IndexQuery, {String? parent});
    return browseFolders(ref, argument.$1, parent: argument.parent);
  }

  @override
  bool operator ==(Object other) {
    return other is BrowseFoldersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$browseFoldersHash() => r'8fad246557a48b57787304acef9538e5e9127795';

/// Folder mode: child folders of [parent] (null = volumes) for [scope].

final class BrowseFoldersFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<FolderEntry>>,
          (IndexQuery, {String? parent})
        > {
  BrowseFoldersFamily._()
    : super(
        retry: null,
        name: r'browseFoldersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Folder mode: child folders of [parent] (null = volumes) for [scope].

  BrowseFoldersProvider call(IndexQuery scope, {String? parent}) =>
      BrowseFoldersProvider._(argument: (scope, parent: parent), from: this);

  @override
  String toString() => r'browseFoldersProvider';
}

/// "Other" source: the folders holding files no rule recognised, by file
/// count (largest first). [scope] carries the type/hidden choice.

@ProviderFor(otherFolders)
final otherFoldersProvider = OtherFoldersFamily._();

/// "Other" source: the folders holding files no rule recognised, by file
/// count (largest first). [scope] carries the type/hidden choice.

final class OtherFoldersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<FolderEntry>>,
          List<FolderEntry>,
          FutureOr<List<FolderEntry>>
        >
    with
        $FutureModifier<List<FolderEntry>>,
        $FutureProvider<List<FolderEntry>> {
  /// "Other" source: the folders holding files no rule recognised, by file
  /// count (largest first). [scope] carries the type/hidden choice.
  OtherFoldersProvider._({
    required OtherFoldersFamily super.from,
    required IndexQuery super.argument,
  }) : super(
         retry: null,
         name: r'otherFoldersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$otherFoldersHash();

  @override
  String toString() {
    return r'otherFoldersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<FolderEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<FolderEntry>> create(Ref ref) {
    final argument = this.argument as IndexQuery;
    return otherFolders(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is OtherFoldersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$otherFoldersHash() => r'a369761cb152875650dc6588712c1b53a8a96ee0';

/// "Other" source: the folders holding files no rule recognised, by file
/// count (largest first). [scope] carries the type/hidden choice.

final class OtherFoldersFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<FolderEntry>>, IndexQuery> {
  OtherFoldersFamily._()
    : super(
        retry: null,
        name: r'otherFoldersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// "Other" source: the folders holding files no rule recognised, by file
  /// count (largest first). [scope] carries the type/hidden choice.

  OtherFoldersProvider call(IndexQuery scope) =>
      OtherFoldersProvider._(argument: scope, from: this);

  @override
  String toString() => r'otherFoldersProvider';
}

/// A carousel card's cover: the newest photo or video of [query], else its
/// newest file of any kind (shown as a type icon). Null = empty.

@ProviderFor(collectionCover)
final collectionCoverProvider = CollectionCoverFamily._();

/// A carousel card's cover: the newest photo or video of [query], else its
/// newest file of any kind (shown as a type icon). Null = empty.

final class CollectionCoverProvider
    extends
        $FunctionalProvider<AsyncValue<FileRef?>, FileRef?, FutureOr<FileRef?>>
    with $FutureModifier<FileRef?>, $FutureProvider<FileRef?> {
  /// A carousel card's cover: the newest photo or video of [query], else its
  /// newest file of any kind (shown as a type icon). Null = empty.
  CollectionCoverProvider._({
    required CollectionCoverFamily super.from,
    required IndexQuery super.argument,
  }) : super(
         retry: null,
         name: r'collectionCoverProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$collectionCoverHash();

  @override
  String toString() {
    return r'collectionCoverProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<FileRef?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<FileRef?> create(Ref ref) {
    final argument = this.argument as IndexQuery;
    return collectionCover(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CollectionCoverProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$collectionCoverHash() => r'699ea71e6447cc59ef6f1536e55b7f1554eddead';

/// A carousel card's cover: the newest photo or video of [query], else its
/// newest file of any kind (shown as a type icon). Null = empty.

final class CollectionCoverFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<FileRef?>, IndexQuery> {
  CollectionCoverFamily._()
    : super(
        retry: null,
        name: r'collectionCoverProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A carousel card's cover: the newest photo or video of [query], else its
  /// newest file of any kind (shown as a type icon). Null = empty.

  CollectionCoverProvider call(IndexQuery query) =>
      CollectionCoverProvider._(argument: query, from: this);

  @override
  String toString() => r'collectionCoverProvider';
}
