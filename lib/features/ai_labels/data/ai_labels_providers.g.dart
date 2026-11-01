// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_labels_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The API 26 gate. The native library is only opened after it passes.

@ProviderFor(aiSupport)
final aiSupportProvider = AiSupportProvider._();

/// The API 26 gate. The native library is only opened after it passes.

final class AiSupportProvider
    extends
        $FunctionalProvider<
          AsyncValue<AiSupport>,
          AiSupport,
          FutureOr<AiSupport>
        >
    with $FutureModifier<AiSupport>, $FutureProvider<AiSupport> {
  /// The API 26 gate. The native library is only opened after it passes.
  AiSupportProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiSupportProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiSupportHash();

  @$internal
  @override
  $FutureProviderElement<AiSupport> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<AiSupport> create(Ref ref) {
    return aiSupport(ref);
  }
}

String _$aiSupportHash() => r'03e4cc1c97068d804822b1d1e908c001e5abc56d';

/// The bundled `label_map.json` (works without models). Kept by this
/// keepAlive provider, so rootBundle's own cache isn't used (a cached load
/// would be shared across widget tests' fake clocks and never finish).

@ProviderFor(labelMapJson)
final labelMapJsonProvider = LabelMapJsonProvider._();

/// The bundled `label_map.json` (works without models). Kept by this
/// keepAlive provider, so rootBundle's own cache isn't used (a cached load
/// would be shared across widget tests' fake clocks and never finish).

final class LabelMapJsonProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// The bundled `label_map.json` (works without models). Kept by this
  /// keepAlive provider, so rootBundle's own cache isn't used (a cached load
  /// would be shared across widget tests' fake clocks and never finish).
  LabelMapJsonProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'labelMapJsonProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$labelMapJsonHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return labelMapJson(ref);
  }
}

String _$labelMapJsonHash() => r'ba94edbd36f7890f573c61464f8f080470ff78b5';

/// Parsed once; a parse error surfaces as AsyncError (rule 8).

@ProviderFor(labelMap)
final labelMapProvider = LabelMapProvider._();

/// Parsed once; a parse error surfaces as AsyncError (rule 8).

final class LabelMapProvider
    extends
        $FunctionalProvider<AsyncValue<LabelMap>, LabelMap, FutureOr<LabelMap>>
    with $FutureModifier<LabelMap>, $FutureProvider<LabelMap> {
  /// Parsed once; a parse error surfaces as AsyncError (rule 8).
  LabelMapProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'labelMapProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$labelMapHash();

  @$internal
  @override
  $FutureProviderElement<LabelMap> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<LabelMap> create(Ref ref) {
    return labelMap(ref);
  }
}

String _$labelMapHash() => r'a948961ebbc2b4dff892a62adf1a927a7ed9a989';

/// Every storable KFM label (C4's keyword family watches it).

@ProviderFor(labelVocabulary)
final labelVocabularyProvider = LabelVocabularyProvider._();

/// Every storable KFM label (C4's keyword family watches it).

