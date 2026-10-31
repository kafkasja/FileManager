import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/file_op_messages.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/background/cancel_token.dart';
import 'package:kfm/core/files/file_names.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/platform/permissions/ensure_all_files_access.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/features/archive/data/archive_service.dart';
import 'package:kfm/features/archive/domain/archive_job.dart';
import 'package:kfm/features/archive/ui/compress_dialog.dart';
import 'package:kfm/features/archive/ui/password_dialog.dart';
import 'package:kfm/features/browse/ui/widgets/browse_parts.dart';
import 'package:kfm/features/folders/domain/file_operation.dart';
import 'package:kfm/features/folders/ui/collision_dialog.dart';
import 'package:kfm/features/folders/ui/file_op_flow.dart';
import 'package:kfm/features/folders/ui/folder_picker_sheet.dart';
import 'package:kfm/features/folders/ui/operation_progress_sheet.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// Where "Extract" puts a zip's entries (TASK-B5).
enum ExtractDestination {
  /// A new folder named after the zip, next to it (`photos.zip` →
  /// `photos/`, clash → `photos (1)/`).
  here,

  /// A folder the user picks; clashes get ` (1)`.
  chooseFolder,

  /// The zip's own folder (long-press "Extract this" in the archive view).
  zipFolder,
}

/// Whether [f] is a zip KFM can open (other archive types are out of scope).
bool isZipFile(FileRef f) =>
    f.kind == FileKind.archive && f.name.toLowerCase().endsWith('.zip');

/// Selection → Compress: zips [files] (entry names relative to their
/// common folder) into a zip in the first file's folder by default.
Future<void> compressFiles(
  BuildContext context,
  WidgetRef ref,
  List<FileRef> files,
) async {
  if (files.isEmpty) return;
  if (!await ensureAllFilesAccess(context, ref) || !context.mounted) return;
  final host = _ArchiveHost(context);
  if (host.service.compressBlockReason(files) != null) {
    host.show(host.l10n.archiveWrongPlace);
    return;
  }
  await host.compress(
    sourcePaths: [for (final f in files) f.path],
    rootFolder: commonFolderOf([for (final f in files) f.folderPath]),
    defaultName: defaultZipName(files.first.name),
    defaultFolder: files.first.folderPath,
  );
}

/// Folder ⋮ → Compress: the folder's whole tree (entry names start with
/// the folder's name), saved next to the folder by default.
Future<void> compressFolder(
  BuildContext context,
  WidgetRef ref,
  FolderEntry folder,
) async {
  if (!await ensureAllFilesAccess(context, ref) || !context.mounted) return;
  final host = _ArchiveHost(context);
  if (host.service.compressBlockReason([folderAsFileRef(folder.path)]) !=
      null) {
    host.show(host.l10n.archiveWrongPlace);
    return;
  }
  final parent = parentOf(folder.path);
  await host.compress(
    sourcePaths: [folder.path],
    rootFolder: parent,
    defaultName: defaultZipName(folder.name, isFolder: true),
    defaultFolder: parent,
  );
}

/// Extracts [zip] (all entries, or only [entries]) to [destination].
/// [listing]: when the caller already has it (the archive view).
Future<void> extractZip(
  BuildContext context,
  WidgetRef ref,
  FileRef zip, {
  required ExtractDestination destination,
  Set<String>? entries,
  ArchiveListing? listing,
}) async {
  if (!await ensureAllFilesAccess(context, ref) || !context.mounted) return;
  await _ArchiveHost(
    context,
  ).extract(zip, destination: destination, entries: entries, listing: listing);
}

/// The deepest folder that contains all of [folders].
String commonFolderOf(List<String> folders) {
  var common = folders.first.split('/');
  for (final f in folders.skip(1)) {
    final parts = f.split('/');
    var i = 0;
    while (i < common.length && i < parts.length && common[i] == parts[i]) {
      i++;
    }
    common = common.sublist(0, i);
  }
  final joined = common.join('/');
  return joined.isEmpty ? '/' : joined;
}

/// A stand-in [FileRef] for a folder, for `compressBlockReason`.
FileRef folderAsFileRef(String path) => FileRef(
  id: 'path:$path',
  uri: path,
  name: nameOf(path),
  kind: FileKind.other,
  sizeBytes: 0,
  modifiedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  folderPath: parentOf(path),
  origin: ArchiveService.isInternalStoragePath(path)
      ? FileOrigin.local
      : FileOrigin.external,
);

/// The snackbar text for an [ArchiveError].
String archiveErrorMessage(AppLocalizations l, ArchiveError e) => switch (e) {
  WrongPassword() => l.archiveWrongPassword,
  PasswordNeeded() => l.archivePasswordTitle,
  CorruptArchive() => l.archiveCorrupt,
  UnsafeEntryPath() => l.archiveUnsafePaths,
  NotEnoughSpace(:final needed, :final free) => spaceRefusedMessage(
    l,
    needed: needed,
    free: free,
  ),
  ArchiveCancelled() => l.archiveCancelled,
  ArchiveIoError(:final path) => l.archiveIoError(nameOf(path)),
};

/// Handles that outlive the menu or screen that started the job.
class _ArchiveHost {
  new(BuildContext context)
    : _navigator = Navigator.of(context, rootNavigator: true),
      container = ProviderScope.containerOf(context, listen: false),
      messenger = ScaffoldMessenger.of(context),
      l10n = context.l10n;

  final NavigatorState _navigator;
  final ProviderContainer container;
  final ScaffoldMessengerState messenger;
  final AppLocalizations l10n;

  ArchiveService get service => container.read(archiveServiceProvider);

  BuildContext? get context => _navigator.mounted ? _navigator.context : null;

