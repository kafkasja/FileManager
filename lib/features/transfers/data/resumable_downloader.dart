import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:kfm/core/db/app_database.dart' show TransferFilesCompanion;
import 'package:kfm/core/files/file_names.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/features/connect/data/pinned_client.dart';
import 'package:kfm/features/connect/data/remote_errors.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:kfm/features/connect/domain/remote_file_id.dart';
import 'package:kfm/features/connect/domain/upload_protocol.dart';
import 'package:kfm/features/transfers/data/transfer_run.dart';
import 'package:kfm/features/transfers/domain/transfer_job.dart';

/// How long the other device may take to hash a file for
/// `GET /v1/files/<id>/sha256`.
const Duration kSenderHashTimeout = Duration(minutes: 10);

/// `<staging>/dl-<transferFileId>.part`.
File downloadPartOf(Directory staging, int transferFileId) =>
    File('${staging.path}/dl-$transferFileId.part');

/// Downloads one file of a job with resume (TASK-N10): the local part's
/// length is the truth; the request asks `Range: bytes=<length>-` with
/// `If-Range: <etag>`. 206 appends, 200 (the file changed, or no ranges)
/// starts the part over. After the last byte the sender's hash is fetched
/// (best effort) and the part is published with `importFile`.
class ResumableDownloader {
  new({
    required this._local,
    required this._staging,
    required this._save,
    required this._addToIndex,
  });

  final FileSource _local;
  final Future<Directory> Function() _staging;

  /// Writes fields of a transfer file (uploadId, etag, hashes).
  final Future<void> Function(int fileId, TransferFilesCompanion row) _save;
  final Future<void> Function(List<FileRef> files) _addToIndex;

  /// Bytes of [fileId]'s part (0 when none): where a resume starts.
  Future<int> partLength(int fileId) async {
    final part = downloadPartOf(await _staging(), fileId);
    return await part.exists() ? await part.length() : 0;
  }

  /// Deletes [fileId]'s part (cancel, a permanent failure).
  Future<void> discard(int fileId) async {
    try {
      final part = downloadPartOf(await _staging(), fileId);
      if (await part.exists()) await part.delete();
    } on FileSystemException catch (e) {
      developer.log('partial not deleted: $e', name: 'kfm.transfers');
    }
  }

  /// Returns the new local file id.
  Future<String> run(TransferRun run, RemoteHttp http) async {
    final f = run.file;
    final job = run.job;
    validateFileName(f.name);
    final serverId = parseRemoteFileId(f.sourceFileId).serverId;
    final dir = await _staging();
    final part = downloadPartOf(dir, f.id);
    var have = await part.exists() ? await part.length() : 0;
    // Without a validator a part can't be trusted: start over.
    if (have > 0 && f.etag == null) have = 0;
    final free = await _local.freeBytes(dir.path);
    if (free != null && free < f.sizeBytes - have + kTransferSpaceMarginBytes) {
      throw const TransferFailure(TransferErrors.noSpaceHere);
    }
    HttpClientResponse res;
    try {
      res = await http.getStream(
        ApiRoutes.fileContent(serverId),
        headers: have > 0
            ? {
                HttpHeaders.rangeHeader: 'bytes=$have-',
                HttpHeaders.ifRangeHeader: f.etag!,
              }
            : const {},
      );
    } on RemoteApiException catch (e) {
      // 416: the part is longer than the file is now.
      if (e.status != 416 || have == 0) rethrow;
      have = 0;
      res = await http.getStream(ApiRoutes.fileContent(serverId));
    }
    if (run.stopped) {
      unawaited(res.listen(null).cancel());
      throw const TransferStopped();
    }
    final etag = res.headers.value(HttpHeaders.etagHeader);
    final resumed =
        res.statusCode == HttpStatus.partialContent &&
        have > 0 &&
        _rangeStart(res.headers.value(HttpHeaders.contentRangeHeader)) == have;
    if (res.statusCode == HttpStatus.partialContent && !resumed) {
      // A range we didn't ask for: never stitched; the next try starts over.
      unawaited(res.listen(null).cancel());
      await discard(f.id);
      throw const TransferFailure(TransferErrors.incomplete);
    }
    if (etag != f.etag) {
      await _save(f.id, TransferFilesCompanion(etag: Value(etag)));
    }
    final base = resumed ? have : 0;
    final total = res.contentLength >= 0 ? base + res.contentLength : null;
    run
      ..confirmed = base
      ..progress(base);
    final raf = await part.open(
      mode: resumed ? FileMode.append : FileMode.write,
    );
    try {
      await pipeToFile(run, res, raf);
    } finally {
      try {
        await raf.flush();
      } on FileSystemException catch (e) {
        developer.log('partial not flushed: $e', name: 'kfm.transfers');
      }
      await raf.close();
    }
    if (run.stopped) throw const TransferStopped();
    if (total != null && run.confirmed != total) {
      throw const TransferFailure(TransferErrors.incomplete);
    }
    final sha = await _senderHash(http, serverId);
    if (run.stopped) throw const TransferStopped();
    final ref = await _local.importFile(
      part,
      targetFolder: job.targetPath,
      name: f.name,
    );
    // `importFile` may copy: no part stays behind.
    await discard(f.id);
    if (sha != null) {
      await _save(f.id, TransferFilesCompanion(senderSha256: Value(sha)));
    }
    unawaited(
      _addToIndex([ref]).catchError(
        (Object e) => developer.log(
          'downloaded file not indexed: $e',
          name: 'kfm.transfers',
        ),
      ),
    );
    return ref.id;
  }

  /// The sender's SHA-256 (N11 compares it); null when the other device
  /// can't tell (older version, unreadable) — logged, never fatal.
  Future<String?> _senderHash(RemoteHttp http, String serverId) async {
    try {
      final dto = await http.getJson(
        ApiRoutes.fileSha256(serverId),
        decode: FileSha256Dto.fromJson,
        timeout: kSenderHashTimeout,
      );
      return dto.sha256;
    } on Object catch (e) {
      developer.log('sender hash unavailable: $e', name: 'kfm.transfers');
      return null;
    }
  }
}

/// The first byte of a `Content-Range: bytes a-b/n` header; null if none.
int? _rangeStart(String? header) {
  if (header == null) return null;
  final m = RegExp(r'^\s*bytes\s+(\d+)-').firstMatch(header);
  return m == null ? null : int.tryParse(m.group(1)!);
}
