import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/app.dart';
import 'package:kfm/core/background/background_scheduler.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_startup_check.dart';
import 'package:kfm/core/diagnostics/error_log.dart';
import 'package:kfm/core/diagnostics/error_log_providers.dart';
import 'package:kfm/core/platform/host_platform.dart';
import 'package:kfm/core/platform/windows/desktop_shell.dart';
import 'package:kfm/core/platform/windows/desktop_shell_provider.dart';
import 'package:kfm/core/platform/windows/media_kit_handle.dart';
import 'package:kfm/features/ai_labels/data/ai_licenses.dart';
import 'package:kfm/features/connect/ui/remote_connection_controller.dart';
import 'package:kfm/features/swipe/ui/video_controller_pool.dart';
import 'package:kfm/features/trash/data/pending_purge_worker.dart';
import 'package:media_kit/media_kit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerAiLicenses();
  // PL1: video on Windows goes through media_kit (libmpv).
  if (isWindowsHost) MediaKit.ensureInitialized();
  // PL1: closing the window goes through the close/tray flow.
  final desktopShell = isWindowsHost ? WindowsDesktopShell() : null;
  await desktopShell?.init();
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
  // Q6: a damaged database file is moved aside before drift opens it, so
  // KFM starts fresh instead of failing every query on every start.
  final dbReport = await checkDatabaseFile(await appDatabaseFile());
  if (dbReport.state != DbStartupState.ok) {
    log
        .record(
          ErrorLogEntry(
            at: DateTime.now().toUtc(),
            source: ErrorSource.db,
            error: 'startup check: ${dbReport.state.name} ${dbReport.detail}',
          ),
        )
        .ignore();
  }
  runApp(
    ProviderScope(
      overrides: [
        errorLogProvider.overrideWithValue(log),
        dbStartupReportProvider.overrideWithValue(dbReport),
        if (Platform.isAndroid)
          backgroundSchedulerProvider.overrideWithValue(
            WorkmanagerScheduler(pendingPurgeDispatcher),
          ),
        if (desktopShell != null)
          desktopShellProvider.overrideWithValue(desktopShell),
        if (isWindowsHost)
          videoHandleFactoryProvider.overrideWith(
            (ref) => mediaKitHandleFactory(
              ref.read(remoteConnectionControllerProvider.notifier).mediaProxy,
            ),
          ),
      ],
      child: const App(),
    ),
  );
}
