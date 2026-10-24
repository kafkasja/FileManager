// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'storage_access_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(permissionService)
final permissionServiceProvider = PermissionServiceProvider._();

final class PermissionServiceProvider
    extends
        $FunctionalProvider<
          PermissionService,
          PermissionService,
          PermissionService
        >
    with $Provider<PermissionService> {
  PermissionServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'permissionServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$permissionServiceHash();

  @$internal
  @override
  $ProviderElement<PermissionService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PermissionService create(Ref ref) {
    return permissionService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PermissionService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PermissionService>(value),
    );
  }
}

String _$permissionServiceHash() => r'6edd1bc551244dc298b0678933dd9c55da4e49b3';

/// Current storage access. Re-checked whenever the app returns to the
/// foreground (the user may have changed it in system settings).

@ProviderFor(StorageAccessController)
final storageAccessControllerProvider = StorageAccessControllerProvider._();

/// Current storage access. Re-checked whenever the app returns to the
/// foreground (the user may have changed it in system settings).
final class StorageAccessControllerProvider
    extends $AsyncNotifierProvider<StorageAccessController, StorageAccess> {
  /// Current storage access. Re-checked whenever the app returns to the
  /// foreground (the user may have changed it in system settings).
  StorageAccessControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storageAccessControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storageAccessControllerHash();

  @$internal
  @override
  StorageAccessController create() => StorageAccessController();
}

String _$storageAccessControllerHash() =>
    r'11ac41bad44dc77c5788e08139ef6b523bb60d8b';

/// Current storage access. Re-checked whenever the app returns to the
/// foreground (the user may have changed it in system settings).

abstract class _$StorageAccessController extends $AsyncNotifier<StorageAccess> {
  FutureOr<StorageAccess> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<StorageAccess>, StorageAccess>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<StorageAccess>, StorageAccess>,
              AsyncValue<StorageAccess>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// "Not now" on the All files access sheet, remembered for this app run only.

@ProviderFor(AllFilesNotNow)
final allFilesNotNowProvider = AllFilesNotNowProvider._();

/// "Not now" on the All files access sheet, remembered for this app run only.
final class AllFilesNotNowProvider
    extends $NotifierProvider<AllFilesNotNow, bool> {
  /// "Not now" on the All files access sheet, remembered for this app run only.
  AllFilesNotNowProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allFilesNotNowProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allFilesNotNowHash();

  @$internal
  @override
  AllFilesNotNow create() => AllFilesNotNow();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$allFilesNotNowHash() => r'eaf0d8a2d6608935584372e373990e8f480ffd98';

/// "Not now" on the All files access sheet, remembered for this app run only.

abstract class _$AllFilesNotNow extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
