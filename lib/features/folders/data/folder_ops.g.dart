// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folder_ops.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(folderOps)
final folderOpsProvider = FolderOpsProvider._();

final class FolderOpsProvider
    extends $FunctionalProvider<FolderOps, FolderOps, FolderOps>
    with $Provider<FolderOps> {
  FolderOpsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'folderOpsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$folderOpsHash();

  @$internal
  @override
  $ProviderElement<FolderOps> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FolderOps create(Ref ref) {
    return folderOps(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FolderOps value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FolderOps>(value),
    );
  }
}

String _$folderOpsHash() => r'3dc315af8cb62427fbfaf702d9c8742299a62a29';
