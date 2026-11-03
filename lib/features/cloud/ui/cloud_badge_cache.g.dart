// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cloud_badge_cache.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// X4: at least one KFM upload exists. Until then no badge, no filter row,
/// no cloud settings beyond X3's row, and [cloudBadgeCacheProvider] is never
/// built (simple by default).

@ProviderFor(cloudHasUploads)
final cloudHasUploadsProvider = CloudHasUploadsProvider._();

/// X4: at least one KFM upload exists. Until then no badge, no filter row,
/// no cloud settings beyond X3's row, and [cloudBadgeCacheProvider] is never
/// built (simple by default).

final class CloudHasUploadsProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// X4: at least one KFM upload exists. Until then no badge, no filter row,
  /// no cloud settings beyond X3's row, and [cloudBadgeCacheProvider] is never
  /// built (simple by default).
  CloudHasUploadsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cloudHasUploadsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cloudHasUploadsHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return cloudHasUploads(ref);
  }
}

String _$cloudHasUploadsHash() => r'085ed53eb6d892cf0057bef55846b111c63c81a5';

/// X4 "Show cloud icon" (Settings → Cloud).

@ProviderFor(cloudShowBadge)
final cloudShowBadgeProvider = CloudShowBadgeProvider._();

/// X4 "Show cloud icon" (Settings → Cloud).

final class CloudShowBadgeProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// X4 "Show cloud icon" (Settings → Cloud).
  CloudShowBadgeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cloudShowBadgeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cloudShowBadgeHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return cloudShowBadge(ref);
  }
}

String _$cloudShowBadgeHash() => r'd59585dfa88197d26b38d6892211e98684ed5db7';

/// X4: uploaded `cloud_items` facts per file id, looked up in batches (all
/// ids asked for in one frame = one query per 500 ids). The badge itself
/// is computed by the widget from its own `FileRef` (size + modified ms),
/// so a file edited on disk shows "changed" as soon as its ref changes.
/// Loaded ids without uploads map to an empty list.

@ProviderFor(CloudBadgeCache)
final cloudBadgeCacheProvider = CloudBadgeCacheProvider._();

/// X4: uploaded `cloud_items` facts per file id, looked up in batches (all
/// ids asked for in one frame = one query per 500 ids). The badge itself
/// is computed by the widget from its own `FileRef` (size + modified ms),
/// so a file edited on disk shows "changed" as soon as its ref changes.
/// Loaded ids without uploads map to an empty list.
final class CloudBadgeCacheProvider
    extends
        $NotifierProvider<CloudBadgeCache, Map<String, List<CloudUploadFact>>> {
  /// X4: uploaded `cloud_items` facts per file id, looked up in batches (all
  /// ids asked for in one frame = one query per 500 ids). The badge itself
  /// is computed by the widget from its own `FileRef` (size + modified ms),
  /// so a file edited on disk shows "changed" as soon as its ref changes.
  /// Loaded ids without uploads map to an empty list.
  CloudBadgeCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cloudBadgeCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cloudBadgeCacheHash();

  @$internal
  @override
  CloudBadgeCache create() => CloudBadgeCache();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, List<CloudUploadFact>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, List<CloudUploadFact>>>(
        value,
      ),
    );
  }
}

String _$cloudBadgeCacheHash() => r'178b40cb00859384b2a31aa005a0e4b45fbdfd65';

/// X4: uploaded `cloud_items` facts per file id, looked up in batches (all
/// ids asked for in one frame = one query per 500 ids). The badge itself
/// is computed by the widget from its own `FileRef` (size + modified ms),
/// so a file edited on disk shows "changed" as soon as its ref changes.
/// Loaded ids without uploads map to an empty list.

abstract class _$CloudBadgeCache
    extends $Notifier<Map<String, List<CloudUploadFact>>> {
  Map<String, List<CloudUploadFact>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              Map<String, List<CloudUploadFact>>,
              Map<String, List<CloudUploadFact>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                Map<String, List<CloudUploadFact>>,
                Map<String, List<CloudUploadFact>>
              >,
              Map<String, List<CloudUploadFact>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// X4: one file's uploads, newest first (the viewer's info line).

@ProviderFor(cloudUploadsOfFile)
final cloudUploadsOfFileProvider = CloudUploadsOfFileFamily._();

/// X4: one file's uploads, newest first (the viewer's info line).

final class CloudUploadsOfFileProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CloudUploadFact>>,
          List<CloudUploadFact>,
          Stream<List<CloudUploadFact>>
        >
    with
        $FutureModifier<List<CloudUploadFact>>,
        $StreamProvider<List<CloudUploadFact>> {
  /// X4: one file's uploads, newest first (the viewer's info line).
  CloudUploadsOfFileProvider._({
    required CloudUploadsOfFileFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'cloudUploadsOfFileProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cloudUploadsOfFileHash();

  @override
  String toString() {
    return r'cloudUploadsOfFileProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<CloudUploadFact>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<CloudUploadFact>> create(Ref ref) {
    final argument = this.argument as String;
    return cloudUploadsOfFile(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CloudUploadsOfFileProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cloudUploadsOfFileHash() =>
    r'ab16efa1bf0c6bc48eddb60723b80c9695ae85d8';

/// X4: one file's uploads, newest first (the viewer's info line).

final class CloudUploadsOfFileFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<CloudUploadFact>>, String> {
  CloudUploadsOfFileFamily._()
    : super(
        retry: null,
        name: r'cloudUploadsOfFileProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// X4: one file's uploads, newest first (the viewer's info line).

  CloudUploadsOfFileProvider call(String fileId) =>
      CloudUploadsOfFileProvider._(argument: fileId, from: this);

  @override
  String toString() => r'cloudUploadsOfFileProvider';
}
