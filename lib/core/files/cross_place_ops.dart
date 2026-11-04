import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:kfm/core/background/file_hasher.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/files/folder_listing.dart';
import 'package:kfm/core/files/io_errors.dart';
import 'package:kfm/core/utils/random_id.dart';

/// The copy's bytes differ from the source's (TASK-U2). The copy was
/// deleted; the source is untouched.
class CopyVerificationException implements Exception {
  const new({required this.expected, required this.actual});

  final String expected;
  final String? actual;

  @override
  String toString() => 'CopyVerificationException($expected != $actual)';
}

/// A copy whose bytes were checked against the source.
typedef VerifiedCopy = ({FileRef copy, String sha256, int sizeBytes});

/// Copy and safe move between places (TASK-U2, rule 10): source → an
/// app-private staging part (native copy-out for SAF/MTP, a file copy for
/// readable paths, else the byte stream) → SHA-256 of the part in a worker
/// isolate → `importFile` on the target → the destination is hashed again
/// (natively for SAF, else in an isolate) and compared. A mismatch deletes
/// the destination and throws [CopyVerificationException]. The part is
/// deleted on success, failure and cancel.
class CrossPlaceOps {
  new({
    required this._sourceOfId,
    required this._sourceOfFolder,
    required this._staging,
    Future<String> Function(String path)? hashFile,
    Future<String> Function(FileRef f, FileSource source)? hashRef,
  }) : _hashFile = hashFile ?? hashFileInIsolate,
       _hashRef = hashRef ?? hashFileRef;

  final FileSource Function(String fileId) _sourceOfId;
  final FileSource Function(String folder) _sourceOfFolder;
  final Future<Directory> Function() _staging;
  final Future<String> Function(String path) _hashFile;
  final Future<String> Function(FileRef f, FileSource source) _hashRef;
  final StreamController<FileIdChange> _idChanges =
      StreamController<FileIdChange>.broadcast();

  /// Moved files (the original is gone, the copy is the file now).
  Stream<FileIdChange> get idChanges => _idChanges.stream;

  /// Announces a finished move so tags, favorites and labels follow it.
  void announceMoved(String oldId, FileRef copy) {
    if (!_idChanges.isClosed) _idChanges.add(FileIdChange(oldId, copy));
  }

  Future<void> dispose() => _idChanges.close();

  /// Staging parts of local jobs (deleted at startup).
  static const partPrefix = 'local-';

  /// Copies [f] into [targetFolder] as [name] (a clash gets ` (1)`) and
  /// verifies it. [partName] is the staging file name (jobs:
  /// `local-<job>-<position>.part`).
  Future<VerifiedCopy> copyVerified(
    FileRef f,
    String targetFolder, {
    String? name,
    String? partName,
    String? mimeType,
    void Function()? onVerifying,
  }) async {
    final source = _sourceOfId(f.id);
    final target = _sourceOfFolder(targetFolder);
    final dir = await _staging();
    final part = File(
      '${dir.path}/${partName ?? '$partPrefix${randomHexId()}.part'}',
    );
    try {
      String? sourceHash;
      try {
        if (source is CopiesOut) {
          sourceHash = await (source as CopiesOut).copyOut(f, part.path);
        } else if (!await _copyByPath(f, part)) {
          await _stream(source, f, part);
        }
      } on FileSystemException catch (e) {
        // Q4: a full disk is `noSpace` (jobs stop instead of failing every
        // remaining file as an I/O error).
        throw fileOpExceptionFromIo(e, part.path, fileId: f.id);
      }
      final size = await part.length();
      // The copy keeps the original's modified time (dart:io imports carry
      // the part's time over; photos without EXIF are dated by it).
      try {
        await part.setLastModified(f.modifiedAt);
      } on FileSystemException catch (e) {
        developer.log('modified time not kept: $e', name: 'kfm.crossPlace');
      }
      sourceHash ??= await _hashFile(part.path);
      onVerifying?.call();
      final copy = await target.importFile(
        part,
        targetFolder: targetFolder,
        name: name ?? f.name,
        mimeType: mimeType ?? f.mimeType,
      );
      String? copyHash;
      try {
        copyHash = target is HashesNatively
            ? await (target as HashesNatively).sha256Of(copy)
            : await _hashRef(copy, target);
      } on Object catch (e) {
        developer.log('copy not readable: $e', name: 'kfm.crossPlace');
      }
      if (copyHash != sourceHash) {
        await _deleteQuietly(target, copy);
        throw CopyVerificationException(expected: sourceHash, actual: copyHash);
      }
      return (copy: copy, sha256: sourceHash, sizeBytes: size);
    } finally {
      try {
        if (await part.exists()) await part.delete();
      } on FileSystemException catch (e) {
        developer.log('part not deleted: $e', name: 'kfm.crossPlace');
      }
    }
  }

  /// A single-file copy (`FileSource.copy` across places).
  Future<FileRef> copy(FileRef f, String targetFolder) async =>
      (await _verified(f, targetFolder)).copy;

  /// A single-file safe move (`FileSource.move` across places): copy →
  /// verify → the original goes to the trash (restorable). A declined
  /// trash dialog deletes the copy again and throws `userCancelled`.
  Future<FileRef> move(FileRef f, String targetFolder) async {
    final done = await _verified(f, targetFolder);
    final source = _sourceOfId(f.id);
    final result = await source.trashBatch([f]);
    if (result.trashed.isEmpty) {
      await _deleteQuietly(_sourceOfFolder(targetFolder), done.copy);
      throw result.failed[f.id] ??
          FileOpException(
            FileOpFailure.userCancelled,
            'original not trashed',
            fileId: f.id,
          );
    }
    announceMoved(f.id, done.copy);
    return done.copy;
  }

  Future<VerifiedCopy> _verified(FileRef f, String targetFolder) async {
    try {
      return await copyVerified(f, targetFolder);
    } on CopyVerificationException catch (e) {
      throw FileOpException(
        FileOpFailure.ioError,
        'verification failed: $e',
        fileId: f.id,
      );
    }
  }

  /// True when [f] has a readable dart:io path and was copied with it.
  static Future<bool> _copyByPath(FileRef f, File part) async {
    if (!f.path.startsWith('/')) return false;
    final file = File(f.path);
    try {
      if (!await file.exists()) return false;
      await file.copy(part.path);
      return true;
    } on FileSystemException catch (e) {
      // A full disk fails the stream the same way: don't copy twice.
      if (fileOpExceptionFromIo(e, part.path).failure ==
          FileOpFailure.noSpace) {
        rethrow;
      }
      return false; // scoped storage: read through the source
    }
  }

  static Future<void> _stream(FileSource source, FileRef f, File part) async {
    final sink = part.openWrite();
    try {
      await sink.addStream(source.openRead(f));
      await sink.flush();
    } on Object {
      // Q4: closing after a failed write throws "File closed", which used
      // to replace the real error (a full disk became a plain I/O error).
      try {
        await sink.close();
      } on Object catch (e) {
        developer.log('part not closed: $e', name: 'kfm.crossPlace');
      }
      rethrow;
    }
    await sink.close();
  }

  static Future<void> _deleteQuietly(FileSource target, FileRef copy) async {
    try {
      await target.deletePermanentlyBatch([copy]);
    } on Object catch (e) {
      developer.log('bad copy not deleted: $e', name: 'kfm.crossPlace');
    }
  }
}
