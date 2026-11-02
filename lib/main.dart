import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/app.dart';
import 'package:kfm/core/background/background_scheduler.dart';
import 'package:kfm/core/diagnostics/error_log.dart';
import 'package:kfm/core/diagnostics/error_log_providers.dart';
import 'package:kfm/features/ai_labels/data/ai_licenses.dart';
import 'package:kfm/features/trash/data/pending_purge_worker.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerAiLicenses();
  // H5: errors also go to the on-device log (opened lazily on the first
  // write, so startup doesn't wait for it).
  final log = ErrorLog.current = ErrorLog.main(errorLogDirectory);
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    log
        .record(
          ErrorLogEntry(
            at: DateTime.now().toUtc(),
            source: ErrorSource.flutter,
            error: details.exceptionAsString(),
            stack: details.stack,
          ),
        )
        .ignore();
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    log
        .record(
          ErrorLogEntry(
            at: DateTime.now().toUtc(),
            source: ErrorSource.platform,
            error: error.toString(),
            stack: stack,
          ),
        )
        .ignore();
    return false; // the engine still prints it to logcat
  };
  runApp(
    ProviderScope(
      overrides: [
        errorLogProvider.overrideWithValue(log),
        if (Platform.isAndroid)
          backgroundSchedulerProvider.overrideWithValue(
            WorkmanagerScheduler(pendingPurgeDispatcher),
          ),
      ],
      child: const App(),
    ),
  );
}
