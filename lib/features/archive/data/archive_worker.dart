import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive_io.dart'
    show
        ArchiveException,
        CompressionType,
        InputFileStream,
        InputStream,
        OutputFileStream,
        ZipDecoder,
        ZipFile,
        ZipFileHeader,
        getCrc32;
// WinZip AES (CTR + HMAC-SHA1) of the pinned archive 4.5.x: not exported,
// but the only way to check an entry's authentication code (below).
// ignore: implementation_imports
import 'package:archive/src/util/aes.dart' show Aes;
import 'package:kfm/core/files/file_names.dart';
import 'package:kfm/core/files/system_files.dart';
import 'package:kfm/features/archive/data/zip_writer.dart';
import 'package:kfm/features/archive/domain/archive_job.dart';
import 'package:kfm/features/archive/domain/safe_paths.dart';
import 'package:meta/meta.dart';

/// Zip work for one job, run in its own isolate (TASK-B5). Streaming only:
/// file data never sits in memory as a whole, so a 4 GB video zips with
/// constant memory. Uses async dart:io on real local paths (see the plan's
/// Rules), so the isolate's event loop runs between chunks and a cancel
/// lands within about a megabyte, also inside one large entry.
///
/// Compress uses our own [ZipWriter]. Extract reads the central directory
/// with archive 4.x (`ZipDecoder.decodeStream` + `.directory.fileHeaders`:
/// `ZipFileHeader.generalPurposeBitFlag/compressionMethod/versionMadeBy/
/// externalFileAttributes/localHeaderOffset/compressedSize/crc32/
/// uncompressedSize/extraField/file`), then reads stored, deflated and
/// AES-encrypted entry data itself (async reads, dart:io's chunked raw
/// `ZLibDecoder`, archive's `Aes` for CTR + the HMAC check). ZipCrypto
/// entries are decrypted by `ZipFile.getStream(decompress: false)`;
/// bzip2 / zstd use `ZipFile.decompress(OutputFileStream)`.

/// Reads a zip's central directory (no file data). Sent to the worker by
/// `ArchiveService.list`.
@immutable
final class ListRequest {
  const new(this.zipPath);

  final String zipPath;
}

/// What the service hands the isolate: `request` is a [ListRequest] or an
/// [ArchiveJob]; `tempPath` is where a job writes before its final rename
/// (already in the temp ledger); `reply` gets, in order: the worker's
/// command [SendPort], any number of [ArchiveProgress], for a job
/// [archiveMovingMessage] when the move into place starts, then one result
/// ([ArchiveListing], [ArchiveOutput]) or an [ArchiveError].
typedef ArchiveWorkerArgs = ({
  Object request,
  String? tempPath,
  SendPort reply,
});

/// Sent on the worker's command port to stop the job.
const archiveCancelCommand = 'cancel';

/// Isolate entry point.
Future<void> archiveWorkerMain(ArchiveWorkerArgs args) async {
  final commands = ReceivePort();
  var cancelled = false;
  commands.listen((m) {
    if (m == archiveCancelCommand) cancelled = true;
  });
  args.reply.send(commands.sendPort);
  bool isCancelled() => cancelled;
  void moving() => args.reply.send(archiveMovingMessage);
  try {
    final result = switch (args.request) {
      ListRequest(:final zipPath) => listArchive(zipPath),
      final CompressJob job => await compressArchive(
        job,
        tempPath: args.tempPath!,
        isCancelled: isCancelled,
        onProgress: args.reply.send,
        onMoving: moving,
      ),
      final ExtractJob job => await extractArchive(
        job,
        tempPath: args.tempPath!,
        isCancelled: isCancelled,
        onProgress: args.reply.send,
        onMoving: moving,
      ),
      final other => throw ArgumentError('unknown request $other'),
    };
    args.reply.send(result);
  } on ArchiveError catch (e) {
    args.reply.send(e);
  } on Object catch (e) {
    args.reply.send(ArchiveIoError('', '$e'));
  } finally {
    commands.close();
  }
}

// ---------------------------------------------------------------- list ---

