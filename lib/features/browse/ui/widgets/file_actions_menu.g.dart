// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_actions_menu.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Sorted by [FileMenuItem.order]. E1: while linked, "Send to `name`"
/// comes first.

@ProviderFor(fileMenuItems)
final fileMenuItemsProvider = FileMenuItemsProvider._();

/// Sorted by [FileMenuItem.order]. E1: while linked, "Send to `name`"
/// comes first.

final class FileMenuItemsProvider
    extends
        $FunctionalProvider<
          List<FileMenuItem>,
          List<FileMenuItem>,
          List<FileMenuItem>
        >
    with $Provider<List<FileMenuItem>> {
  /// Sorted by [FileMenuItem.order]. E1: while linked, "Send to `name`"
  /// comes first.
  FileMenuItemsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fileMenuItemsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fileMenuItemsHash();

  @$internal
  @override
  $ProviderElement<List<FileMenuItem>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<FileMenuItem> create(Ref ref) {
    return fileMenuItems(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<FileMenuItem> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<FileMenuItem>>(value),
    );
  }
}

String _$fileMenuItemsHash() => r'9188f25362d4a1c69839a103fedde6ae75642320';
