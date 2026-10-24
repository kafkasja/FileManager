// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trash_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The delete-mode setting (D1). New sessions copy it.

@ProviderFor(deleteModeSetting)
final deleteModeSettingProvider = DeleteModeSettingProvider._();

/// The delete-mode setting (D1). New sessions copy it.

final class DeleteModeSettingProvider
    extends
        $FunctionalProvider<
          AsyncValue<DeleteMode>,
          DeleteMode,
          Stream<DeleteMode>
        >
    with $FutureModifier<DeleteMode>, $StreamProvider<DeleteMode> {
  /// The delete-mode setting (D1). New sessions copy it.
  DeleteModeSettingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deleteModeSettingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deleteModeSettingHash();

  @$internal
  @override
  $StreamProviderElement<DeleteMode> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<DeleteMode> create(Ref ref) {
    return deleteModeSetting(ref);
  }
}

String _$deleteModeSettingHash() => r'cc41c19c192087a59b8184439a0dae78724b2c39';

/// Pending-folder retention in days (D4), clamped to 1–90.

@ProviderFor(pendingRetentionDays)
final pendingRetentionDaysProvider = PendingRetentionDaysProvider._();

/// Pending-folder retention in days (D4), clamped to 1–90.

final class PendingRetentionDaysProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// Pending-folder retention in days (D4), clamped to 1–90.
  PendingRetentionDaysProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingRetentionDaysProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingRetentionDaysHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return pendingRetentionDays(ref);
  }
}

String _$pendingRetentionDaysHash() =>
    r'c42d8a309e12a3060eb56a6a31a3ce234d1559d1';

@ProviderFor(trashLedger)
final trashLedgerProvider = TrashLedgerProvider._();

final class TrashLedgerProvider
    extends $FunctionalProvider<TrashLedger, TrashLedger, TrashLedger>
    with $Provider<TrashLedger> {
  TrashLedgerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trashLedgerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trashLedgerHash();

  @$internal
  @override
  $ProviderElement<TrashLedger> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TrashLedger create(Ref ref) {
    return trashLedger(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TrashLedger value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TrashLedger>(value),
    );
  }
}

String _$trashLedgerHash() => r'ae37641a65b562bdd2fc709d305421080c099239';

/// H2: all such deletes, any session, newest first.

@ProviderFor(folderUnavailable)
final folderUnavailableProvider = FolderUnavailableProvider._();

/// H2: all such deletes, any session, newest first.

final class FolderUnavailableProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<UnavailableDelete>>,
          List<UnavailableDelete>,
          Stream<List<UnavailableDelete>>
        >
    with
        $FutureModifier<List<UnavailableDelete>>,
        $StreamProvider<List<UnavailableDelete>> {
  /// H2: all such deletes, any session, newest first.
  FolderUnavailableProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'folderUnavailableProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$folderUnavailableHash();

  @$internal
  @override
  $StreamProviderElement<List<UnavailableDelete>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<UnavailableDelete>> create(Ref ref) {
    return folderUnavailable(ref);
  }
}

String _$folderUnavailableHash() => r'96b16c325dd59de59c6066600049bd61261b76a7';

/// Once per app run, after storage access is granted. The order matters.

@ProviderFor(startupMaintenance)
final startupMaintenanceProvider = StartupMaintenanceProvider._();

/// Once per app run, after storage access is granted. The order matters.

final class StartupMaintenanceProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Once per app run, after storage access is granted. The order matters.
  StartupMaintenanceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'startupMaintenanceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$startupMaintenanceHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return startupMaintenance(ref);
  }
}

String _$startupMaintenanceHash() =>
    r'a72e5a65193cbedd9206d9f507048e9673d34e1c';
