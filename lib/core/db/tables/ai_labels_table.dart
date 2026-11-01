import 'package:drift/drift.dart';

/// The label C5's Documents group matches on images (TASK-C3 §2).
const String kDocumentLabel = 'document';

/// Stored by name: APPEND ONLY.
enum AiLabelOutcome { labeled, failed }

/// KFM labels per image (TASK-C3). No FK to media_index: its applyIdChange
/// is delete + insert, so a cascade would erase labels. Orphans are removed
/// by the job; ids are re-keyed by FileIdRekeyer.
@DataClassName('AiLabelRow')
@TableIndex(name: 'ai_labels_label', columns: {#label, #fileId})
class AiLabels extends Table {
  TextColumn get fileId => text()();

  /// Lowercase vocabulary label, e.g. 'cat', 'color:blue'.
  TextColumn get label => text().withLength(min: 1, max: 64)();
  RealColumn get confidence => real()();

  @override
  Set<Column<Object>> get primaryKey => {fileId, label};

  @override
  List<String> get customConstraints => ['CHECK (confidence BETWEEN 0 AND 1)'];
}

/// One row per processed image, also with zero labels or a failure, so no
/// file is processed twice for the same (model, file version).
@DataClassName('AiLabelStatusRow')
class AiLabelStatus extends Table {
  TextColumn get fileId => text()();
  TextColumn get outcome => textEnum<AiLabelOutcome>()();

  /// LabelingJob.modelVersion (bumped when a model or label_map changes).
  IntColumn get modelVersion => integer()();

  /// media_index.modifiedAtMs when processed (epoch ms, same unit).
  IntColumn get fileModifiedAtMs => integer()();
  IntColumn get attempts => integer().withDefault(const Constant(1))();

  /// Short reason for `failed` (exception type + message, ≤ 200 chars).
  TextColumn get error => text().nullable()();

  /// Epoch ms (drift's DateTime stores seconds).
  IntColumn get processedAtMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {fileId};
}
