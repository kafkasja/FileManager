// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folder_tree_transfer.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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
        isAutoDispose: true,
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

String _$emptyDirRemoverHash() => r'ab14d6f0b1add86f106061ed70e2a0a6fc2ea8ed';

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
        isAutoDispose: true,
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
    r'134590dd4c761adc167493913142159554a89c47';
