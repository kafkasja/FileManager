// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(backupDocuments)
final backupDocumentsProvider = BackupDocumentsProvider._();

final class BackupDocumentsProvider
    extends
        $FunctionalProvider<BackupDocuments, BackupDocuments, BackupDocuments>
    with $Provider<BackupDocuments> {
  BackupDocumentsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backupDocumentsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backupDocumentsHash();

  @$internal
  @override
  $ProviderElement<BackupDocuments> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BackupDocuments create(Ref ref) {
    return backupDocuments(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackupDocuments value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackupDocuments>(value),
    );
  }
}

String _$backupDocumentsHash() => r'de62b42b23a0c3ff39765c31379ac4fa5ad0fafc';

/// Where backup files are staged between the pickers and the app.

@ProviderFor(backupCacheDir)
final backupCacheDirProvider = BackupCacheDirProvider._();

/// Where backup files are staged between the pickers and the app.

final class BackupCacheDirProvider
    extends
        $FunctionalProvider<
          AsyncValue<Directory>,
          Directory,
          FutureOr<Directory>
        >
    with $FutureModifier<Directory>, $FutureProvider<Directory> {
  /// Where backup files are staged between the pickers and the app.
  BackupCacheDirProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backupCacheDirProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backupCacheDirHash();

  @$internal
  @override
  $FutureProviderElement<Directory> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Directory> create(Ref ref) {
    return backupCacheDir(ref);
  }
}

String _$backupCacheDirHash() => r'63d5657ea0dcd49a5b4c1f19ce0ad09af3fd6a54';

@ProviderFor(backupService)
final backupServiceProvider = BackupServiceProvider._();

final class BackupServiceProvider
    extends $FunctionalProvider<BackupService, BackupService, BackupService>
    with $Provider<BackupService> {
  BackupServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backupServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backupServiceHash();

  @$internal
  @override
  $ProviderElement<BackupService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BackupService create(Ref ref) {
    return backupService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BackupService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BackupService>(value),
    );
  }
}

String _$backupServiceHash() => r'9fb0d56b4a4ecf35b2a3a90e36b079a852d60e7a';

/// Brings `media_index` up to date before matching (an incremental scan).

@ProviderFor(backupIndexRefresh)
final backupIndexRefreshProvider = BackupIndexRefreshProvider._();

/// Brings `media_index` up to date before matching (an incremental scan).

final class BackupIndexRefreshProvider
    extends
        $FunctionalProvider<
          Future<void> Function(),
          Future<void> Function(),
          Future<void> Function()
        >
    with $Provider<Future<void> Function()> {
  /// Brings `media_index` up to date before matching (an incremental scan).
  BackupIndexRefreshProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backupIndexRefreshProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backupIndexRefreshHash();

  @$internal
  @override
  $ProviderElement<Future<void> Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Future<void> Function() create(Ref ref) {
    return backupIndexRefresh(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Future<void> Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Future<void> Function()>(value),
    );
  }
}

String _$backupIndexRefreshHash() =>
    r'b38e7024bc6054041b6f03e6a45541412c6bc747';

/// "Undo last import" is offered while this is true; invalidate after an
/// import or undo.

@ProviderFor(backupUndoAvailable)
final backupUndoAvailableProvider = BackupUndoAvailableProvider._();

/// "Undo last import" is offered while this is true; invalidate after an
/// import or undo.

final class BackupUndoAvailableProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// "Undo last import" is offered while this is true; invalidate after an
  /// import or undo.
  BackupUndoAvailableProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backupUndoAvailableProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backupUndoAvailableHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return backupUndoAvailable(ref);
  }
}

String _$backupUndoAvailableHash() =>
    r'f7d58d96c41018b3d953225ac9a6014bdf73507d';