/// The entries of the zip at [zipPath]. Throws [CorruptArchive].
ArchiveListing listArchive(String zipPath) {
  final zip = _OpenZip.open(zipPath, password: null);
  try {
    var total = 0;
    final entries = <ArchiveEntry>[
      for (final e in zip.entries)
        ArchiveEntry(
          name: e.name,
          size: e.size,
          isDirectory: e.isDirectory,
          encrypted: e.encrypted,
        ),
    ];
    for (final e in entries) {
      total += e.size;
    }
    return ArchiveListing(
      entries: List.unmodifiable(entries),
      zipSize: zip.length,
      uncompressedTotal: total,
    );
  } finally {
    zip.close();
  }
}

// ------------------------------------------------------------ compress ---

/// Extensions stored without compression (already compressed).
const Set<String> storedExtensions = {
  'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'mp4', 'mov', 'mkv', //
  'mp3', 'm4a', 'zip', '7z', 'rar', 'apk',
};

/// Whether [name] is stored rather than deflated.
bool isStoredName(String name) {
  final ext = splitExtension(name).$2;
  return ext.isNotEmpty &&
      storedExtensions.contains(ext.substring(1).toLowerCase());
}

/// Zips [job]'s sources into [tempPath], then renames it to
/// `job.outputPath` (or `name (1).zip` if that appeared meanwhile). On any
/// failure or cancel the temp file is removed. [onMoving] is called right
/// before the rename: no cancel is checked after it.
Future<ArchiveOutput> compressArchive(
  CompressJob job, {
  required String tempPath,
  required bool Function() isCancelled,
  void Function(ArchiveProgress)? onProgress,
  void Function()? onMoving,
}) async {
  final sources = await _expandSources(job, skip: {tempPath, job.outputPath});
  final progress = _Progress(sources.fold(0, (s, e) => s + e.size), onProgress)
    ..emit(force: true);
  Future<void> checkpoint() => _checkpoint(isCancelled);

  ZipWriter? writer;
  String? reading;
  try {
    writer = await ZipWriter.create(tempPath);
    for (final src in sources) {
      await checkpoint();
      progress.entry(src.entryName);
      if (src.isDirectory) {
        await writer.addDirectory(src.entryName, src.modified);
        continue;
      }
      reading = src.path;
      final stored = isStoredName(src.entryName);
      // Stored entries are read twice (CRC first, so the header carries
      // the sizes: Java's ZipInputStream needs that).
      final passes = stored ? 2 : 1;
      var read = 0;
      var reported = 0;
      await writer.addFile(
        src.entryName,
        src.path,
        modified: src.modified,
        store: stored,
        checkpoint: checkpoint,
        onRead: (n) {
          read += n;
          final now = min(read ~/ passes, src.size);
          progress.add(now - reported);
          reported = now;
        },
      );
      progress.add(src.size - reported);
      reading = null;
    }
    await writer.finish();
    writer = null;
    // Last chance to cancel; the rename itself is atomic.
    await checkpoint();
    onMoving?.call();
    final finalPath = await _freePath(job.outputPath);
    await File(tempPath).rename(finalPath);
    return ArchiveOutput(files: [finalPath], dirs: const []);
  } on Object catch (e, st) {
    await writer?.abort();
    await _deleteQuietly(tempPath);
    _rethrowMapped(e, st, reading ?? tempPath, needed: progress.total);
  }
}

/// One file or folder to zip.
final class _Source {
  const new({
    required this.path,
    required this.entryName,
    required this.isDirectory,
    required this.size,
    required this.modified,
  });

  final String path;
  final String entryName;
  final bool isDirectory;
  final int size;
  final DateTime modified;
}

