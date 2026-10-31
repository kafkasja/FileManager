// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folder_menu.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(folderMenuItems)
final folderMenuItemsProvider = FolderMenuItemsProvider._();

final class FolderMenuItemsProvider
    extends
        $FunctionalProvider<
          List<FolderMenuItem>,
          List<FolderMenuItem>,
          List<FolderMenuItem>
        >
    with $Provider<List<FolderMenuItem>> {
  FolderMenuItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'folderMenuItemsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$folderMenuItemsHash();

  @$internal
  @override
  $ProviderElement<List<FolderMenuItem>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<FolderMenuItem> create(Ref ref) {
    return folderMenuItems(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<FolderMenuItem> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<FolderMenuItem>>(value),
    );
  }
}

String _$folderMenuItemsHash() => r'd6f4186fb81c4b307944a647881230e3e1e021be';
