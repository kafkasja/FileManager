import 'dart:io';
import 'dart:typed_data';

import 'package:kfm/core/platform/windows/windows_channel.dart';

/// In-memory stand-in for the native `com.kaf.kfm/windows` side. The
/// "Recycle Bin" moves files into [binDir] on the real disk, so the
/// dart:io half of `WindowsFileSource` sees real changes.
class FakeWindowsChannel implements WindowsChannel {
  new({
    this.binDir,
    this.known = const {},
    this.noBinUnder = const [],
    this.missing = false,
  });

  /// Where recycled files go; null = recycle fails with `ioError`.
  final Directory? binDir;
  Map<KnownFolder, String> known;

  /// Paths starting with one of these have no Recycle Bin.
  final List<String> noBinUnder;

  /// Behave like a build without the native side.
  final bool missing;

  /// Paths whose recycle answers `inUse`.
  final Set<String> lockedPaths = {};
  final List<String> calls = [];

  /// trashId → (original path, stored path, deleted at).
  final Map<String, (String, String, DateTime)> bin = {};
  var _next = 0;

  void _check(String method) {
    calls.add(method);
    if (missing) throw const WindowsChannelException('MISSING', 'no native');
  }

  @override
  Future<Map<KnownFolder, String>> knownFolders() async {
    _check('knownFolders');
    return known;
  }

  @override
  Future<Map<String, bool>> binAvailable(List<String> paths) async {
    _check('binAvailable');
    return {for (final p in paths) p: !noBinUnder.any(p.startsWith)};
  }

  @override
  Future<List<RecycleResult>> recycle(List<String> paths) async {
    _check('recycle');
    final out = <RecycleResult>[];
    for (final p in paths) {
      if (lockedPaths.contains(p)) {
        out.add(RecycleResult(path: p, error: BinError.inUse));
        continue;
      }
      final dir = binDir;
      if (dir == null || !File(p).existsSync()) {
        out.add(
          RecycleResult(
            path: p,
            error: dir == null ? BinError.ioError : BinError.notFound,
          ),
        );
        continue;
      }
      final id = 'bin-${_next++}';
      final stored = '${dir.path}/$id';
      File(p).renameSync(stored);
      bin[id] = (p, stored, DateTime.utc(2026, 11, 3));
      out.add(RecycleResult(path: p, trashId: id));
    }
    return out;
  }

  @override
  Future<List<BinItem>> listBin() async {
    _check('listBin');
    return [
      for (final MapEntry(key: id, value: (orig, stored, at)) in bin.entries)
        BinItem(
          trashId: id,
          originalPath: orig,
          sizeBytes: File(stored).lengthSync(),
          deletedAt: at,
          modifiedAt: at,
        ),
    ];
  }

  @override
  Future<List<BinRestoreResult>> restoreFromBin(List<String> trashIds) async {
    _check('restoreFromBin');
    return [
      for (final id in trashIds)
        if (bin.remove(id) case (final orig, final stored, _))
          _restoreOne(id, orig, stored)
        else
          BinRestoreResult(trashId: id, error: BinError.notFound),
    ];
  }

  BinRestoreResult _restoreOne(String id, String orig, String stored) {
    var target = orig;
    if (File(target).existsSync()) {
      final dot = orig.lastIndexOf('.');
      target = '${orig.substring(0, dot)} (1)${orig.substring(dot)}';
    }
    File(stored).renameSync(target);
    return BinRestoreResult(trashId: id, path: target);
  }

  @override
  Future<void> deleteFromBin(List<String> trashIds) async {
    _check('deleteFromBin');
    for (final id in trashIds) {
      if (bin.remove(id) case (_, final stored, _)) File(stored).deleteSync();
    }
  }

  @override
  Future<Uint8List?> thumbnail(String path, int size) async {
    _check('thumbnail');
    return null;
  }

  @override
  Future<bool> networkIsPublic() async {
    _check('networkIsPublic');
    return false;
  }
}