String _norm(String path) =>
    Platform.isWindows ? path.replaceAll(r'\', '/') : path;

/// Files and folders of [job] (folders recursively), with entry names
/// relative to `job.rootFolder`. Skipped: links, and what Browse never
/// shows either (`isSystemTempName`: `.trashed-*`, `.pending-*`, KFM temp
/// files; `isExcludedFolderPath`: `.thumbnails`, `.KFMTrash`,
/// `Android/data|obb`).
Future<List<_Source>> _expandSources(
  CompressJob job, {
  required Set<String> skip,
}) async {
  final root = _norm(job.rootFolder);
  String entryName(String path) => path.startsWith('$root/')
      ? path.substring(root.length + 1)
      : nameOf(path);
  final out = <_Source>[];
  final seen = <String>{};
  Future<void> addEntity(String path) async {
    if (!seen.add(path) || skip.contains(path)) return;
    if (isSystemTempName(nameOf(path))) return;
    final stat = await FileStat.stat(path);
    final type = stat.type;
    if (type == FileSystemEntityType.file) {
      out.add(
        _Source(
          path: path,
          entryName: entryName(path),
          isDirectory: false,
          size: stat.size,
          modified: stat.modified,
        ),
      );
    } else if (type == FileSystemEntityType.directory) {
      if (isExcludedFolderPath(path)) return;
      out.add(
        _Source(
          path: path,
          entryName: entryName(path),
          isDirectory: true,
          size: 0,
          modified: stat.modified,
        ),
      );
      final children = [
        await for (final e in Directory(path).list(followLinks: false))
          if (e is! Link) _norm(e.path),
      ]..sort();
      for (final c in children) {
        await addEntity(c);
      }
    } else if (type == FileSystemEntityType.notFound) {
      throw ArchiveIoError(path, 'not found');
    }
    // Links, pipes, sockets: never followed.
  }

  for (final p in job.sourcePaths) {
    await addEntity(_norm(p));
  }
  return out;
}

// ------------------------------------------------------------- extract ---

/// Extracts [job] into [tempPath] (a new hidden folder next to or inside
/// the target), then moves it into place: renamed to `job.targetFolder`
/// when that doesn't exist yet, else each top-level item is renamed into it
/// (clashes get ` (1)`). All names are checked before anything is written;
/// on any failure or cancel the temp folder is removed. [onMoving] is
/// called when the move starts: no cancel is checked after it.
Future<ArchiveOutput> extractArchive(
  ExtractJob job, {
  required String tempPath,
  required bool Function() isCancelled,
  void Function(ArchiveProgress)? onProgress,
  void Function()? onMoving,
}) async {
  final password = job.password == null ? null : zipPassword(job.password!);
  final zip = _OpenZip.open(job.zipPath, password: password);
  final temp = _norm(tempPath);
  var created = false;
  _Progress? progress;
  RandomAccessFile? raw;
  try {
    final selected = _select(zip.entries, job.entryNames);
    if (selected.any((s) => s.entry.encrypted) && password == null) {
      throw const PasswordNeeded();
    }
    final total = selected.fold(
      0,
      (s, e) => s + (e.entry.isDirectory ? 0 : e.entry.size),
    );
    final p = progress = _Progress(total, onProgress)..emit(force: true);
    raw = await File(job.zipPath).open();
    final ctx = _ExtractContext(raw, p, isCancelled, password);
    await Directory(temp).create(recursive: true);
    created = true;
    final files = <String>[];
    final dirs = <String>{};
    void madeDir(String path) {
      // Every folder between the temp root and [path].
      var d = path;
      while (d.length > temp.length && dirs.add(d)) {
        d = parentOf(d);
      }
    }

    // Lower-case relative folder path → the folder made for it. Android's
    // shared storage (and Windows) ignore case, so `Photos/` and `photos/`
    // are one folder there: both map to the first spelling, which is the
    // name the folder really has.
    final folders = <String, String>{};
    String folderFor(List<String> segments) {
      var actual = temp;
      final key = StringBuffer();
      for (final seg in segments) {
        key
          ..write('/')
          ..write(seg.toLowerCase());
        final parent = actual;
        actual = folders.putIfAbsent(key.toString(), () => '$parent/$seg');
      }
      return actual;
    }

    final usedFiles = <String>{};
    for (final s in selected) {
      await _checkpoint(isCancelled);
      if (s.segments.isEmpty) continue;
      progress.entry(s.entry.name);
      if (s.entry.isDirectory) {
        final dest = folderFor(s.segments);
        await Directory(dest).create(recursive: true);
        madeDir(dest);
        continue;
      }
      final parent = folderFor(s.segments.sublist(0, s.segments.length - 1));
      await Directory(parent).create(recursive: true);
      madeDir(parent);
      // Two entries with one name (also differing only in case): keep both.
      final name = await uniqueName(
        s.segments.last,
        (c) async =>
            usedFiles.contains('$parent/$c'.toLowerCase()) ||
            await FileSystemEntity.type('$parent/$c') !=
                FileSystemEntityType.notFound,
      );
      final path = '$parent/$name';
      usedFiles.add(path.toLowerCase());
      await _writeEntry(ctx, s.entry, path);
      files.add(path);
    }
    zip.close();
    await raw.close();
    raw = null;
    await _checkpoint(isCancelled);
    onMoving?.call();
    return await _moveIntoPlace(temp, _norm(job.targetFolder), files, dirs);
  } on Object catch (e, st) {
    zip.close();
    try {
      await raw?.close();
    } on FileSystemException {
      // Closing a read handle; nothing to lose.
    }
    if (created) await _deleteQuietly(temp);
    _rethrowMapped(e, st, job.zipPath, needed: progress?.total ?? 0);
  }
}

/// The password as archive 4.x takes it: it uses `codeUnits` as the bytes,
/// so the UTF-8 bytes go in one char each (what 7-Zip and WinZip use for
/// AES, and modern tools for ZipCrypto).
String zipPassword(String password) =>
    String.fromCharCodes(utf8.encode(password));

/// One entry picked for extraction, with its path segments below the
/// target (the parent folders of a picked entry are dropped: "Extract
/// this" on `a/b/c.jpg` gives `c.jpg`).
typedef _Picked = ({_Entry entry, List<String> segments});

List<_Picked> _select(List<_Entry> entries, Set<String>? names) {
  // Every name is checked, picked or not: one unsafe entry refuses the
  // whole archive.
  final segments = <List<String>>[];
  for (final e in entries) {
    if (e.symlink) throw UnsafeEntryPath(e.name);
    final segs = entrySegments(e.name);
    if (segs.isEmpty && !e.isDirectory) throw UnsafeEntryPath(e.name);
    segments.add(segs);
  }
  if (names == null) {
    return [
      for (var i = 0; i < entries.length; i++)
        (entry: entries[i], segments: segments[i]),
    ];
  }
  final drops = <String, int>{};
  final picked = <_Picked>[];
  for (var i = 0; i < entries.length; i++) {
    final by = pickedBy(entries[i].name, names);
    if (by == null) continue;
    final drop = drops[by] ??= entrySegments(by).length - 1;
    final segs = segments[i];
    picked.add((
      entry: entries[i],
      segments: drop > 0 && drop <= segs.length ? segs.sublist(drop) : segs,
    ));
  }
  return picked;
}

const int _chunkSize = 256 * 1024;
const int _yieldEvery = 1024 * 1024;

/// State shared by the entries of one extract.
final class _ExtractContext {
  new(this.raw, this.progress, this.isCancelled, this.password);

  /// The zip, for reading entry data.
  final RandomAccessFile raw;
  final _Progress progress;
  final bool Function() isCancelled;

  /// [zipPassword] form, or null.
  final String? password;

  /// An encrypted entry passed its full check (CRC / MAC): the password is
  /// right, so later bad data is damage, not a wrong password.
  bool passwordProven = false;
}

/// Bad entry data: for an encrypted entry before the password was proven
/// by a full check, most likely a wrong password (ZipCrypto checks it with
/// one byte, AES with two), else damage.
ArchiveError _badData(_ExtractContext ctx, _Entry e, String detail) =>
    e.encrypted && !ctx.passwordProven
    ? const WrongPassword()
    : CorruptArchive('${e.name}: $detail');

Future<void> _writeEntry(_ExtractContext ctx, _Entry e, String path) async {
  final header = e.header;
  final zf = header.file;
  final type = zf?.compressionMethod;
  final aes = header.compressionMethod == ZipFile.zipCompressionAexEncryption;
  int written;
  int crc;
  if (zf == null || e.size == 0) {
    await File(path).writeAsBytes(const []);
    written = 0;
    crc = 0;
  } else if (type == CompressionType.none || type == CompressionType.deflate) {
    (written, crc) = e.encrypted && !aes
        ? await _copyZipCrypto(ctx, zf, e, path)
        : await _copyRaw(ctx, e, path, aes: aes);
  } else {
    // bzip2 / zstd: the package's decoder, streamed into the file (it
    // reads back its own output), then checked.
    final out = OutputFileStream(path);
    try {
      zf.decompress(out);
    } on Object catch (err) {
      if (err is FileSystemException && _isWriteError(err)) rethrow;
      throw _badData(ctx, e, '$err');
    } finally {
      await out.close();
    }
    (written, crc) = await _crcOfFile(path);
    ctx.progress.add(written);
  }
  // AE-2 (WinZip AES) entries carry no CRC; their MAC was checked instead.
  if (written != e.size ||
      (crc != header.crc32 && !(aes && header.crc32 == 0))) {
    throw _badData(ctx, e, 'checksum mismatch');
  }
  if (e.encrypted && e.size > 0) ctx.passwordProven = true;
  final modified = e.modified;
  if (modified != null) {
    try {
      await File(path).setLastModified(modified);
    } on FileSystemException {
      // Keeps "now"; not worth failing the extract.
    }
  }
}

/// Whether [e] (from writing the output) is the disk's fault rather than
/// the data's. dart:io reports bad deflate data as a FileSystemException
/// without an OS error ("Filter error").
bool _isWriteError(FileSystemException e) => e.osError != null;

/// Stored / deflated (optionally WinZip AES) entry data, read from the zip
/// with async I/O in our own loop: a cancel lands mid-entry. AES: the
/// password verifier is checked first, the HMAC-SHA1 authentication code
/// (last 10 bytes) after the data; archive's own decoder never gets to that
/// check when the data is read by length. Returns (bytes written, CRC-32).
Future<(int, int)> _copyRaw(
  _ExtractContext ctx,
  _Entry e,
  String path, {
  required bool aes,
}) async {
  final header = e.header;
  final raw = ctx.raw;
  final out = await File(path).open(mode: FileMode.writeOnly);
  var crc = 0;
  var written = 0;
  final pending = <List<int>>[];
  final deflated = header.file!.compressionMethod == CompressionType.deflate;
  final inflater = deflated
      ? ZLibDecoder(raw: true).startChunkedConversion(_ListSink(pending))
      : null;
  void decode(void Function() step) {
    try {
      step();
    } on Object catch (err) {
      if (err is ArchiveError) rethrow;
      throw _badData(ctx, e, '$err');
    }
  }

  Future<void> flush() async {
    for (final bytes in pending) {
      if (bytes.isEmpty) continue;
      written += bytes.length;
      if (written > e.size) {
        throw _badData(ctx, e, 'more data than declared');
      }
      crc = getCrc32(bytes, crc);
      await out.writeFrom(bytes);
      ctx.progress.add(bytes.length);
    }
    pending.clear();
  }

  try {
    await raw.setPosition(await _dataOffset(raw, header));
    var remaining = header.compressedSize;
    Aes? cipher;
    if (aes) {
      final saltLength = switch (_aesStrength(header)) {
        1 => 8,
        2 => 12,
        _ => 16,
      };
      final keySize = saltLength * 2;
      if (remaining < saltLength + 2 + 10) {
        throw CorruptArchive('${e.name}: truncated encrypted entry');
      }
      final salt = await _readExactly(raw, saltLength, e);
      final verifier = await _readExactly(raw, 2, e);
      final password = ctx.password ?? '';
      if (password.isEmpty) throw const WrongPassword();
      final key = ZipFile.deriveKey(password, salt, derivedKeyLength: keySize);
      if (key[keySize * 2] != verifier[0] ||
          key[keySize * 2 + 1] != verifier[1]) {
        throw const WrongPassword();
      }
      cipher = Aes(
        Uint8List.fromList(key.sublist(0, keySize)),
        Uint8List.fromList(key.sublist(keySize, keySize * 2)),
        keySize,
      );
      remaining -= saltLength + 2 + 10;
    }
    var sinceYield = 0;
    while (remaining > 0) {
      // A multiple of 16 except at the end, as AES-CTR needs.
      final chunk = await _readExactly(raw, min(_chunkSize, remaining), e);
      remaining -= chunk.length;
      // Decrypts in place (after adding the ciphertext to the MAC).
      cipher?.update(chunk, 0, chunk.length);
      if (inflater != null) {
        decode(() => inflater.add(chunk));
      } else {
        pending.add(chunk);
      }
      await flush();
      sinceYield += chunk.length;
      if (sinceYield >= _yieldEvery) {
        sinceYield = 0;
        await _checkpoint(ctx.isCancelled);
      }
    }
    if (inflater != null) decode(inflater.close);
    await flush();
    if (cipher != null) {
      final stored = await _readExactly(raw, 10, e);
      final computed = cipher.finish();
      var diff = 0;
      for (var i = 0; i < 10; i++) {
        diff |= stored[i] ^ computed[i];
      }
      if (diff != 0) throw _badData(ctx, e, 'authentication code mismatch');
    }
  } finally {
    await out.close();
  }
  return (written, crc);
}

/// ZipCrypto entries: archive's decrypting stream (synchronous reads), fed
/// through our loop so it still yields every megabyte.
Future<(int, int)> _copyZipCrypto(
  _ExtractContext ctx,
  ZipFile zf,
  _Entry e,
  String path,
) async {
  final out = await File(path).open(mode: FileMode.writeOnly);
  var crc = 0;
  var written = 0;
  final pending = <List<int>>[];
  try {
    final InputStream stream;
    try {
      stream = zf.getStream(decompress: false);
    } on ArchiveException catch (err) {
      throw _badData(ctx, e, err.message);
    }
    final inflater = zf.compressionMethod == CompressionType.deflate
        ? ZLibDecoder(raw: true).startChunkedConversion(_ListSink(pending))
        : null;
    var sinceYield = 0;
    var ended = false;
    while (!ended) {
      var read = 0;
      try {
        if (stream.isEOS) {
          inflater?.close();
          ended = true;
        } else {
          final chunk = stream
              .readBytes(min(_chunkSize, stream.length))
              .toUint8List();
          read = chunk.length;
          if (chunk.isEmpty) {
            inflater?.close();
            ended = true;
          } else if (inflater != null) {
            inflater.add(chunk);
          } else {
            pending.add(chunk);
          }
        }
      } on Object catch (err) {
        if (err is ArchiveError) rethrow;
        throw _badData(ctx, e, '$err');
      }
      for (final bytes in pending) {
        written += bytes.length;
        if (written > e.size) {
          throw _badData(ctx, e, 'more data than declared');
        }
        crc = getCrc32(bytes, crc);
        await out.writeFrom(bytes);
        ctx.progress.add(bytes.length);
      }
      pending.clear();
      sinceYield += read;
      if (sinceYield >= _yieldEvery) {
        sinceYield = 0;
        await _checkpoint(ctx.isCancelled);
      }
    }
  } finally {
    await out.close();
  }
  return (written, crc);
}

/// Where [header]'s data starts: after its local header's name and extra
/// field (which can differ from the central directory's).
Future<int> _dataOffset(RandomAccessFile raw, ZipFileHeader header) async {
  await raw.setPosition(header.localHeaderOffset);
  final head = await raw.read(30);
  if (head.length < 30 ||
      head[0] != 0x50 ||
      head[1] != 0x4b ||
      head[2] != 3 ||
      head[3] != 4) {
    throw CorruptArchive('${header.filename}: no local header');
  }
  final nameLength = head[26] | head[27] << 8;
  final extraLength = head[28] | head[29] << 8;
  return header.localHeaderOffset + 30 + nameLength + extraLength;
}

/// The WinZip AES strength (1/2/3 = 128/192/256 bit) from the entry's
/// 0x9901 extra field; 256 bit when it's missing.
int _aesStrength(ZipFileHeader header) {
  final extra = header.extraField;
  if (extra == null) return 3;
  var i = 0;
  while (i + 4 <= extra.length) {
    final id = extra[i] | extra[i + 1] << 8;
    final size = extra[i + 2] | extra[i + 3] << 8;
    if (id == 0x9901 && size >= 7 && i + 4 + 7 <= extra.length) {
      return extra[i + 4 + 4];
    }
    i += 4 + size;
  }
  return 3;
}

Future<Uint8List> _readExactly(RandomAccessFile raw, int n, _Entry e) async {
  final first = await raw.read(n);
  if (first.length == n) return first;
  final b = BytesBuilder(copy: false)..add(first);
  while (b.length < n) {
    final more = await raw.read(n - b.length);
    if (more.isEmpty) throw CorruptArchive('${e.name}: truncated');
    b.add(more);
  }
  return b.takeBytes();
}

Future<(int, int)> _crcOfFile(String path) async {
  var crc = 0;
  var length = 0;
  await for (final chunk in File(path).openRead()) {
    crc = getCrc32(chunk, crc);
    length += chunk.length;
  }
  return (length, crc);
}

/// Moves the extracted tree from [temp] to [target]; returns the final
/// paths.
Future<ArchiveOutput> _moveIntoPlace(
  String temp,
  String target,
  List<String> files,
  Set<String> dirs,
) async {
  // Top-level name in temp (lower case) → final path.
  final moved = <String, String>{};
  String? movedRoot;
  if (await FileSystemEntity.type(target) == FileSystemEntityType.notFound) {
    await Directory(temp).rename(target);
    movedRoot = target;
  } else {
    final children = [
      await for (final c in Directory(temp).list()) nameOf(_norm(c.path)),
    ]..sort();
    for (final child in children) {
      final name = await uniqueName(
        child,
        (c) async =>
            await FileSystemEntity.type('$target/$c') !=
            FileSystemEntityType.notFound,
      );
      final from = '$temp/$child';
      final to = '$target/$name';
      if (await FileSystemEntity.isDirectory(from)) {
        await Directory(from).rename(to);
      } else {
        await File(from).rename(to);
      }
      moved[child.toLowerCase()] = to;
    }
    await Directory(temp).delete();
  }

  String finalPath(String tempPath) {
    final rel = tempPath.substring(temp.length + 1);
    if (movedRoot != null) return '$movedRoot/$rel';
    final slash = rel.indexOf('/');
    final top = slash < 0 ? rel : rel.substring(0, slash);
    final rest = slash < 0 ? '' : rel.substring(slash);
    return '${moved[top.toLowerCase()] ?? '$target/$top'}$rest';
  }

  final sortedDirs = dirs.toList()..sort();
  return ArchiveOutput(
    files: List.unmodifiable(files.map(finalPath)),
    dirs: List.unmodifiable([?movedRoot, ...sortedDirs.map(finalPath)]),
  );
}

/// Collects dart:io's chunked inflater output (called synchronously).
final class _ListSink implements Sink<List<int>> {
  const new(this._into);

  final List<List<int>> _into;

  @override
  void add(List<int> data) => _into.add(data);

  @override
  void close() {}
}

// --------------------------------------------------------------- zip in ---

/// One central-directory entry with its decoded name.
final class _Entry {
  const new({
    required this.header,
    required this.name,
    required this.isDirectory,
    required this.size,
    required this.encrypted,
    required this.symlink,
    required this.modified,
  });

  final ZipFileHeader header;
  final String name;
  final bool isDirectory;
  final int size;
  final bool encrypted;
  final bool symlink;
  final DateTime? modified;
}

/// A zip opened for reading: its central directory, decoded.
final class _OpenZip {
  new _(this._input, this.entries, this.length);

  /// Throws [CorruptArchive] for anything that isn't a readable zip.
  /// [password] in [zipPassword] form.
  factory open(String path, {required String? password}) {
    final file = File(path);
    final int length;
    try {
      length = file.lengthSync();
    } on FileSystemException catch (e) {
      throw ArchiveIoError(path, e.message);
    }
    _requireEndRecord(file, length);
    final input = InputFileStream(path);
    try {
      final decoder = ZipDecoder()..decodeStream(input, password: password);
      final raf = file.openSync();
      try {
        final entries = [
          for (final h in decoder.directory.fileHeaders) _entry(h, raf),
        ];
        return _OpenZip._(input, entries, length);
      } finally {
        raf.closeSync();
      }
    } on Object catch (e) {
      input.closeSync();
      if (e is ArchiveError) rethrow;
      throw CorruptArchive('$e');
    }
  }

  final InputFileStream _input;
  final List<_Entry> entries;
  final int length;
  bool _closed = false;

  void close() {
    if (_closed) return;
    _closed = true;
    _input.closeSync();
  }

  static _Entry _entry(ZipFileHeader h, RandomAccessFile raf) {
    final name = _decodeName(h, raf);
    final flags = h.generalPurposeBitFlag;
    return _Entry(
      header: h,
      name: name,
      isDirectory: name.endsWith('/') || name.endsWith(r'\'),
      size: h.uncompressedSize,
      encrypted: flags & 1 != 0,
      symlink: isSymlinkEntry(
        versionMadeBy: h.versionMadeBy,
        externalAttributes: h.externalFileAttributes,
      ),
      modified: _dosTime(h.lastModifiedFileDate, h.lastModifiedFileTime),
    );
  }

  /// UTF-8 names come from the package; others are re-read raw from the
  /// local header and decoded as UTF-8 or CP437 (the package would give
  /// Latin-1 for them).
  static String _decodeName(ZipFileHeader h, RandomAccessFile raf) {
    final name = h.filename;
    if (h.generalPurposeBitFlag & zipUtf8Flag != 0 ||
        name.codeUnits.every((c) => c < 0x80)) {
      return name;
    }
    try {
      raf.setPositionSync(h.localHeaderOffset);
      final head = raf.readSync(30);
      if (head.length < 30 ||
          head[0] != 0x50 ||
          head[1] != 0x4b ||
          head[2] != 3 ||
          head[3] != 4) {
        return name;
      }
      final n = head[26] | head[27] << 8;
      final raw = raf.readSync(n);
      if (raw.length != n) return name;
      return decodeEntryName(raw, utf8Flag: false);
    } on FileSystemException {
      return name;
    }
  }

  static DateTime? _dosTime(int date, int time) {
    if (date == 0) return null;
    final year = ((date >> 9) & 0x7f) + 1980;
    final month = (date >> 5) & 0x0f;
    final day = date & 0x1f;
    if (month < 1 || month > 12 || day < 1) return null;
    return DateTime(
      year,
      month,
      day,
      (time >> 11) & 0x1f,
      (time >> 5) & 0x3f,
      (time & 0x1f) * 2,
    );
  }

  /// The end-of-central-directory record must be in the last 64 KiB (the
  /// package would scan the whole file and then report an empty zip).
  static void _requireEndRecord(File file, int length) {
    const eocd = 22;
    if (length < eocd) throw const CorruptArchive('too short for a zip');
    final tail = min(length, eocd + 0xFFFF);
    final raf = file.openSync();
    try {
      raf.setPositionSync(length - tail);
      final bytes = raf.readSync(tail);
      for (var i = bytes.length - eocd; i >= 0; i--) {
        if (bytes[i] == 0x50 &&
            bytes[i + 1] == 0x4b &&
            bytes[i + 2] == 5 &&
            bytes[i + 3] == 6) {
          return;
        }
      }
    } finally {
      raf.closeSync();
    }
    throw const CorruptArchive('no end of central directory record');
  }
}

// -------------------------------------------------------------- shared ---

/// Throttled progress: at most every 100 ms (plus forced emits).
final class _Progress {
  new(this.total, this._onProgress);

  final int total;
  final void Function(ArchiveProgress)? _onProgress;
  final Stopwatch _clock = Stopwatch()..start();
  int _done = 0;
  int _lastMs = -_interval;
  String? _current;

  static const _interval = 100;

  void add(int bytes) {
    _done += bytes;
    emit();
  }

  void entry(String name) {
    _current = name;
    emit();
  }

  void emit({bool force = false}) {
    final cb = _onProgress;
    if (cb == null) return;
    final now = _clock.elapsedMilliseconds;
    if (!force && now - _lastMs < _interval) return;
    _lastMs = now;
    cb(
      ArchiveProgress(
        bytesDone: min(_done, total),
        bytesTotal: total,
        currentEntry: _current,
      ),
    );
  }
}

/// Lets the command port deliver a cancel, then checks it.
Future<void> _checkpoint(bool Function() isCancelled) async {
  await Future<void>.delayed(Duration.zero);
  if (isCancelled()) throw const ArchiveCancelled();
}

/// [path], or `name (1).ext`… if something is there now.
Future<String> _freePath(String path) async {
  final folder = parentOf(path);
  final name = await uniqueName(
    nameOf(path),
    (c) async =>
        await FileSystemEntity.type('$folder/$c') !=
        FileSystemEntityType.notFound,
  );
  return '$folder/$name';
}

Future<void> _deleteQuietly(String path) async {
  try {
    final type = await FileSystemEntity.type(path, followLinks: false);
    if (type == FileSystemEntityType.directory) {
      await Directory(path).delete(recursive: true);
    } else if (type != FileSystemEntityType.notFound) {
      await File(path).delete();
    }
  } on FileSystemException {
    // The temp ledger removes it at the next start.
  }
}

/// ENOSPC (Linux) / ERROR_DISK_FULL (Windows).
const _noSpaceCodes = {28, 112};

Never _rethrowMapped(
  Object e,
  StackTrace st,
  String path, {
  required int needed,
}) {
  if (e is ArchiveError) Error.throwWithStackTrace(e, st);
  if (e is FileSystemException) {
    if (_noSpaceCodes.contains(e.osError?.errorCode)) {
      throw NotEnoughSpace(needed, 0);
    }
    throw ArchiveIoError(e.path ?? path, e.message);
  }
  if (e is ArchiveException) {
    final m = e.message;
    if (m.contains('password is needed')) throw const PasswordNeeded();
    if (m.contains('Wrong password')) throw const WrongPassword();
    throw CorruptArchive(m);
  }
  if (e is FormatException || e is RangeError || e is StateError) {
    throw CorruptArchive('$e');
  }
  Error.throwWithStackTrace(e, st);
}
