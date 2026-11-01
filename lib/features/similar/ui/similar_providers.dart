import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;
import 'package:kfm/core/background/in_app_jobs.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/similar/data/similar_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'similar_providers.g.dart';

/// Whether the finder is on (TASK-C2, off by default).
@riverpod
Stream<bool> similarEnabled(Ref ref) =>
    ref.watch(settingsRepositoryProvider).watch(AppSettings.similarEnabled);

@riverpod
Stream<String> similarStrictness(Ref ref) =>
    ref.watch(settingsRepositoryProvider).watch(AppSettings.similarStrictness);

@riverpod
Stream<bool> similarIncludeScreenshots(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watch(AppSettings.similarIncludeScreenshots);

@riverpod
Stream<List<SimilarGroup>> similarGroups(Ref ref) =>
    ref.watch(similarRepositoryProvider).watchGroups();

@riverpod
Stream<int> similarBlurThreshold(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watch(AppSettings.similarBlurThreshold);

@riverpod
Stream<List<FileRef>> similarBlurry(Ref ref) async* {
  final threshold = await ref.watch(similarBlurThresholdProvider.future);
  yield* ref.watch(similarRepositoryProvider).watchBlurry(threshold: threshold);
}

/// Starts a scan run now (the runner otherwise picks it up when idle).
void kickSimilarScan(WidgetRef ref) => ref.read(inAppJobRunnerProvider).kick();
