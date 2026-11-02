import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'apk_cache.g.dart';

/// X5: `cacheDir/apk/` holds copies of `content://` APKs while their info
/// sheet is open. A copy left by a kill is removed on the next start.
class ApkCache {
  new(this._cacheDir, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  final Future<Directory> Function() _cacheDir;
  final DateTime Function() _now;

  static const maxAge = Duration(days: 1);

  /// Deletes copies older than [maxAge]; returns how many. Errors propagate.
  Future<int> cleanUp() async {
    final dir = Directory(p.join((await _cacheDir()).path, 'apk'));
    if (!dir.existsSync()) return 0;
    final cutoff = _now().subtract(maxAge);
    var removed = 0;
    await for (final e in dir.list(followLinks: false)) {
      if (e is! File) continue;
      if (e.statSync().modified.isBefore(cutoff)) {
        await e.delete();
        removed++;
      }
    }
    return removed;
  }
}

/// On Android `getTemporaryDirectory` is `Context.getCacheDir`, the
/// folder `ApkSupport.kt` copies into.
@Riverpod(keepAlive: true)
ApkCache apkCache(Ref ref) => ApkCache(getTemporaryDirectory);
