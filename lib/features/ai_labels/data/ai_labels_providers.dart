import 'dart:async';
import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:kfm/core/background/in_app_jobs.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/android/files_channel.dart';
import 'package:kfm/features/ai_labels/data/ai_labels_repository.dart';
import 'package:kfm/features/ai_labels/data/ai_model_manifest.dart';
import 'package:kfm/features/ai_labels/data/ai_model_store.dart';
import 'package:kfm/features/ai_labels/data/label_worker.dart';
import 'package:kfm/features/ai_labels/data/labeling_job.dart';
import 'package:kfm/features/ai_labels/data/tflite_models.dart';
import 'package:kfm/features/ai_labels/domain/label_map.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ai_labels_providers.g.dart';

/// Whether on-device labeling can run here (TASK-C3 §1).
enum AiSupport {
  supported,

  /// Android 7 (API 24–25): LiteRT's native library can't load.
  needsAndroid8,

  /// No native runtime bundled for this platform yet (Windows until PL1).
  unsupportedPlatform,
}

/// The API 26 gate. The native library is only opened after it passes.
@Riverpod(keepAlive: true)
Future<AiSupport> aiSupport(Ref ref) async {
  if (!Platform.isAndroid) return AiSupport.unsupportedPlatform;
  try {
    final sdk = await FilesChannel().sdkInt();
    return sdk >= 26 ? AiSupport.supported : AiSupport.needsAndroid8;
  } on Object {
    return AiSupport.unsupportedPlatform;
  }
}

/// The bundled `label_map.json` (works without models). Kept by this
/// keepAlive provider, so rootBundle's own cache isn't used (a cached load
/// would be shared across widget tests' fake clocks and never finish).
@Riverpod(keepAlive: true)
Future<String> labelMapJson(Ref ref) =>
    rootBundle.loadString(LabelMap.assetPath, cache: false);

/// Parsed once; a parse error surfaces as AsyncError (rule 8).
@Riverpod(keepAlive: true)
Future<LabelMap> labelMap(Ref ref) async =>
    LabelMap.parse(await ref.watch(labelMapJsonProvider.future));

/// Every storable KFM label (C4's keyword family watches it).
@Riverpod(keepAlive: true)
Set<String> labelVocabulary(Ref ref) =>
    ref.watch(labelMapProvider).value?.vocabulary ?? const {};

bool _isWifi(List<ConnectivityResult> r) =>
    r.contains(ConnectivityResult.wifi) ||
    r.contains(ConnectivityResult.ethernet);

/// The model downloader. Created on first use (Settings section, details
/// screen, or the job once labeling is on); no network until Download.
@Riverpod(keepAlive: true)
Future<AiModelStore> aiModelStore(Ref ref) async {
  final manifest = AiModelManifest.parse(
    await rootBundle.loadString(AiModelManifest.assetPath),
  );
  final settings = ref.watch(settingsRepositoryProvider);
  final connectivity = Connectivity();
  final store = AiModelStore(
    manifest: manifest,
    baseDir: getApplicationSupportDirectory,
    wifiOnly: () => settings.read(AppSettings.aiModelsWifiOnly),
    isOnWifi: () async => _isWifi(await connectivity.checkConnectivity()),
    wifiChanges: connectivity.onConnectivityChanged.map(_isWifi),
  );
  ref.onDispose(store.dispose);
  final state = await store.verifyInstalled();
  // An outdated/corrupt set turns labeling off (never re-downloaded
  // automatically).
  if (state is AiModelsNotInstalled) {
    await settings.write(AppSettings.aiLabelsEnabled, false);
  }
  return store;
}

@Riverpod(keepAlive: true)
Stream<AiModelState> aiModelState(Ref ref) async* {
  final store = await ref.watch(aiModelStoreProvider.future);
  yield store.state;
  yield* store.states;
}

/// Not (battery < 20% and not charging). Unknown = may run.
@Riverpod(keepAlive: true)
Future<bool> Function() batteryGate(Ref ref) {
  final battery = Battery();
  return () async {
    try {
      final state = await battery.batteryState;
      if (state == BatteryState.charging ||
          state == BatteryState.full ||
          state == BatteryState.connectedNotCharging) {
        return true;
      }
      return await battery.batteryLevel >= LabelingJob.lowBatteryPercent;
    } on Object {
      return true;
    }
  };
}

/// Spawns the worker isolate with the TFLite models.
@Riverpod(keepAlive: true)
LabelWorkerStarter labelWorkerStarter(Ref ref) =>
    (models) async => await IsolateLabelWorker.spawn(
      classifier: models.classifier,
      detector: models.detector,
      labelMapJson: await ref.read(labelMapJsonProvider.future),
      createModels: createTfliteModels,
    );

