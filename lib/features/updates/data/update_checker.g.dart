// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_checker.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The installed version (overridden in tests).

@ProviderFor(currentAppVersion)
final currentAppVersionProvider = CurrentAppVersionProvider._();

/// The installed version (overridden in tests).

final class CurrentAppVersionProvider
    extends $FunctionalProvider<AppVersion, AppVersion, AppVersion>
    with $Provider<AppVersion> {
  /// The installed version (overridden in tests).
  CurrentAppVersionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentAppVersionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentAppVersionHash();

  @$internal
  @override
  $ProviderElement<AppVersion> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppVersion create(Ref ref) {
    return currentAppVersion(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppVersion value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppVersion>(value),
    );
  }
}

String _$currentAppVersionHash() => r'ccd75558a1c1e664875473807bbbbd10a5fda092';

/// Wall clock for the daily rule (overridden in tests).

@ProviderFor(updateClock)
final updateClockProvider = UpdateClockProvider._();

/// Wall clock for the daily rule (overridden in tests).

final class UpdateClockProvider
    extends
        $FunctionalProvider<
          DateTime Function(),
          DateTime Function(),
          DateTime Function()
        >
    with $Provider<DateTime Function()> {
  /// Wall clock for the daily rule (overridden in tests).
  UpdateClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateClockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateClockHash();

  @$internal
  @override
  $ProviderElement<DateTime Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DateTime Function() create(Ref ref) {
    return updateClock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime Function()>(value),
    );
  }
}

String _$updateClockHash() => r'ac0e13abc5435626ba8a23eb109da2bb0befe624';

/// "Check for updates" (off by default; rule 7).

@ProviderFor(updateCheckEnabled)
final updateCheckEnabledProvider = UpdateCheckEnabledProvider._();

/// "Check for updates" (off by default; rule 7).

final class UpdateCheckEnabledProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  /// "Check for updates" (off by default; rule 7).
  UpdateCheckEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateCheckEnabledProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateCheckEnabledHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return updateCheckEnabled(ref);
  }
}

String _$updateCheckEnabledHash() =>
    r'69ae1198968d7e0bbf0592b32beb1c77f30caca8';

/// The version whose banner the user closed ('' = none).

@ProviderFor(updateDismissedVersion)
final updateDismissedVersionProvider = UpdateDismissedVersionProvider._();

/// The version whose banner the user closed ('' = none).

final class UpdateDismissedVersionProvider
    extends $FunctionalProvider<AsyncValue<String>, String, Stream<String>>
    with $FutureModifier<String>, $StreamProvider<String> {
  /// The version whose banner the user closed ('' = none).
  UpdateDismissedVersionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateDismissedVersionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateDismissedVersionHash();

  @$internal
  @override
  $StreamProviderElement<String> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<String> create(Ref ref) {
    return updateDismissedVersion(ref);
  }
}

String _$updateDismissedVersionHash() =>
    r'51b7880bc98077b28fa0a78b9846d769721c3f12';

/// TASK-X7: asks GitHub for the latest release. Automatic checks run at most
/// once a day and only while the switch is on; "Check now" always runs.
/// State: null until something is known.

@ProviderFor(UpdateChecker)
final updateCheckerProvider = UpdateCheckerProvider._();

/// TASK-X7: asks GitHub for the latest release. Automatic checks run at most
/// once a day and only while the switch is on; "Check now" always runs.
/// State: null until something is known.
final class UpdateCheckerProvider
    extends $NotifierProvider<UpdateChecker, UpdateStatus?> {
  /// TASK-X7: asks GitHub for the latest release. Automatic checks run at most
  /// once a day and only while the switch is on; "Check now" always runs.
  /// State: null until something is known.
  UpdateCheckerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateCheckerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateCheckerHash();

  @$internal
  @override
  UpdateChecker create() => UpdateChecker();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UpdateStatus? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UpdateStatus?>(value),
    );
  }
}

String _$updateCheckerHash() => r'7b0ee5c7ef156f83bb5e4ab9ce0e555a8905d286';

/// TASK-X7: asks GitHub for the latest release. Automatic checks run at most
/// once a day and only while the switch is on; "Check now" always runs.
/// State: null until something is known.

abstract class _$UpdateChecker extends $Notifier<UpdateStatus?> {
  UpdateStatus? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<UpdateStatus?, UpdateStatus?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<UpdateStatus?, UpdateStatus?>,
              UpdateStatus?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Watched by `App`: the automatic check on start, on resume and when the
/// switch turns on. Does nothing (no request) while the switch is off.

@ProviderFor(updateAutoCheck)
final updateAutoCheckProvider = UpdateAutoCheckProvider._();

/// Watched by `App`: the automatic check on start, on resume and when the
/// switch turns on. Does nothing (no request) while the switch is off.

final class UpdateAutoCheckProvider
    extends $FunctionalProvider<void, void, void>
    with $Provider<void> {
  /// Watched by `App`: the automatic check on start, on resume and when the
  /// switch turns on. Does nothing (no request) while the switch is off.
  UpdateAutoCheckProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'updateAutoCheckProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$updateAutoCheckHash();

  @$internal
  @override
  $ProviderElement<void> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  void create(Ref ref) {
    return updateAutoCheck(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$updateAutoCheckHash() => r'a01f20a3e8acb3a2650c8d4ddd92b7c29c81561f';
