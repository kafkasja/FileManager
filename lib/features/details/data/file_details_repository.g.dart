// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_details_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(detailsPlatform)
final detailsPlatformProvider = DetailsPlatformProvider._();

final class DetailsPlatformProvider
    extends
        $FunctionalProvider<DetailsPlatform, DetailsPlatform, DetailsPlatform>
    with $Provider<DetailsPlatform> {
  DetailsPlatformProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'detailsPlatformProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$detailsPlatformHash();

  @$internal
  @override
  $ProviderElement<DetailsPlatform> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DetailsPlatform create(Ref ref) {
    return detailsPlatform(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DetailsPlatform value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DetailsPlatform>(value),
    );
  }
}

String _$detailsPlatformHash() => r'47c864e61ab778e95fca6d1b9b129c571f49943d';

/// Parsed once per app run.

@ProviderFor(knownFiles)
final knownFilesProvider = KnownFilesProvider._();

/// Parsed once per app run.

final class KnownFilesProvider
    extends
        $FunctionalProvider<
          AsyncValue<KnownFiles>,
          KnownFiles,
          FutureOr<KnownFiles>
        >
    with $FutureModifier<KnownFiles>, $FutureProvider<KnownFiles> {
  /// Parsed once per app run.
  KnownFilesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'knownFilesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$knownFilesHash();

  @$internal
  @override
  $FutureProviderElement<KnownFiles> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<KnownFiles> create(Ref ref) {
    return knownFiles(ref);
  }
}

String _$knownFilesHash() => r'ee00680ef58aeddbe33ce55ce9cbbf8bb2d8e3f9';

@ProviderFor(knownApps)
final knownAppsProvider = KnownAppsProvider._();

final class KnownAppsProvider
    extends
        $FunctionalProvider<
          AsyncValue<KnownApps>,
          KnownApps,
          FutureOr<KnownApps>
        >
    with $FutureModifier<KnownApps>, $FutureProvider<KnownApps> {
  KnownAppsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'knownAppsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$knownAppsHash();

  @$internal
  @override
  $FutureProviderElement<KnownApps> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<KnownApps> create(Ref ref) {
    return knownApps(ref);
  }
}

String _$knownAppsHash() => r'204a0d4e9c6d5902214e78c5699c165257dd5a86';

@ProviderFor(fileDetailsRepository)
final fileDetailsRepositoryProvider = FileDetailsRepositoryProvider._();

final class FileDetailsRepositoryProvider
    extends
        $FunctionalProvider<
          FileDetailsRepository,
          FileDetailsRepository,
          FileDetailsRepository
        >
    with $Provider<FileDetailsRepository> {
  FileDetailsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fileDetailsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fileDetailsRepositoryHash();

  @$internal
  @override
  $ProviderElement<FileDetailsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FileDetailsRepository create(Ref ref) {
    return fileDetailsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FileDetailsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FileDetailsRepository>(value),
    );
  }
}

String _$fileDetailsRepositoryHash() =>
    r'a8dd2a85b3fed45d8af90903900e7708c04d3975';

/// The file's details; loaded on open, never stored.

@ProviderFor(fileDetails)
final fileDetailsProvider = FileDetailsFamily._();

/// The file's details; loaded on open, never stored.

final class FileDetailsProvider
    extends
        $FunctionalProvider<
          AsyncValue<FileDetails>,
          FileDetails,
          FutureOr<FileDetails>
        >
    with $FutureModifier<FileDetails>, $FutureProvider<FileDetails> {
  /// The file's details; loaded on open, never stored.
  FileDetailsProvider._({
    required FileDetailsFamily super.from,
    required FileRef super.argument,
  }) : super(
         retry: null,
         name: r'fileDetailsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$fileDetailsHash();

  @override
  String toString() {
    return r'fileDetailsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<FileDetails> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<FileDetails> create(Ref ref) {
    final argument = this.argument as FileRef;
    return fileDetails(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FileDetailsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$fileDetailsHash() => r'7520c309af68f60f800e80d342e8e88db83dfe04';

/// The file's details; loaded on open, never stored.

final class FileDetailsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<FileDetails>, FileRef> {
  FileDetailsFamily._()
    : super(
        retry: null,
        name: r'fileDetailsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The file's details; loaded on open, never stored.

  FileDetailsProvider call(FileRef file) =>
      FileDetailsProvider._(argument: file, from: this);

  @override
  String toString() => r'fileDetailsProvider';
}
