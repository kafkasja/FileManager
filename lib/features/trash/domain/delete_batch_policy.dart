import 'package:meta/meta.dart';

/// Commit during a session once this many deletes are outside the safe zone.
const int kBatchThreshold = 50;

/// When queued deletes may be physically carried out (TASK-D2).
@immutable
class DeleteBatchPolicy {
  const new({this.threshold = kBatchThreshold});

  final int threshold;

  bool shouldCommitDuringSession(int eligibleCount) =>
      eligibleCount >= threshold;
}