final class LabelVocabularyProvider
    extends $FunctionalProvider<Set<String>, Set<String>, Set<String>>
    with $Provider<Set<String>> {
  /// Every storable KFM label (C4's keyword family watches it).
  LabelVocabularyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'labelVocabularyProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$labelVocabularyHash();

  @$internal
  @override
  $ProviderElement<Set<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Set<String> create(Ref ref) {
    return labelVocabulary(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$labelVocabularyHash() => r'02454adb8d47363dc539f559cb328f476e384846';

/// The model downloader. Created on first use (Settings section, details
/// screen, or the job once labeling is on); no network until Download.

@ProviderFor(aiModelStore)
final aiModelStoreProvider = AiModelStoreProvider._();

/// The model downloader. Created on first use (Settings section, details
/// screen, or the job once labeling is on); no network until Download.

final class AiModelStoreProvider
    extends
        $FunctionalProvider<
          AsyncValue<AiModelStore>,
          AiModelStore,
          FutureOr<AiModelStore>
        >
    with $FutureModifier<AiModelStore>, $FutureProvider<AiModelStore> {
  /// The model downloader. Created on first use (Settings section, details
  /// screen, or the job once labeling is on); no network until Download.
  AiModelStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiModelStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiModelStoreHash();

  @$internal
  @override
  $FutureProviderElement<AiModelStore> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AiModelStore> create(Ref ref) {
    return aiModelStore(ref);
  }
}

String _$aiModelStoreHash() => r'940ad2999dbb22ad133f178ebbe558dd94189300';

@ProviderFor(aiModelState)
final aiModelStateProvider = AiModelStateProvider._();

final class AiModelStateProvider
    extends
        $FunctionalProvider<
          AsyncValue<AiModelState>,
          AiModelState,
          Stream<AiModelState>
        >
    with $FutureModifier<AiModelState>, $StreamProvider<AiModelState> {
  AiModelStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiModelStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiModelStateHash();

  @$internal
  @override
  $StreamProviderElement<AiModelState> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<AiModelState> create(Ref ref) {
    return aiModelState(ref);
  }
}

String _$aiModelStateHash() => r'67199d72327402e94689193458a207458e12b0ea';

/// Not (battery < 20% and not charging). Unknown = may run.

@ProviderFor(batteryGate)
final batteryGateProvider = BatteryGateProvider._();

/// Not (battery < 20% and not charging). Unknown = may run.

final class BatteryGateProvider
    extends
        $FunctionalProvider<
          Future<bool> Function(),
          Future<bool> Function(),
          Future<bool> Function()
        >
    with $Provider<Future<bool> Function()> {
  /// Not (battery < 20% and not charging). Unknown = may run.
  BatteryGateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'batteryGateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$batteryGateHash();

  @$internal
  @override
  $ProviderElement<Future<bool> Function()> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  Future<bool> Function() create(Ref ref) {
    return batteryGate(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Future<bool> Function() value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Future<bool> Function()>(value),
    );
  }
}

String _$batteryGateHash() => r'a80407821550777eddabba600bc161bc554b2d85';

/// Spawns the worker isolate with the TFLite models.

@ProviderFor(labelWorkerStarter)
final labelWorkerStarterProvider = LabelWorkerStarterProvider._();

/// Spawns the worker isolate with the TFLite models.

final class LabelWorkerStarterProvider
    extends
        $FunctionalProvider<
          LabelWorkerStarter,
          LabelWorkerStarter,
          LabelWorkerStarter
        >
    with $Provider<LabelWorkerStarter> {
  /// Spawns the worker isolate with the TFLite models.
  LabelWorkerStarterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'labelWorkerStarterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$labelWorkerStarterHash();

  @$internal
  @override
  $ProviderElement<LabelWorkerStarter> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LabelWorkerStarter create(Ref ref) {
    return labelWorkerStarter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LabelWorkerStarter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LabelWorkerStarter>(value),
    );
  }
}

String _$labelWorkerStarterHash() =>
    r'9b22a9aa7ce8a68fc5dc371aded1d83e93d8d4a5';

/// Registers the labeling job with the in-app runner (watched in
/// `App.build`) and kicks it when labeling is turned on or resumed.

@ProviderFor(labelingJob)
final labelingJobProvider = LabelingJobProvider._();

/// Registers the labeling job with the in-app runner (watched in
/// `App.build`) and kicks it when labeling is turned on or resumed.

final class LabelingJobProvider
    extends $FunctionalProvider<LabelingJob, LabelingJob, LabelingJob>
    with $Provider<LabelingJob> {
  /// Registers the labeling job with the in-app runner (watched in
  /// `App.build`) and kicks it when labeling is turned on or resumed.
  LabelingJobProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'labelingJobProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$labelingJobHash();

  @$internal
  @override
  $ProviderElement<LabelingJob> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LabelingJob create(Ref ref) {
    return labelingJob(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LabelingJob value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LabelingJob>(value),
    );
  }
}

String _$labelingJobHash() => r'd9445dd9b1863b58e19340ed6928e7197bdfd76f';

/// "{processed} of {total} photos labeled" (C4: "Still labeling (63%)").

@ProviderFor(labelingProgress)
final labelingProgressProvider = LabelingProgressProvider._();

/// "{processed} of {total} photos labeled" (C4: "Still labeling (63%)").

final class LabelingProgressProvider
    extends
        $FunctionalProvider<
          AsyncValue<LabelingProgress>,
          LabelingProgress,
          Stream<LabelingProgress>
        >
    with $FutureModifier<LabelingProgress>, $StreamProvider<LabelingProgress> {
  /// "{processed} of {total} photos labeled" (C4: "Still labeling (63%)").
  LabelingProgressProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'labelingProgressProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$labelingProgressHash();

  @$internal
  @override
  $StreamProviderElement<LabelingProgress> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<LabelingProgress> create(Ref ref) {
    return labelingProgress(ref);
  }
}

String _$labelingProgressHash() => r'8eb648ee59e00aee0faa60ee4b7979682804a048';

/// Images that couldn't be labeled (one Settings line).

@ProviderFor(labelingFailedCount)
final labelingFailedCountProvider = LabelingFailedCountProvider._();

/// Images that couldn't be labeled (one Settings line).

final class LabelingFailedCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// Images that couldn't be labeled (one Settings line).
  LabelingFailedCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'labelingFailedCountProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$labelingFailedCountHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return labelingFailedCount(ref);
  }
}

