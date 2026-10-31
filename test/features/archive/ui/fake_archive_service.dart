import 'package:kfm/core/background/cancel_token.dart';
import 'package:kfm/core/files/file_names.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/archive/data/archive_service.dart';
import 'package:kfm/features/archive/domain/archive_job.dart';

import '../../../core/files/fake_file_source.dart';

/// Scriptable [ArchiveService] for the B5 UI tests: writes outputs into a
/// [FakeFileSource] instead of running a worker.
class FakeArchiveService implements ArchiveService {
  new(this.files);

  final FakeFileSource files;

  /// What [list] returns.
  ArchiveListing listing = const ArchiveListing(
    entries: [
      ArchiveEntry(name: 'a.jpg', size: 1000, isDirectory: false),
      ArchiveEntry(name: 'sub/', size: 0, isDirectory: true),
      ArchiveEntry(name: 'sub/b.txt', size: 20, isDirectory: false),
    ],
    zipSize: 900,
    uncompressedTotal: 1020,
  );

  /// When set, [list] throws it.
  ArchiveError? listError;

  /// When set, [run] throws it (after recording the job).
  ArchiveError? runError;

  /// When set, extract jobs need this password.
  String? password;

  /// What [compressBlockReason] returns.
  String? blockReason;

  /// Called after every successful [run] (tests arm the undo here).
  void Function()? onSuccess;

  final List<ArchiveJob> jobs = [];
  final List<FileRef> trashedForReplace = [];

  @override
  Future<void> get indexSettled async {}

  @override
  Duration get killAfter => const Duration(seconds: 2);

  @override
  Future<ArchiveListing> list(String zipPath) async {
    if (listError case final e?) throw e;
    return listing;
  }

  /// What [destinationBlockReason] returns.
  String? destinationReason;

  /// When true, a Replace's trash "is declined": the new zip keeps a
  /// ` (1)` name and [ArchiveOutput.replaceFailed] is set.
  bool declineReplace = false;

  /// The `replacing` of each [run].
  final List<FileRef?> replacing = [];

  /// Whether [run] reports its undo as recorded.
  bool recordsUndo = true;

  @override
  Future<ArchiveOutput> run(
    ArchiveJob job, {
    required CancelToken cancel,
    void Function(ArchiveProgress)? onProgress,
    FileRef? replacing,
  }) async {
    jobs.add(job);
    this.replacing.add(replacing);
    if (runError case final e?) throw e;
    final ArchiveOutput out;
    switch (job) {
      case CompressJob(:final outputPath):
        onProgress?.call(const ArchiveProgress(bytesDone: 1, bytesTotal: 2));
        var path = outputPath;
        var failed = false;
        if (replacing != null) {
          final (base, ext) = splitExtension(nameOf(outputPath));
          path = '${parentOf(outputPath)}/$base (1)$ext';
          if (declineReplace) {
            failed = true;
          } else {
            await trashForReplace(replacing);
            path = outputPath;
          }
        }
        files.addFile(path);
        out = ArchiveOutput(
          files: [path],
          dirs: const [],
          undoRecorded: recordsUndo,
          replaceFailed: failed,
        );
      case ExtractJob(:final targetFolder, :final entryNames):
        if (password != null) {
          if (job.password == null) throw const PasswordNeeded();
          if (job.password != password) throw const WrongPassword();
        }
        final names = [
          for (final e in listing.entries)
            if (!e.isDirectory &&
                (entryNames == null || pickedBy(e.name, entryNames) != null))
              e.name,
        ];
        final paths = [for (final n in names) '$targetFolder/$n']
          ..forEach(files.addFile);
        out = ArchiveOutput(
          files: paths,
          dirs: [targetFolder],
          undoRecorded: recordsUndo,
        );
    }
    onSuccess?.call();
    return out;
  }

  @override
  Future<String> extractHereTarget(String zipPath) async {
    final folder = parentOf(zipPath);
    final base = splitExtension(nameOf(zipPath)).$1;
    final name = await uniqueName(
      base,
      (n) async => files.files.any(
        (f) =>
            f.folderPath == '$folder/$n' ||
            f.folderPath.startsWith('$folder/$n/'),
      ),
    );
    return '$folder/$name';
  }

  @override
  String? compressBlockReason(List<FileRef> files) => blockReason;

  @override
  String? destinationBlockReason(String folderPath) => destinationReason;

  @override
  Future<void> trashForReplace(FileRef existing) async {
    trashedForReplace.add(existing);
    await files.trashBatch([existing]);
  }
}
