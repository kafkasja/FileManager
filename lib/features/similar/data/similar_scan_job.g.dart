// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'similar_scan_job.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Registers the scan with the in-app runner (watched in `App.build`) and
/// kicks it when the user turns it on or a regroup is needed. Changing
/// strictness or the screenshot setting marks a regroup.

@ProviderFor(similarScanJob)
final similarScanJobProvider = SimilarScanJobProvider._();

/// Registers the scan with the in-app runner (watched in `App.build`) and
/// kicks it when the user turns it on or a regroup is needed. Changing
/// strictness or the screenshot setting marks a regroup.

final class SimilarScanJobProvider
    extends $FunctionalProvider<SimilarScanJob, SimilarScanJob, SimilarScanJob>
    with $Provider<SimilarScanJob> {
  /// Registers the scan with the in-app runner (watched in `App.build`) and
  /// kicks it when the user turns it on or a regroup is needed. Changing
  /// strictness or the screenshot setting marks a regroup.
  SimilarScanJobProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'similarScanJobProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$similarScanJobHash();

  @$internal
  @override
  $ProviderElement<SimilarScanJob> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SimilarScanJob create(Ref ref) {
    return similarScanJob(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SimilarScanJob value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SimilarScanJob>(value),
    );
  }
}

String _$similarScanJobHash() => r'cc11569e3b195ccb2d567645007ecf6ae8cdd609';

/// Scan progress for the Similar screen ("Checking photos… done of total").

@ProviderFor(similarScanProgress)
final similarScanProgressProvider = SimilarScanProgressProvider._();

/// Scan progress for the Similar screen ("Checking photos… done of total").

final class SimilarScanProgressProvider
    extends
        $FunctionalProvider<
          AsyncValue<SimilarScanProgress>,
          SimilarScanProgress,
          Stream<SimilarScanProgress>
        >
    with
        $FutureModifier<SimilarScanProgress>,
        $StreamProvider<SimilarScanProgress> {
  /// Scan progress for the Similar screen ("Checking photos… done of total").
  SimilarScanProgressProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'similarScanProgressProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$similarScanProgressHash();

  @$internal
  @override
  $StreamProviderElement<SimilarScanProgress> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<SimilarScanProgress> create(Ref ref) {
    return similarScanProgress(ref);
  }
}

String _$similarScanProgressHash() =>
    r'6d6c0723fb4ef039d6cf25d0d81b2e24a4109a94';
