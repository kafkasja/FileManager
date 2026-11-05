import 'dart:developer' as developer;

import 'package:kfm/core/diagnostics/error_log.dart';
import 'package:meta/meta.dart';

/// TASK-E1: a finished transfer's `TransferStats` summary goes to the
/// debug log and the on-device H5 log (no names or paths), so a slow
/// transfer can be explained from the phone's log export.
void logTransferStats(String summary) {
  developer.log(summary, name: 'kfm.transfers.stats');
  debugOnTransferStats?.call(summary);
  ErrorLog.current
      ?.record(
        ErrorLogEntry(
          at: DateTime.now(),
          source: ErrorSource.isolate,
          error: '[transfer stats] $summary',
        ),
      )
      .ignore();
}

/// Test hook (the throughput test prints the summaries).
@visibleForTesting
void Function(String summary)? debugOnTransferStats;
