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

/// Once per app run, after storage access is granted: rows stuck in
/// `committing` (D2), rebuild the pending-folder table if app data was
/// cleared, and purge expired pending items (D4). The daily background
/// purge (WorkManager) is not built yet.

@ProviderFor(startupMaintenance)
final startupMaintenanceProvider = StartupMaintenanceProvider._();

/// Once per app run, after storage access is granted: rows stuck in
/// `committing` (D2), rebuild the pending-folder table if app data was
/// cleared, and purge expired pending items (D4). The daily background
/// purge (WorkManager) is not built yet.

final class StartupMaintenanceProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Once per app run, after storage access is granted: rows stuck in
  /// `committing` (D2), rebuild the pending-folder table if app data was
  /// cleared, and purge expired pending items (D4). The daily background
  /// purge (WorkManager) is not built yet.
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
    r'72654aafacb0978a3d4c7ae121be4213ca6df3cf';
