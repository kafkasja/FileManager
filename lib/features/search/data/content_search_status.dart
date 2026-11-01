import 'package:kfm/features/ai_labels/data/ai_labels_providers.dart';
import 'package:kfm/features/ai_labels/data/ai_labels_repository.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'content_search_status.g.dart';

/// What content (AI label) search can do right now (TASK-C4 §3).
@immutable
class ContentSearchStatus {
  const new({
    required this.labelingOn,
    required this.canTurnOn,
    required this.progress,
  });

  /// Still loading: labels are queried, no banner or hint yet.
  static const loading = ContentSearchStatus(
    labelingOn: null,
    canTurnOn: false,
    progress: null,
  );

  /// C3's `aiLabelsEnabled` (only true while the models are installed: C3
  /// turns it off when they're missing). Null = not loaded yet.
  final bool? labelingOn;

  /// Labeling can run on this device (API 26+, a runtime).
  final bool canTurnOn;

  /// C3's progress; null = not loaded yet.
  final LabelingProgress? progress;

  /// Label words become `ai_labels` terms: labeling is on, or labels from
  /// before exist (C3 keeps them when the models are removed). Otherwise
  /// they're searched as names, so no false "no results".
  bool get queriesLabels =>
      labelingOn != false || (progress?.processed ?? 1) > 0;

  /// "Turn on photo labeling to search by content".
  bool get showTurnOn => labelingOn == false && canTurnOn;

  /// "Still labeling photos (63%)".
  bool get showStillLabeling =>
      labelingOn == true && progress != null && progress!.fraction < 1;

  @override
  bool operator ==(Object other) =>
      other is ContentSearchStatus &&
      other.labelingOn == labelingOn &&
      other.canTurnOn == canTurnOn &&
      other.progress == progress;

  @override
  int get hashCode => Object.hash(labelingOn, canTurnOn, progress);
}

@riverpod
ContentSearchStatus contentSearchStatus(Ref ref) => ContentSearchStatus(
  labelingOn: ref.watch(aiLabelsEnabledProvider).value,
  canTurnOn: ref.watch(aiSupportProvider).value == AiSupport.supported,
  progress: ref.watch(labelingProgressProvider).value,
);
