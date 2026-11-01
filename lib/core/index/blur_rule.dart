import 'package:drift/drift.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/tables/image_signals_table.dart';

/// TASK-C2. The one blurry rule: the Blurry tab and C4's `blurry` search use
/// it; nobody copies the threshold. [threshold] is
/// `AppSettings.similarBlurThreshold` (callers read it and pass it in).
bool isBlurry(double blurScore, int threshold) => blurScore < threshold;

/// Same rule in SQL over image_signals (status ok only).
Expression<bool> blurryPredicate($ImageSignalsTable s, int threshold) =>
    s.status.equalsValue(SignalStatus.ok) &
    s.blurScore.isSmallerThanValue(threshold.toDouble());
