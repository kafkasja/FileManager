// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared_folder_fs.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sharedFolderFs)
final sharedFolderFsProvider = SharedFolderFsProvider._();

final class SharedFolderFsProvider
    extends $FunctionalProvider<SharedFolderFs, SharedFolderFs, SharedFolderFs>
    with $Provider<SharedFolderFs> {
  SharedFolderFsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharedFolderFsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharedFolderFsHash();

  @$internal
  @override
  $ProviderElement<SharedFolderFs> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SharedFolderFs create(Ref ref) {
    return sharedFolderFs(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SharedFolderFs value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SharedFolderFs>(value),
    );
  }
}

String _$sharedFolderFsHash() => r'97fa3e95603a20ce7178150bb1a0c97d50d6e6ab';
