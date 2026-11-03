// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_job_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(localJobsDao)
final localJobsDaoProvider = LocalJobsDaoProvider._();

final class LocalJobsDaoProvider
    extends $FunctionalProvider<LocalJobsDao, LocalJobsDao, LocalJobsDao>
    with $Provider<LocalJobsDao> {
  LocalJobsDaoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localJobsDaoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localJobsDaoHash();

  @$internal
  @override
  $ProviderElement<LocalJobsDao> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LocalJobsDao create(Ref ref) {
    return localJobsDao(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalJobsDao value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalJobsDao>(value),
    );
  }
}

String _$localJobsDaoHash() => r'e71999bf1f37138f6c95f75892d4f53d832ef5a7';

/// The "On this phone" job runner (TASK-U2). Null when the file source
/// isn't the routing one (tests, other platforms). Recovers interrupted
/// jobs once and follows U1's place changes (pause / resume).

@ProviderFor(localJobRunner)
final localJobRunnerProvider = LocalJobRunnerProvider._();

/// The "On this phone" job runner (TASK-U2). Null when the file source
/// isn't the routing one (tests, other platforms). Recovers interrupted
/// jobs once and follows U1's place changes (pause / resume).

final class LocalJobRunnerProvider
    extends
        $FunctionalProvider<LocalJobRunner?, LocalJobRunner?, LocalJobRunner?>
    with $Provider<LocalJobRunner?> {
  /// The "On this phone" job runner (TASK-U2). Null when the file source
  /// isn't the routing one (tests, other platforms). Recovers interrupted
  /// jobs once and follows U1's place changes (pause / resume).
  LocalJobRunnerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'localJobRunnerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$localJobRunnerHash();

  @$internal
  @override
  $ProviderElement<LocalJobRunner?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LocalJobRunner? create(Ref ref) {
    return localJobRunner(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocalJobRunner? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocalJobRunner?>(value),
    );
  }
}

String _$localJobRunnerHash() => r'450a60f48cda14ce12898ae85f65f6c5278ed9f3';
