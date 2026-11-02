import 'package:kfm/features/backup/domain/backup_codec.dart';
import 'package:meta/meta.dart';

/// A `media_index` row as far as matching needs it (TASK-X6).
@immutable
class IndexedFile {
  const new({
    required this.id,
    required this.folderPath,
    required this.name,
    required this.size,
    required this.takenAtMs,
    required this.modifiedAtMs,
  });

  final String id;
  final String folderPath;
  final String name;
  final int size;
  final int? takenAtMs;
  final int modifiedAtMs;
}

final _internal = RegExp(r'^/storage/emulated/\d+(?=/|$)');
final _removable = RegExp(r'^/storage/(?!emulated(?:/|$)|self(?:/|$))[^/]+');

/// Splits an absolute folder path into a volume tag and the path below it,
/// so a file matches on another phone (SD card UUIDs differ per card).
({String vol, String rel}) splitVolume(String folderPath) {
  String below(Match m) {
    final rest = folderPath.substring(m.end);
    return rest.startsWith('/') ? rest.substring(1) : rest;
  }

  final internal = _internal.firstMatch(folderPath);
  if (internal != null) return (vol: 'int', rel: below(internal));
  final removable = _removable.firstMatch(folderPath);
  if (removable != null) return (vol: 'sd', rel: below(removable));
  return (
    vol: 'root',
    rel: folderPath.startsWith('/') ? folderPath.substring(1) : folderPath,
  );
}

String _exactKey(String vol, String rel, String name, int size, int? taken) =>
    '$vol\u0000$rel\u0000$name\u0000$size\u0000${taken ?? ''}';

String _looseKey(String name, int size, int? taken) =>
    '$name\u0000$size\u0000${taken ?? ''}';

/// For each of [files] the local file it is, or null. Pure; run it in
/// `Isolate.run` for big libraries.
///
/// 1. Same volume, folder, name, size and capture time.
/// 2. Else same name, size and capture time, when exactly one local file
///    and exactly one backup entry have them (folders were reorganised).
/// 3. Else unmatched. A null capture time only matches null; never by name
///    alone. A local file is matched at most once.
List<IndexedFile?> matchFiles(List<BackupFile> files, List<IndexedFile> index) {
  final exact = <String, IndexedFile>{};
  final loose = <String, List<IndexedFile>>{};
  for (final f in index) {
    final (:vol, :rel) = splitVolume(f.folderPath);
    exact[_exactKey(vol, rel, f.name, f.size, f.takenAtMs)] = f;
    (loose[_looseKey(f.name, f.size, f.takenAtMs)] ??= []).add(f);
  }
  final claimed = <String>{};
  final result = List<IndexedFile?>.filled(files.length, null);
  for (final (i, b) in files.indexed) {
    final hit = exact[_exactKey(b.vol, b.rel, b.name, b.size, b.takenAtMs)];
    if (hit != null && claimed.add(hit.id)) result[i] = hit;
  }
  final backupLoose = <String, int>{};
  for (final b in files) {
    final k = _looseKey(b.name, b.size, b.takenAtMs);
    backupLoose[k] = (backupLoose[k] ?? 0) + 1;
  }
  for (final (i, b) in files.indexed) {
    if (result[i] != null) continue;
    final k = _looseKey(b.name, b.size, b.takenAtMs);
    final candidates = loose[k];
    if (candidates == null || candidates.length != 1) continue;
    if (backupLoose[k] != 1) continue;
    final only = candidates.single;
    if (claimed.add(only.id)) result[i] = only;
  }
  return result;
}