/// Registers the labeling job with the in-app runner (watched in
/// `App.build`) and kicks it when labeling is turned on or resumed.
@Riverpod(keepAlive: true)
LabelingJob labelingJob(Ref ref) {
  final settings = ref.watch(settingsRepositoryProvider);
  final runner = ref.watch(inAppJobRunnerProvider);
  final job = LabelingJob(
    repo: ref.watch(aiLabelsRepositoryProvider),
    settings: settings,
    loadModels: () async =>
        await (await ref.read(aiModelStoreProvider.future)).loadVerified(),
    startWorker: ref.watch(labelWorkerStarterProvider),
    supported: () async =>
        await ref.read(aiSupportProvider.future) == AiSupport.supported,
    batteryOk: ref.watch(batteryGateProvider),
  );
  runner.register(job);
  final subs = [
    settings.watch(AppSettings.aiLabelsEnabled).listen((on) {
      if (on) runner.kick();
    }),
    settings.watch(AppSettings.aiLabelsPaused).listen((paused) {
      if (!paused) runner.kick();
    }),
  ];
  ref.onDispose(() {
    for (final s in subs) {
      unawaited(s.cancel());
    }
    runner.unregister(job);
    job.dispose();
  });
  return job;
}

/// "{processed} of {total} photos labeled" (C4: "Still labeling (63%)").
@Riverpod(keepAlive: true)
Stream<LabelingProgress> labelingProgress(Ref ref) => ref
    .watch(aiLabelsRepositoryProvider)
    .watchProgress(LabelingJob.modelVersion);

/// Images that couldn't be labeled (one Settings line).
@Riverpod(keepAlive: true)
Stream<int> labelingFailedCount(Ref ref) =>
    ref.watch(aiLabelsRepositoryProvider).watchFailedCount();

/// Job-level errors (worker can't start, models missing). Null = none.
@Riverpod(keepAlive: true)
Stream<LabelingJobError?> labelingJobErrors(Ref ref) {
  final errors = ref.watch(labelingJobProvider).errors;
  final controller = StreamController<LabelingJobError?>();
  void push() => controller.add(errors.value);
  push();
  errors.addListener(push);
  ref.onDispose(() {
    errors.removeListener(push);
    unawaited(controller.close());
  });
  return controller.stream;
}

@riverpod
Stream<bool> aiLabelsEnabled(Ref ref) =>
    ref.watch(settingsRepositoryProvider).watch(AppSettings.aiLabelsEnabled);

@riverpod
Stream<bool> aiLabelsPaused(Ref ref) =>
    ref.watch(settingsRepositoryProvider).watch(AppSettings.aiLabelsPaused);

@riverpod
Stream<bool> aiModelsWifiOnly(Ref ref) =>
    ref.watch(settingsRepositoryProvider).watch(AppSettings.aiModelsWifiOnly);

@riverpod
Stream<bool> aiLabelsCardDismissed(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watch(AppSettings.aiLabelsCardDismissed);

/// Result of "Turn on".
enum TurnOnResult {
  /// Models installed: labeling is on now.
  enabled,

  /// Show the details screen first (the Download button is the consent).
  needsDownload,

  /// API < 26 or no runtime: nothing to offer.
  unsupported,
}

/// The user actions of the card, Settings section and details screen.
class AiLabelsController {
  new(this._ref);

  final Ref _ref;

  Future<AiModelStore> get _store => _ref.read(aiModelStoreProvider.future);

  Future<void> _set({required bool enabled}) async {
    final settings = _ref.read(settingsRepositoryProvider);
    if (enabled) await settings.write(AppSettings.aiLabelsPaused, false);
    await settings.write(AppSettings.aiLabelsEnabled, enabled);
    if (enabled) _ref.read(inAppJobRunnerProvider).kick();
  }

  Future<TurnOnResult> turnOn() async {
    if (await _ref.read(aiSupportProvider.future) != AiSupport.supported) {
      return TurnOnResult.unsupported;
    }
    if (!(await _store).isInstalled) return TurnOnResult.needsDownload;
    await _set(enabled: true);
    return TurnOnResult.enabled;
  }

  /// The explicit, user-confirmed download; labeling turns on after it.
  Future<bool> download({bool useMobileData = false}) async {
    final ok = await (await _store).download(useMobileData: useMobileData);
    if (ok) await _set(enabled: true);
    return ok;
  }

  Future<void> cancelDownload() async => await (await _store).cancel();

  /// Only while the models are installed.
  Future<void> setEnabled({required bool on}) async {
    if (on && !(await _store).isInstalled) return;
    await _set(enabled: on);
  }

  Future<void> setPaused({required bool paused}) async {
    await _ref
        .read(settingsRepositoryProvider)
        .write(AppSettings.aiLabelsPaused, paused);
    if (!paused) _ref.read(inAppJobRunnerProvider).kick();
  }

  Future<void> setWifiOnly({required bool on}) => _ref
      .read(settingsRepositoryProvider)
      .write(AppSettings.aiModelsWifiOnly, on);

  Future<void> dismissCard() => _ref
      .read(settingsRepositoryProvider)
      .write(AppSettings.aiLabelsCardDismissed, true);

  Future<void> resetLabels() => _ref.read(aiLabelsRepositoryProvider).reset();

  /// Stops labeling and deletes `ai_models/`; [deleteLabels] also runs
  /// "Reset labels" (otherwise existing labels keep working in search).
  Future<void> removeModels({required bool deleteLabels}) async {
    await _ref
        .read(settingsRepositoryProvider)
        .write(AppSettings.aiLabelsEnabled, false);
    await (await _store).remove();
    if (deleteLabels) await resetLabels();
  }
}

@Riverpod(keepAlive: true)
AiLabelsController aiLabelsController(Ref ref) => AiLabelsController(ref);
