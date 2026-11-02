import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:kfm/core/diagnostics/redact.dart';

/// Where an error was caught (H5).
enum ErrorSource { flutter, platform, isolate, db, bg }

/// One error to log. [error] and [stack] are redacted when written.
@immutable
class ErrorLogEntry {
  const new({
    required this.at,
    required this.source,
    required this.error,
    this.stack,
  });

  final DateTime at;
  final ErrorSource source;
  final String error;
  final StackTrace? stack;
}

/// Device facts at the top of an export. No serial, Android ID or account.
@immutable
class ExportHeader {
  const new({
    required this.appVersion,
    required this.buildNumber,
    required this.locale,
    required this.schemaVersion,
    this.sdkInt,
    this.deviceModel,
  });

  final String appVersion;
  final String buildNumber;
  final int? sdkInt;
  final String? deviceModel;
  final String locale;
  final int schemaVersion;
}

/// H5: a small rotating error log on the device; it never leaves it unless
/// the user shares the export. Independent of the DB (the DB may be the
/// broken part).
///
/// Files in the log folder (`<app support>/logs`): `errors.log` (+ `errors.1.log`,
/// one rotation) for the UI isolate, `errors-bg.log` for the WorkManager
/// isolate (own instance, so two isolates never append to one file), `salt`
/// (16 random bytes, hex) for [redactForLog]. Appends are serialized by a
/// future chain and use async I/O, so the UI isolate never blocks.
class ErrorLog {
  /// [rotate] keeps one older file; otherwise the file is cut to its newest
  /// half when it grows past [maxBytes] (the background log).
  new _(
    this._dirFn, {
    required this.fileName,
    required this.maxBytes,
    required this.rotate,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// The UI isolate's log in [dir] (created lazily on the first write).
  factory main(
    Future<Directory> Function() dir, {
    int maxBytes = mainMaxBytes,
    DateTime Function()? clock,
  }) => ErrorLog._(
    dir,
    fileName: mainFileName,
    maxBytes: maxBytes,
    rotate: true,
    clock: clock,
  );

  /// The WorkManager isolate's log in [dir].
  factory background(
    Future<Directory> Function() dir, {
    int maxBytes = backgroundMaxBytes,
    DateTime Function()? clock,
  }) => ErrorLog._(
    dir,
    fileName: backgroundFileName,
    maxBytes: maxBytes,
    rotate: false,
    clock: clock,
  );

  /// Records nothing (tests, platforms without a log folder).
  factory disabled() => _DisabledErrorLog();

  static const mainFileName = 'errors.log';
  static const rotatedFileName = 'errors.1.log';
  static const backgroundFileName = 'errors-bg.log';
  static const saltFileName = 'salt';
  static const exportDirName = 'export';
  static const int mainMaxBytes = 256 * 1024;
  static const int backgroundMaxBytes = 128 * 1024;
  static const maxFrames = 40;
  static const maxErrorChars = 4000;
  static const dedupeWindow = Duration(seconds: 60);

  /// The process-wide log (set in `main` and in the WorkManager entry), for
  /// code without a `Ref` (isolate spawns).
  static ErrorLog? current;

  final Future<Directory> Function() _dirFn;
  Future<Directory>? _dirFuture;
  Future<Directory> get _dir => _dirFuture ??= _dirFn();
  final String fileName;
  final int maxBytes;
  final bool rotate;
  final DateTime Function() _clock;

  Future<void> _chain = Future<void>.value();

  /// Fires after every finished write or clear, so Settings → About's
  /// count updates while the screen stays open (tabs keep it alive).
  final StreamController<void> _changes = StreamController.broadcast();
  Stream<void> get changes => _changes.stream;
  String? _salt;
  int? _size;

  // Dedupe: identical error + top frame within [dedupeWindow].
  String? _lastKey;
  DateTime? _lastAt;
  ErrorSource? _lastSource;
  int _repeats = 0;

  /// Appends [e] (redacted). Never throws: an I/O failure is printed and
  /// dropped (a logger that throws would recurse).
  Future<void> record(ErrorLogEntry e) =>
      _enqueue(() => _record(e), swallow: true).whenComplete(_changed);

  // Only writes and clears notify: entryCount/flush also use the queue,
  // and the count provider re-reads on every notification.
  void _changed() => _changes.add(null);

  /// Waits for every pending write.
  Future<void> flush() => _enqueue(_writeRepeats, swallow: true);

  /// Entries in all log files (UI + background).
  Future<int> entryCount() async {
    await flush();
    var count = 0;
    for (final file in await _logFiles()) {
      final text = await _readOrEmpty(file);
      count += _entryHeader.allMatches(text).length;
    }
    return count;
  }

  /// Writes `export/kfm-errors-<date>.txt` (header + every log file, oldest
  /// first) and returns it. Older exports are deleted first.
  Future<File> buildExport(ExportHeader header) async {
    await flush();
    final dir = await _dir;
    final exportDir = Directory('${dir.path}/$exportDirName');
    if (await exportDir.exists()) await exportDir.delete(recursive: true);
    await exportDir.create(recursive: true);
    final now = _clock().toUtc();
    final date = now.toIso8601String().substring(0, 10);
    final out = StringBuffer()
      ..writeln('KFM error log')
      ..writeln('Exported: ${now.toIso8601String()}')
      ..writeln('App: ${header.appVersion} (${header.buildNumber})')
      ..writeln('Android SDK: ${header.sdkInt ?? '?'}')
      ..writeln('Device: ${header.deviceModel ?? '?'}')
      ..writeln('Locale: ${header.locale}')
      ..writeln('DB schema: ${header.schemaVersion}')
      ..writeln('Folder and file names are replaced by #tokens.')
      ..writeln();
    for (final file in await _logFiles()) {
      final text = await _readOrEmpty(file);
      if (text.isEmpty) continue;
      out
        ..writeln('== ${file.uri.pathSegments.last} ==')
        ..write(text);
      if (!text.endsWith('\n')) out.writeln();
      out.writeln();
    }
    final file = File('${exportDir.path}/kfm-errors-$date.txt');
    await file.writeAsString(out.toString(), flush: true);
    return file;
  }

  /// Deletes every log file and export (the salt stays).
  Future<void> clear() => _enqueue(swallow: false, () async {
    _lastKey = null;
    _repeats = 0;
    _size = 0;
    final dir = await _dir;
    for (final file in await _logFiles()) {
      if (await file.exists()) await file.delete();
    }
    final exportDir = Directory('${dir.path}/$exportDirName');
    if (await exportDir.exists()) await exportDir.delete(recursive: true);
  }).whenComplete(_changed);

  /// Runs [job] after every earlier one. The chain itself never fails;
  /// [swallow] = false hands the failure to the caller too.
  Future<void> _enqueue(Future<void> Function() job, {required bool swallow}) {
    final run = _chain.then((_) => job());
    final chain = _chain = run.catchError((Object e) {
      debugPrint('kfm error log: $e');
    });
    return swallow ? chain : run;
  }

  /// Oldest first: background, rotated, current.
  Future<List<File>> _logFiles() async {
    final dir = (await _dir).path;
    return [
      File('$dir/$backgroundFileName'),
      File('$dir/$rotatedFileName'),
      File('$dir/$mainFileName'),
    ];
  }

  Future<void> _record(ErrorLogEntry e) async {
    final error = e.error.length > maxErrorChars
        ? '${e.error.substring(0, maxErrorChars)}â€¦'
        : e.error;
    final frames = _frames(e.stack);
    final key = '${e.source.name}|$error|${frames.firstOrNull ?? ''}';
    final last = _lastAt;
    if (key == _lastKey &&
        last != null &&
        e.at.difference(last).abs() < dedupeWindow) {
      _repeats++;
      return;
    }
    await _writeRepeats();
    _lastKey = key;
    _lastAt = e.at;
    _lastSource = e.source;
    final salt = await _loadSalt();
    final block = StringBuffer()
      ..writeln(
        '${e.at.toUtc().toIso8601String()} [${e.source.name}] '
        '${redactForLog(error, salt)}',
      );
    for (final frame in frames) {
      block.writeln(redactForLog(frame, salt));
    }
    await _append(block.toString());
  }

  /// "(x5)" note for errors folded into the previous entry.
  Future<void> _writeRepeats() async {
    if (_repeats == 0) return;
    final at = _clock().toUtc().toIso8601String();
    final count = _repeats + 1;
    _repeats = 0;
    await _append('$at [${_lastSource?.name}] (x$count) same error as above\n');
  }

  List<String> _frames(StackTrace? stack) {
    if (stack == null) return const [];
    final lines = stack
        .toString()
        .split('\n')
        .map((l) => l.trimRight())
        .where((l) => l.isNotEmpty)
        .toList();
    return lines.length <= maxFrames
        ? lines
        : [...lines.take(maxFrames), 'â€¦ ${lines.length - maxFrames} more'];
  }

  Future<String> _loadSalt() async {
    final cached = _salt;
    if (cached != null) return cached;
    final dir = await _dir;
    await dir.create(recursive: true);
    final file = File('${dir.path}/$saltFileName');
    var salt = await file.exists() ? (await file.readAsString()).trim() : '';
    if (salt.length < 32) {
      final random = Random.secure();
      salt = List.generate(
        16,
        (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
      await file.writeAsString(salt, flush: true);
    }
    return _salt = salt;
  }

  Future<void> _append(String text) async {
    final dir = await _dir;
    await dir.create(recursive: true);
    final file = File('${dir.path}/$fileName');
    final size = _size ??= await file.exists() ? await file.length() : 0;
    final bytes = text.length; // close enough (mostly ASCII)
    if (size + bytes > maxBytes && size > 0) {
      if (rotate) {
        await file.rename('${dir.path}/$rotatedFileName');
        _size = 0;
      } else {
        _size = await _keepNewestHalf(file);
      }
    }
    await file.writeAsString(text, mode: FileMode.append);
    _size = (_size ?? 0) + bytes;
  }

  /// Cuts [file] to its newest `maxBytes / 2`, at an entry start.
  Future<int> _keepNewestHalf(File file) async {
    final text = await file.readAsString();
    var cut = text.length - maxBytes ~/ 2;
    if (cut <= 0) return text.length;
    final next = _entryHeader.allMatches(text).where((m) => m.start >= cut);
    cut = next.isEmpty ? text.length : next.first.start;
    final kept = text.substring(cut);
    await file.writeAsString(kept, flush: true);
    return kept.length;
  }

  static Future<String> _readOrEmpty(File file) async {
    try {
      return await file.readAsString();
    } on FileSystemException {
      return '';
    } on FormatException {
      return '';
    }
  }

  /// `2026-10-29T10:15:02.123Z [flutter] â€¦` at a line start.
  static final _entryHeader = RegExp(
    r'^\d{4}-\d\d-\d\dT[\d:.]+Z \[(?:flutter|platform|isolate|db|bg)\] (?!\(x\d+\) same error)',
    multiLine: true,
  );
}

class _DisabledErrorLog extends ErrorLog {
  new()
    : super._(
        () async => Directory.systemTemp,
        fileName: ErrorLog.mainFileName,
        maxBytes: 0,
        rotate: true,
      );

  @override
  Future<void> record(ErrorLogEntry e) async {}

  @override
  Future<void> flush() async {}

  @override
  Future<int> entryCount() async => 0;

  @override
  Future<File> buildExport(ExportHeader header) =>
      Future.error(UnsupportedError('error log disabled'));

  @override
  Future<void> clear() async {}
}