  void show(String text, {bool undo = false}) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(text),
        duration: opSnackBarDuration,
        persist: false,
        action: undo
            ? SnackBarAction(
                label: l10n.undoAction,
                onPressed: () {
                  final c = context;
                  if (c != null) unawaited(undoLastFileOperation(c));
                },
              )
            : null,
      ),
    );

  Future<void> compress({
    required List<String> sourcePaths,
    required String rootFolder,
    required String defaultName,
    required String defaultFolder,
  }) async {
    var c = context;
    if (c == null) return;
    final target = await showCompressDialog(
      c,
      initialName: defaultName,
      initialFolder: defaultFolder,
    );
    if (target == null) return;
    if (service.destinationBlockReason(target.folder) != null) {
      show(l10n.archiveWrongDestination);
      return;
    }
    final files = container.read(fileSourceProvider);
    var name = target.name;
    Future<String> keepBoth() => uniqueName(
      name,
      (n) async => await files.statPath('${target.folder}/$n') != null,
    );
    try {
      FileRef? replacing;
      final existing = await files.statPath('${target.folder}/$name');
      if (existing != null && _isSource(existing.path, sourcePaths)) {
        // `backup.zip` selected and zipped as `backup.zip`: replacing it
        // would trash a source. No question, just a free name.
        name = await keepBoth();
      } else if (existing != null) {
        c = context;
        if (c == null || !c.mounted) return;
        final (choice, _) = await showCollisionDialog(
          c,
          incoming: existing,
          existing: existing,
          showApplyToAll: false,
        );
        switch (choice) {
          case CollisionChoice.skip:
            return;
          case CollisionChoice.replace:
            // Trashed by the service only once the new zip is written.
            replacing = existing;
          case CollisionChoice.keepBoth:
            name = await keepBoth();
        }
      }
      final out = await _run(
        CompressJob(
          sourcePaths: sourcePaths,
          rootFolder: rootFolder,
          outputPath: '${target.folder}/$name',
        ),
        ProgressLabel.compressing,
        replacing: replacing,
      );
      final created = out.files.isEmpty ? name : nameOf(out.files.first);
      if (out.replaceFailed) {
        show(l10n.archiveReplaceFailed(created), undo: out.undoRecorded);
      } else {
        show(l10n.archiveCreated(created), undo: out.undoRecorded);
      }
    } on ArchiveError catch (e) {
      show(archiveErrorMessage(l10n, e));
    } on FileOpException catch (e) {
      show(
        e.failure == FileOpFailure.userCancelled
            ? l10n.fileOpDeclined
            : l10n.fileOpFailedGeneric(name),
      );
    }
  }

  /// [path] is one of [sources] or inside one of them.
  static bool _isSource(String path, List<String> sources) =>
      sources.any((s) => path == s || path.startsWith('$s/'));

  Future<void> extract(
    FileRef zip, {
    required ExtractDestination destination,
    Set<String>? entries,
    ArchiveListing? listing,
  }) async {
    if (service.compressBlockReason([zip]) != null) {
      show(l10n.archiveWrongPlace);
      return;
    }
    try {
      final list = listing ?? await service.list(zip.path);
      // Also for "Extract this": the selected entries' total counts.
      if (list.looksLikeBombFor(entries) &&
          !await _confirmBomb(list, entries)) {
        return;
      }
      final String target;
      switch (destination) {
        case ExtractDestination.here:
          target = await service.extractHereTarget(zip.path);
        case ExtractDestination.zipFolder:
          target = zip.folderPath;
        case ExtractDestination.chooseFolder:
          final c = context;
          if (c == null || !c.mounted) return;
          final picked = await showFolderPicker(
            c,
            title: l10n.archiveExtractToTitle,
          );
          if (picked == null) return;
          if (service.destinationBlockReason(picked) != null) {
            show(l10n.archiveWrongDestination);
            return;
          }
          target = picked;
      }
      ExtractJob job([String? password]) => ExtractJob(
        zipPath: zip.path,
        targetFolder: target,
        entryNames: entries,
        password: password,
      );
      ArchiveOutput? out;
      try {
        out = await _run(job(), ProgressLabel.extracting);
      } on PasswordNeeded {
        final c = context;
        if (c == null || !c.mounted) return;
        out = await showPasswordDialog<ArchiveOutput>(
          c,
          zipName: zip.name,
          attempt: (password) => _run(job(password), ProgressLabel.extracting),
        );
      }
      if (out == null) return;
      show(
        l10n.archiveExtracted(out.files.length, nameOfFolder(l10n, target)),
        undo: out.undoRecorded,
      );
    } on ArchiveError catch (e) {
      show(archiveErrorMessage(l10n, e));
    }
  }

  Future<ArchiveOutput> _run(
    ArchiveJob job,
    ProgressLabel label, {
    FileRef? replacing,
  }) async {
    final cancel = CancelToken();
    final c = context;
    if (c == null) {
      return await service.run(job, cancel: cancel, replacing: replacing);
    }
    return await showOperationProgress(
      c,
      label: label,
      cancel: cancel,
      task: (onProgress) => service.run(
        job,
        cancel: cancel,
        replacing: replacing,
        onProgress: (p) => onProgress(
          OperationProgress(
            done: 0,
            total: 1,
            bytesDone: p.bytesDone,
            bytesTotal: p.bytesTotal,
            current: p.currentEntry,
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmBomb(ArchiveListing listing, Set<String>? picked) async {
    final c = context;
    if (c == null) return false;
    final ok = await showDialog<bool>(
      context: c,
      builder: (context) => AlertDialog(
        title: Text(l10n.archiveBombTitle),
        content: Text(
          l10n.archiveBombBody(
            formatBytes(listing.bytesFor(picked), locale: l10n.localeName),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.archiveBombAction),
          ),
        ],
      ),
    );
    return ok ?? false;
  }
}
