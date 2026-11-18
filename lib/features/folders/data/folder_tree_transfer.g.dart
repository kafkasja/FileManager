// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folder_tree_transfer.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// How subfolders are listed (tests: the fake file source has no disk).

@ProviderFor(subfolderLister)
final subfolderListerProvider = SubfolderListerProvider._();

/// How subfolders are listed (tests: the fake file source has no disk).

final class SubfolderListerProvider
    extends
        $FunctionalProvider<SubfolderLister, SubfolderLister, SubfolderLister>
    with $Provider<SubfolderLister> {
  /// How subfolders are listed (tests: the fake file source has no disk).
  SubfolderListerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subfolderListerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subfolderListerHash();

  @$internal
  @override
  $ProviderElement<SubfolderLister> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SubfolderLister create(Ref ref) {
    return subfolderLister(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SubfolderLister value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SubfolderLister>(value),
    );
  }
}

String _$subfolderListerHash() => r'5cc3e1371ca56132cf37af729af08f9452f72df2';

/// How emptied folders are removed (tests: the fake file source has no
/// disk).

@ProviderFor(emptyDirRemover)
final emptyDirRemoverProvider = EmptyDirRemoverProvider._();

/// How emptied folders are removed (tests: the fake file source has no
/// disk).

final class EmptyDirRemoverProvider
    extends
        $FunctionalProvider<EmptyDirRemover, EmptyDirRemover, EmptyDirRemover>
    with $Provider<EmptyDirRemover> {
  /// How emptied folders are removed (tests: the fake file source has no
  /// disk).
  EmptyDirRemoverProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'emptyDirRemoverProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$emptyDirRemoverHash();

  @$internal
  @override
  $ProviderElement<EmptyDirRemover> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  EmptyDirRemover create(Ref ref) {
    return emptyDirRemover(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EmptyDirRemover value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EmptyDirRemover>(value),
    );
  }
}

String _$emptyDirRemoverHash() => r'5a4a2509de32e49b64ab88c93c9f21a1d58dba61';

@ProviderFor(folderTreeTransfer)
final folderTreeTransferProvider = FolderTreeTransferProvider._();

final class FolderTreeTransferProvider
    extends
        $FunctionalProvider<
          FolderTreeTransfer,
          FolderTreeTransfer,
          FolderTreeTransfer
        >
    with $Provider<FolderTreeTransfer> {
  FolderTreeTransferProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'folderTreeTransferProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$folderTreeTransferHash();

  @$internal
  @override
  $ProviderElement<FolderTreeTransfer> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FolderTreeTransfer create(Ref ref) {
    return folderTreeTransfer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FolderTreeTransfer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FolderTreeTransfer>(value),
    );
  }
}

String _$folderTreeTransferHash() =>
    r'342284a221fbc6a6c0c5df39459dd076f1aea338';
