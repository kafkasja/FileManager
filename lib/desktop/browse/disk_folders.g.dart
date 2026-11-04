// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'disk_folders.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(diskFolderLister)
final diskFolderListerProvider = DiskFolderListerProvider._();

final class DiskFolderListerProvider
    extends
        $FunctionalProvider<
          DiskFolderLister,
          DiskFolderLister,
          DiskFolderLister
        >
    with $Provider<DiskFolderLister> {
  DiskFolderListerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'diskFolderListerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$diskFolderListerHash();

  @$internal
  @override
  $ProviderElement<DiskFolderLister> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DiskFolderLister create(Ref ref) {
    return diskFolderLister(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DiskFolderLister value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DiskFolderLister>(value),
    );
  }
}

String _$diskFolderListerHash() => r'f3c225547126f321f610a33edaf91b6bc96f18bd';

/// [folder]'s subfolders on disk; listed again when the index changes and
/// whenever the folder is opened again.

@ProviderFor(desktopDiskFolders)
final desktopDiskFoldersProvider = DesktopDiskFoldersFamily._();

/// [folder]'s subfolders on disk; listed again when the index changes and
/// whenever the folder is opened again.

final class DesktopDiskFoldersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DiskFolder>>,
          List<DiskFolder>,
          FutureOr<List<DiskFolder>>
        >
    with $FutureModifier<List<DiskFolder>>, $FutureProvider<List<DiskFolder>> {
  /// [folder]'s subfolders on disk; listed again when the index changes and
  /// whenever the folder is opened again.
  DesktopDiskFoldersProvider._({
    required DesktopDiskFoldersFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'desktopDiskFoldersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$desktopDiskFoldersHash();

  @override
  String toString() {
    return r'desktopDiskFoldersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<DiskFolder>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<DiskFolder>> create(Ref ref) {
    final argument = this.argument as String;
    return desktopDiskFolders(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DesktopDiskFoldersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$desktopDiskFoldersHash() =>
    r'b6427a6108a8ce85e2ad334f72383ded77e43c5e';

/// [folder]'s subfolders on disk; listed again when the index changes and
/// whenever the folder is opened again.

final class DesktopDiskFoldersFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<DiskFolder>>, String> {
  DesktopDiskFoldersFamily._()
    : super(
        retry: null,
        name: r'desktopDiskFoldersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// [folder]'s subfolders on disk; listed again when the index changes and
  /// whenever the folder is opened again.

  DesktopDiskFoldersProvider call(String folder) =>
      DesktopDiskFoldersProvider._(argument: folder, from: this);

  @override
  String toString() => r'desktopDiskFoldersProvider';
}
