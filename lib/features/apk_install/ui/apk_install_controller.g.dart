// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'apk_install_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The info sheet of one `.apk` (TASK-X5). Disposed with the sheet, which
/// also deletes a cache copy of a `content://` file.

@ProviderFor(ApkInstallController)
final apkInstallControllerProvider = ApkInstallControllerFamily._();

/// The info sheet of one `.apk` (TASK-X5). Disposed with the sheet, which
/// also deletes a cache copy of a `content://` file.
final class ApkInstallControllerProvider
    extends $AsyncNotifierProvider<ApkInstallController, ApkInfo> {
  /// The info sheet of one `.apk` (TASK-X5). Disposed with the sheet, which
  /// also deletes a cache copy of a `content://` file.
  ApkInstallControllerProvider._({
    required ApkInstallControllerFamily super.from,
    required FileRef super.argument,
  }) : super(
         retry: _noRetry,
         name: r'apkInstallControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$apkInstallControllerHash();

  @override
  String toString() {
    return r'apkInstallControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ApkInstallController create() => ApkInstallController();

  @override
  bool operator ==(Object other) {
    return other is ApkInstallControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$apkInstallControllerHash() =>
    r'c86103bf225438b1195e284a8b37dae7a2a25f4c';

/// The info sheet of one `.apk` (TASK-X5). Disposed with the sheet, which
/// also deletes a cache copy of a `content://` file.

final class ApkInstallControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          ApkInstallController,
          AsyncValue<ApkInfo>,
          ApkInfo,
          FutureOr<ApkInfo>,
          FileRef
        > {
  ApkInstallControllerFamily._()
    : super(
        retry: _noRetry,
        name: r'apkInstallControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The info sheet of one `.apk` (TASK-X5). Disposed with the sheet, which
  /// also deletes a cache copy of a `content://` file.

  ApkInstallControllerProvider call(FileRef file) =>
      ApkInstallControllerProvider._(argument: file, from: this);

  @override
  String toString() => r'apkInstallControllerProvider';
}

/// The info sheet of one `.apk` (TASK-X5). Disposed with the sheet, which
/// also deletes a cache copy of a `content://` file.

abstract class _$ApkInstallController extends $AsyncNotifier<ApkInfo> {
  late final _$args = ref.$arg as FileRef;
  FileRef get file => _$args;

  FutureOr<ApkInfo> build(FileRef file);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ApkInfo>, ApkInfo>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ApkInfo>, ApkInfo>,
              AsyncValue<ApkInfo>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
