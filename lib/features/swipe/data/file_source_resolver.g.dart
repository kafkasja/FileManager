// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_source_resolver.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(fileSourceResolver)
final fileSourceResolverProvider = FileSourceResolverProvider._();

final class FileSourceResolverProvider
    extends
        $FunctionalProvider<
          FileSourceResolver,
          FileSourceResolver,
          FileSourceResolver
        >
    with $Provider<FileSourceResolver> {
  FileSourceResolverProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fileSourceResolverProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fileSourceResolverHash();

  @$internal
  @override
  $ProviderElement<FileSourceResolver> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FileSourceResolver create(Ref ref) {
    return fileSourceResolver(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FileSourceResolver value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FileSourceResolver>(value),
    );
  }
}

String _$fileSourceResolverHash() =>
    r'8342eb1fd1e8ed72d5c4e6b9185424c5a5da41b8';
