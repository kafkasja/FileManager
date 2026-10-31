import 'package:kfm/core/files/file_ref.dart';
import 'package:meta/meta.dart';

/// One zip job run in a worker isolate (TASK-B5). Paths are real local
/// paths (`FileRef.path`); the worker uses dart:io on them.
@immutable
sealed class ArchiveJob {
  const new();
}

final class CompressJob extends ArchiveJob {
  const new({
    required this.sourcePaths,
    required this.rootFolder,
    required this.outputPath,
  });

  /// Files; a folder is expanded (recursively) by the worker.
  final List<String> sourcePaths;

  /// Entry names are relative to it.
  final String rootFolder;
  final String outputPath;
}

final class ExtractJob extends ArchiveJob {
  const new({
    required this.zipPath,
    required this.targetFolder,
    this.entryNames,
    this.password,
  });

  final String zipPath;
  final String targetFolder;

  /// `null` = all entries.
  final Set<String>? entryNames;
  final String? password;
}

@immutable
class ArchiveProgress {
  const new({
    required this.bytesDone,
    required this.bytesTotal,
    this.currentEntry,
  });

  final int bytesDone;
  final int bytesTotal;
  final String? currentEntry;
}

/// Worker result: the final paths it created (files, and dirs for extract).
/// `ArchiveService.run` fills in the flags below.
@immutable
class ArchiveOutput {
  const new({
    required this.files,
    required this.dirs,
    this.undoRecorded = false,
    this.replaceFailed = false,
  });

  final List<String> files;
  final List<String> dirs;

  /// This job's undo is stored in `LastOperationUndo` (offer Undo only then).
  final bool undoRecorded;

  /// Compress with Replace: the old zip couldn't be trashed (declined or
  /// failed), so it stays and the new zip kept its ` (1)` name.
  final bool replaceFailed;
}

/// Sent by the worker when the final move into place starts: from then on
/// the job can't be cancelled (half-moved results would be lost).
const archiveMovingMessage = 'moving';

/// The name in [picked] that selects [entryName]: the entry itself, or a
/// folder above it (`docs/` or `docs` picks `docs/x.txt`). The outermost
/// match wins. Null when not picked. Cost: one set lookup per path level.
String? pickedBy(String entryName, Set<String> picked) {
  for (
    var i = entryName.indexOf('/');
    i >= 0;
    i = entryName.indexOf('/', i + 1)
  ) {
    final folder = entryName.substring(0, i);
    if (picked.contains(folder)) return folder;
    if (picked.contains('$folder/')) return '$folder/';
  }
  return picked.contains(entryName) ? entryName : null;
}

/// One entry of a zip's central directory, for "View contents".
@immutable
class ArchiveEntry {
  const new({
    required this.name,
    required this.size,
    required this.isDirectory,
    this.encrypted = false,
  });

  /// Full entry name inside the zip (`a/b/c.jpg`, folders end with `/`).
  final String name;

  /// Uncompressed size in bytes.
  final int size;
  final bool isDirectory;
  final bool encrypted;
}

/// Entry list plus the sizes the UI needs for the zip-bomb check.
@immutable
class ArchiveListing {
  const new({
    required this.entries,
    required this.zipSize,
    required this.uncompressedTotal,
  });

  final List<ArchiveEntry> entries;
  final int zipSize;
  final int uncompressedTotal;

  /// Over 50× the zip size and over 10 GB: ask before extracting.
  bool get looksLikeBomb => isBombSize(uncompressedTotal);

  /// [looksLikeBomb] for extracting only [picked] (all when null).
  bool looksLikeBombFor(Set<String>? picked) => isBombSize(bytesFor(picked));

  /// Uncompressed bytes an extract of [picked] (all when null) writes.
  int bytesFor(Set<String>? picked) =>
      picked == null ? uncompressedTotal : selectedSize(picked);

  bool isBombSize(int total) => total > zipSize * 50 && total > bombMinBytes;

  /// Uncompressed bytes of the files [picked] selects (all when null).
  int selectedSize(Set<String>? picked) {
    var total = 0;
    for (final e in entries) {
      if (e.isDirectory) continue;
      if (picked == null || pickedBy(e.name, picked) != null) total += e.size;
    }
    return total;
  }

  static const int bombMinBytes = 10 * 1024 * 1024 * 1024;
}

@immutable
sealed class ArchiveError implements Exception {
  const new();
}

final class WrongPassword extends ArchiveError {
  const new();
}

final class PasswordNeeded extends ArchiveError {
  const new();
}

final class CorruptArchive extends ArchiveError {
  const new(this.detail);

  final String detail;
}

final class UnsafeEntryPath extends ArchiveError {
  const new(this.entry);

  final String entry;
}

final class NotEnoughSpace extends ArchiveError {
  const new(this.needed, this.free);

  final int needed;
  final int free;
}

final class ArchiveCancelled extends ArchiveError {
  const new();
}

/// A source file couldn't be read, or the target couldn't be written.
final class ArchiveIoError extends ArchiveError {
  const new(this.path, this.detail);

  final String path;
  final String detail;
}

/// Size and modified time of an extracted file, as written.
@immutable
final class ExtractedStamp {
  const new(this.size, this.modifiedAt);

  factory of(FileRef f) => ExtractedStamp(f.sizeBytes, f.modifiedAt);

  final int size;
  final DateTime modifiedAt;

  /// [f] still has this size and modified time (to the second: MediaStore
  /// keeps seconds).
  bool matches(FileRef f) =>
      f.sizeBytes == size &&
      f.modifiedAt.millisecondsSinceEpoch ~/ 1000 ==
          modifiedAt.millisecondsSinceEpoch ~/ 1000;
}
