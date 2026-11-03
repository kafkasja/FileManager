// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folder_picker.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Tests override it.

@ProviderFor(pickFolder)
final pickFolderProvider = PickFolderProvider._();

/// Tests override it.

final class PickFolderProvider
    extends $FunctionalProvider<PickFolder, PickFolder, PickFolder>
    with $Provider<PickFolder> {
  /// Tests override it.
  PickFolderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pickFolderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pickFolderHash();

  @$internal
  @override
  $ProviderElement<PickFolder> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PickFolder create(Ref ref) {
    return pickFolder(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PickFolder value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PickFolder>(value),
    );
  }
}

String _$pickFolderHash() => r'3f7442c889030dbaffa139c23bf7a5e5bb5f9d30';
