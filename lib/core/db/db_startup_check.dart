import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

/// What [checkDatabaseFile] found before the app opened its database (Q6).
enum DbStartupState {
  /// Opened fine (or no database yet).
  ok,

  /// The file wasn't a readable SQLite database: it was moved aside and
  /// KFM starts with a new, empty one. User files are never touched.
  reset,

  /// The file couldn't be opened or checked for another reason (locked by
  /// another program, no permission, I/O error). Nothing was moved.
  unavailable,
}

@immutable
class DbStartupReport {
  const new(this.state, {this.backupName, this.detail});

  static const ok = DbStartupReport(DbStartupState.ok);

  final DbStartupState state;

  /// File name of the moved-aside copy ([DbStartupState.reset]).
  final String? backupName;

  /// The SQLite or file-system error, for the error log (not shown).
  final String? detail;
}

/// SQLite primary result codes that mean "this file is damaged".
const _corruptCodes = {
  11, // SQLITE_CORRUPT
  26, // SQLITE_NOTADB
};

/// How many moved-aside sets are kept; older ones are deleted.
const kBrokenDbCopiesKept = 2;

const _brokenMarker = '.broken-';

/// The app database's file (`drift_flutter` names it `<name>.sqlite`).
Future<File> appDatabaseFile() async =>
    File(p.join((await getApplicationSupportDirectory()).path, 'kfm.sqlite'));

/// Opens [db] with a plain SQLite connection and reads its schema before
/// drift does. A damaged file (not a database, or a malformed header or
/// schema page) is renamed to `<name>.broken-<stamp>` together with its
/// `-wal` and `-shm` files, so the app starts with a fresh database instead
/// of failing every query on every start. A file that is merely locked or
/// unreadable is left alone ([DbStartupState.unavailable]). Never throws.
///
/// Only the header and schema are checked (cheap on every start); damage
/// deeper in the file shows up as query errors instead.
Future<DbStartupReport> checkDatabaseFile(
  File db, {
  DateTime Function() now = DateTime.now,
}) async {
  try {
    final wal = File('${db.path}-wal');
    final shm = File('${db.path}-shm');
    if (FileSystemEntity.typeSync(db.path) == FileSystemEntityType.directory) {
      return const DbStartupReport(
        DbStartupState.unavailable,
        detail: 'database path is a folder',
      );
    }
    if (!db.existsSync()) {
      // A WAL without its database would be replayed into the new one.
      if (wal.existsSync() || shm.existsSync()) {
        return _moveAside(db, now(), 'orphan WAL without its database');
      }
      return DbStartupReport.ok;
    }
    final String? problem;
    try {
      problem = _probe(db.path);
    } on SqliteException catch (e) {
      return DbStartupReport(
        DbStartupState.unavailable,
        detail: 'SqliteException(${e.resultCode}): ${e.message}',
      );
    }
    if (problem == null) return DbStartupReport.ok;
    return _moveAside(db, now(), problem);
  } on FileSystemException catch (e) {
    return DbStartupReport(DbStartupState.unavailable, detail: e.toString());
  } on Object catch (e) {
    return DbStartupReport(DbStartupState.unavailable, detail: e.toString());
  }
}

/// Null when the file reads fine; the error text when it is damaged.
/// Other SQLite errors (busy, can't open, I/O) are rethrown.
String? _probe(String path) {
  final Database conn;
  try {
    // Read-only: closing it never checkpoints or deletes the WAL, so a
    // damaged set is moved aside exactly as it was found.
    conn = sqlite3.open(path, mode: OpenMode.readOnly);
  } on SqliteException catch (e) {
    if (_corruptCodes.contains(e.resultCode & 0xff)) return e.toString();
    rethrow;
  }
  try {
    conn
      ..execute('PRAGMA busy_timeout = 5000')
      ..select('PRAGMA schema_version')
      ..select('SELECT count(*) FROM sqlite_master')
      ..select('PRAGMA journal_mode');
    return null;
  } on SqliteException catch (e) {
    if (_corruptCodes.contains(e.resultCode & 0xff)) return e.toString();
    rethrow;
  } finally {
    conn.close();
  }
}

DbStartupReport _moveAside(File db, DateTime at, String why) {
  final stamp = _stamp(at);
  final backup = '${db.path}$_brokenMarker$stamp';
  // Side files first: a fresh database must never meet the old WAL.
  for (final suffix in const ['-wal', '-shm', '-journal']) {
    final side = File('${db.path}$suffix');
    if (side.existsSync()) {
      side.renameSync('${db.path}$suffix$_brokenMarker$stamp');
    }
  }
  if (db.existsSync()) db.renameSync(backup);
  _pruneOldCopies(db);
  return DbStartupReport(
    DbStartupState.reset,
    backupName: p.basename(backup),
    detail: why,
  );
}

/// Keeps the newest [kBrokenDbCopiesKept] stamps; best effort.
void _pruneOldCopies(File db) {
  try {
    final base = p.basename(db.path);
    final byStamp = <String, List<File>>{};
    for (final e in db.parent.listSync(followLinks: false)) {
      if (e is! File) continue;
      final name = p.basename(e.path);
      if (!name.startsWith(base)) continue;
      final i = name.indexOf(_brokenMarker);
      if (i < 0) continue;
      final stamp = name.substring(i + _brokenMarker.length);
      (byStamp[stamp] ??= []).add(e);
    }
    final stamps = byStamp.keys.toList()..sort();
    final drop = stamps.length - kBrokenDbCopiesKept;
    for (final old in stamps.take(drop < 0 ? 0 : drop)) {
      for (final f in byStamp[old]!) {
        f.deleteSync();
      }
    }
  } on FileSystemException {
    // Leftover copies only cost space.
  }
}

String _stamp(DateTime at) {
  final u = at.toUtc();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${u.year}${two(u.month)}${two(u.day)}-'
      '${two(u.hour)}${two(u.minute)}${two(u.second)}-'
      '${u.millisecond.toString().padLeft(3, '0')}';
}
