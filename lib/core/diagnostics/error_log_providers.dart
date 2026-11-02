import 'dart:io';

import 'package:kfm/app/app_info.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/diagnostics/error_log.dart';
import 'package:kfm/core/files/android/files_channel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'error_log_providers.g.dart';

/// `<app support>/logs` (Android `filesDir/logs`; the FileProvider serves
/// only its `export/` folder).
Future<Directory> errorLogDirectory() async =>
    Directory('${(await getApplicationSupportDirectory()).path}/logs');

/// H5: the UI isolate's error log. `main` sets [ErrorLog.current] (and
/// overrides this); without it (tests) nothing is recorded.
@Riverpod(keepAlive: true)
ErrorLog errorLog(Ref ref) => ErrorLog.current ?? ErrorLog.disabled();

/// H5: failed queued writes go to the log too (the banner still shows
/// them). Watched in `App.build` (Riverpod 3 pauses unwatched providers).
@Riverpod(keepAlive: true)
void errorLogDbBridge(Ref ref) {
  final log = ref.watch(errorLogProvider);
  ref.listen(dbWriteErrorsProvider, (_, next) {
    final e = next.value;
    if (e == null) return;
    log
        .record(
          ErrorLogEntry(
            at: DateTime.now().toUtc(),
            source: ErrorSource.db,
            error: 'write ${e.coalesceKey ?? '(ordered)'}: ${e.error}',
            stack: e.stackTrace,
          ),
        )
        .ignore();
  });
}

/// Entries in the log, for Settings → About.
@riverpod
Future<int> errorLogCount(Ref ref) => ref.watch(errorLogProvider).entryCount();

/// Device facts for the export header (no serial, Android ID or account).
@riverpod
Future<ExportHeader> errorLogExportHeader(Ref ref) async {
  final db = ref.watch(appDatabaseProvider);
  int? sdk;
  String? model;
  if (Platform.isAndroid) {
    final channel = FilesChannel();
    try {
      sdk = await channel.sdkInt();
      model = await channel.deviceModel();
    } on Object {
      // Header facts are optional; the log itself is what matters.
    }
  }
  return ExportHeader(
    appVersion: appVersion,
    buildNumber: appBuildNumber,
    sdkInt: sdk,
    deviceModel: model,
    locale: Platform.localeName,
    schemaVersion: db.schemaVersion,
  );
}

/// Opens the share sheet for an export file. False = nothing could share it.
typedef ErrorLogSharer = Future<bool> Function(File file, String subject);

@Riverpod(keepAlive: true)
ErrorLogSharer errorLogSharer(Ref ref) => (file, subject) async {
  if (!Platform.isAndroid) return false;
  return await FilesChannel().shareFile(
    path: file.path,
    mime: 'text/plain',
    subject: subject,
  );
};
