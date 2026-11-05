// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'desktop_disk_files.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(diskFileLister)
final diskFileListerProvider = DiskFileListerProvider._();

final class DiskFileListerProvider
    extends $FunctionalProvider<DiskFileLister, DiskFileLister, DiskFileLister>
    with $Provider<DiskFileLister> {
  DiskFileListerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diskFileListerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diskFileListerHash();

  @$internal
  @override
  $ProviderElement<DiskFileLister> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DiskFileLister create(Ref ref) {
    return diskFileLister(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiskFileLister value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiskFileLister>(value),
    );
  }
}

String _$diskFileListerHash() => r'c6dfd9da1beff1143ecc1acb2e5c29546a89a3a1';

/// The index covers [folder]: under an index root, and the first full scan
/// is done. Else Browse lists its files from disk too.

@ProviderFor(desktopFolderIndexed)
final desktopFolderIndexedProvider = DesktopFolderIndexedFamily._();

/// The index covers [folder]: under an index root, and the first full scan
/// is done. Else Browse lists its files from disk too.

final class DesktopFolderIndexedProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// The index covers [folder]: under an index root, and the first full scan
  /// is done. Else Browse lists its files from disk too.
  DesktopFolderIndexedProvider._({
    required DesktopFolderIndexedFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'desktopFolderIndexedProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$desktopFolderIndexedHash();

  @override
  String toString() {
    return r'desktopFolderIndexedProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as String;
    return desktopFolderIndexed(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DesktopFolderIndexedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$desktopFolderIndexedHash() =>
    r'840590e2efcba104e5be6fd1c324c5a0029a6c9f';

/// The index covers [folder]: under an index root, and the first full scan
/// is done. Else Browse lists its files from disk too.

final class DesktopFolderIndexedFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, String> {
  DesktopFolderIndexedFamily._()
    : super(
        retry: null,
        name: r'desktopFolderIndexedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The index covers [folder]: under an index root, and the first full scan
  /// is done. Else Browse lists its files from disk too.

  DesktopFolderIndexedProvider call(String folder) =>
      DesktopFolderIndexedProvider._(argument: folder, from: this);

  @override
  String toString() => r'desktopFolderIndexedProvider';
}

/// [folder]'s files from disk when the index doesn't cover it; empty
/// otherwise.

@ProviderFor(desktopDiskFiles)
final desktopDiskFilesProvider = DesktopDiskFilesFamily._();

/// [folder]'s files from disk when the index doesn't cover it; empty
/// otherwise.

final class DesktopDiskFilesProvider
    extends
        $FunctionalProvider<
          AsyncValue<DiskFiles>,
          DiskFiles,
          FutureOr<DiskFiles>
        >
    with $FutureModifier<DiskFiles>, $FutureProvider<DiskFiles> {
  /// [folder]'s files from disk when the index doesn't cover it; empty
  /// otherwise.
  DesktopDiskFilesProvider._({
    required DesktopDiskFilesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'desktopDiskFilesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$desktopDiskFilesHash();

  @override
  String toString() {
    return r'desktopDiskFilesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<DiskFiles> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<DiskFiles> create(Ref ref) {
    final argument = this.argument as String;
    return desktopDiskFiles(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DesktopDiskFilesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$desktopDiskFilesHash() => r'f40d6857d6bd14b208c32377e58b314af478e3fe';

/// [folder]'s files from disk when the index doesn't cover it; empty
/// otherwise.

final class DesktopDiskFilesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<DiskFiles>, String> {
  DesktopDiskFilesFamily._()
    : super(
        retry: null,
        name: r'desktopDiskFilesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// [folder]'s files from disk when the index doesn't cover it; empty
  /// otherwise.

  DesktopDiskFilesProvider call(String folder) =>
      DesktopDiskFilesProvider._(argument: folder, from: this);

  @override
  String toString() => r'desktopDiskFilesProvider';
}
