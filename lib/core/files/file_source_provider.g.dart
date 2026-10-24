// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_source_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// D4's hidden pending-delete folders (Android). Null elsewhere for now.

@ProviderFor(pendingFolder)
final pendingFolderProvider = PendingFolderProvider._();

/// D4's hidden pending-delete folders (Android). Null elsewhere for now.

final class PendingFolderProvider
    extends $FunctionalProvider<PendingFolder?, PendingFolder?, PendingFolder?>
    with $Provider<PendingFolder?> {
  /// D4's hidden pending-delete folders (Android). Null elsewhere for now.
  PendingFolderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingFolderProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingFolderHash();

  @$internal
  @override
  $ProviderElement<PendingFolder?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PendingFolder? create(Ref ref) {
    return pendingFolder(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PendingFolder? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PendingFolder?>(value),
    );
  }
}

String _$pendingFolderHash() => r'd11d0dd31543c82f8b66fbe48ff9101d36d721dc';

/// The device's own storage. Tests override this with `FakeFileSource`.

@ProviderFor(fileSource)
final fileSourceProvider = FileSourceProvider._();

/// The device's own storage. Tests override this with `FakeFileSource`.

final class FileSourceProvider
    extends $FunctionalProvider<FileSource, FileSource, FileSource>
    with $Provider<FileSource> {
  /// The device's own storage. Tests override this with `FakeFileSource`.
  FileSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fileSourceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fileSourceHash();

  @$internal
  @override
  $ProviderElement<FileSource> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  FileSource create(Ref ref) {
    return fileSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FileSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FileSource>(value),
    );
  }
}

String _$fileSourceHash() => r'10b3cb6789beec59f21c8837d1779718427dc48b';