String _$labelingFailedCountHash() =>
    r'948930d9aa100b0b8cb50844aae266e444849290';

/// Job-level errors (worker can't start, models missing). Null = none.

@ProviderFor(labelingJobErrors)
final labelingJobErrorsProvider = LabelingJobErrorsProvider._();

/// Job-level errors (worker can't start, models missing). Null = none.

final class LabelingJobErrorsProvider
    extends
        $FunctionalProvider<
          AsyncValue<LabelingJobError?>,
          LabelingJobError?,
          Stream<LabelingJobError?>
        >
    with
        $FutureModifier<LabelingJobError?>,
        $StreamProvider<LabelingJobError?> {
  /// Job-level errors (worker can't start, models missing). Null = none.
  LabelingJobErrorsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'labelingJobErrorsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$labelingJobErrorsHash();

  @$internal
  @override
  $StreamProviderElement<LabelingJobError?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<LabelingJobError?> create(Ref ref) {
    return labelingJobErrors(ref);
  }
}

String _$labelingJobErrorsHash() => r'1cbd8de0312fb68105d2b4d90f3fcf9231055af6';

@ProviderFor(aiLabelsEnabled)
final aiLabelsEnabledProvider = AiLabelsEnabledProvider._();

final class AiLabelsEnabledProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  AiLabelsEnabledProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiLabelsEnabledProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiLabelsEnabledHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return aiLabelsEnabled(ref);
  }
}

String _$aiLabelsEnabledHash() => r'd7c45d006d893b8be6306b0ddcd64add696dc9ef';

@ProviderFor(aiLabelsPaused)
final aiLabelsPausedProvider = AiLabelsPausedProvider._();

final class AiLabelsPausedProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  AiLabelsPausedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiLabelsPausedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiLabelsPausedHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return aiLabelsPaused(ref);
  }
}

String _$aiLabelsPausedHash() => r'6414f74000dc9494328a3e2e07fadd831fda19ac';

@ProviderFor(aiModelsWifiOnly)
final aiModelsWifiOnlyProvider = AiModelsWifiOnlyProvider._();

final class AiModelsWifiOnlyProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  AiModelsWifiOnlyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiModelsWifiOnlyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiModelsWifiOnlyHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return aiModelsWifiOnly(ref);
  }
}

String _$aiModelsWifiOnlyHash() => r'00038d8f90e4a4ece827e60ed04cc9324e00a787';

@ProviderFor(aiLabelsCardDismissed)
final aiLabelsCardDismissedProvider = AiLabelsCardDismissedProvider._();

final class AiLabelsCardDismissedProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  AiLabelsCardDismissedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiLabelsCardDismissedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiLabelsCardDismissedHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return aiLabelsCardDismissed(ref);
  }
}

String _$aiLabelsCardDismissedHash() =>
    r'0a97d687cca8ed868be4c99eedabc8fee6f210a9';

@ProviderFor(aiLabelsController)
final aiLabelsControllerProvider = AiLabelsControllerProvider._();

final class AiLabelsControllerProvider
    extends
        $FunctionalProvider<
          AiLabelsController,
          AiLabelsController,
          AiLabelsController
        >
    with $Provider<AiLabelsController> {
  AiLabelsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'aiLabelsControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiLabelsControllerHash();

  @$internal
  @override
  $ProviderElement<AiLabelsController> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AiLabelsController create(Ref ref) {
    return aiLabelsController(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AiLabelsController value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AiLabelsController>(value),
    );
  }
}

String _$aiLabelsControllerHash() =>
    r'3b1141cfc4824a192cb5ade84024d7e9e32a9942';
