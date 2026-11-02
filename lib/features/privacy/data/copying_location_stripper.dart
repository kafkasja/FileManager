import 'dart:developer' as developer;
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/privacy/domain/image_location.dart';
import 'package:kfm/features/privacy/domain/location_stripper.dart';
import 'package:kfm/features/privacy/domain/mp4_location_stripper.dart';

/// Copies the file's bytes (as the original when Android allows it) to
/// [outPath]. Throws when it can't be read.
typedef CopyOriginal = Future<void> Function(FileRef file, String outPath);

/// [LocationStripper] that copies each file into `<root>/<sendId>/` and
/// removes location from the copy in a worker isolate (TASK-X2): photos
/// with [stripImageLocation], MP4/MOV/3GP videos with
/// [stripMp4LocationInPlace]; other video containers are copied as they
/// are (they don't carry location KFM knows of).
class CopyingLocationStripper implements LocationStripper {
  new({required this._root, required this._copy});

  /// `<cache>/privacy` (created on demand).
  final Future<Directory> Function() _root;
  final CopyOriginal _copy;

  @override
  Future<StrippedFile> stripToTemp(
    FileRef file, {
    required String sendId,
  }) async {
    final dir = Directory('${(await _root()).path}/${_safe(sendId)}');
    await dir.create(recursive: true);
    final out = await _freePath(dir, file.name);
    try {
      await _copy(file, out);
    } on Object catch (e) {
      developer.log('copy for ${file.id} failed: $e', name: 'kfm.privacy');
      await _delete(out);
      throw LocationStripException(LocationStripFailure.readFailed, file.id);
    }
    final video = file.kind == FileKind.video;
    try {
      final size = await Isolate.run(() => _stripFile(out, video: video));
      return StrippedFile(path: out, sizeBytes: size);
    } on ImageLocationException catch (e) {
      developer.log('${file.id}: $e', name: 'kfm.privacy');
      await _delete(out);
      throw LocationStripException(
        LocationStripFailure.stillHasLocation,
        file.id,
      );
    } on Mp4FormatException catch (e) {
      developer.log('${file.id}: $e', name: 'kfm.privacy');
      await _delete(out);
      throw LocationStripException(
        e.message == kLocationStillPresent
            ? LocationStripFailure.stillHasLocation
            : LocationStripFailure.unsupportedFormat,
        file.id,
      );
    } on FileSystemException catch (e) {
      developer.log('${file.id}: $e', name: 'kfm.privacy');
      await _delete(out);
      throw LocationStripException(LocationStripFailure.readFailed, file.id);
    }
  }

  @override
  Future<void> release(String sendId) async {
    final dir = Directory('${(await _root()).path}/${_safe(sendId)}');
    try {
      await dir.delete(recursive: true);
    } on PathNotFoundException {
      // Already gone.
    } on FileSystemException catch (e) {
      developer.log('privacy temp not deleted: $e', name: 'kfm.privacy');
    }
  }

  /// Deletes every send folder last changed before [before] (app start:
  /// shares the receiving app may still have read are gone by then).
  Future<int> purgeOlderThan(DateTime before) async {
    final root = await _root();
    if (!await root.exists()) return 0;
    var count = 0;
    await for (final e in root.list(followLinks: false)) {
      try {
        if ((await e.stat()).modified.isBefore(before)) {
          await e.delete(recursive: true);
          count++;
        }
      } on FileSystemException catch (err) {
        developer.log('privacy temp not purged: $err', name: 'kfm.privacy');
      }
    }
    return count;
  }

  static String _safe(String id) => id.replaceAll(RegExp(r'[^\w.-]'), '_');

  /// `name`, else `name (2).ext`, … (several files of one share can share
  /// a name).
  static Future<String> _freePath(Directory dir, String name) async {
    final safe = name.replaceAll(RegExp(r'[/\\]'), '_');
    var candidate = '${dir.path}/$safe';
    final dot = safe.lastIndexOf('.');
    final stem = dot > 0 ? safe.substring(0, dot) : safe;
    final ext = dot > 0 ? safe.substring(dot) : '';
    for (var i = 2; await File(candidate).exists(); i++) {
      candidate = '${dir.path}/$stem ($i)$ext';
    }
    return candidate;
  }

  static Future<void> _delete(String path) async {
    try {
      await File(path).delete();
    } on FileSystemException {
      // Never written, or already gone.
    }
  }
}

/// Worker isolate: strips [path] in place, returns its length.
Future<int> _stripFile(String path, {required bool video}) async {
  if (!video) return await stripImageFileInPlace(path);
  final file = File(path);
  final raf = await file.open();
  final Uint8List head;
  try {
    head = await raf.read(16);
  } finally {
    await raf.close();
  }
  if (looksLikeIsoBmff(head)) {
    await stripMp4LocationInPlace(path);
  }
  return await file.length();
}
