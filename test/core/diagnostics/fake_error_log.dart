import 'dart:async';
import 'dart:io';

import 'package:kfm/core/diagnostics/error_log.dart';

/// In-memory [ErrorLog] for widget/provider tests.
class FakeErrorLog implements ErrorLog {
  final List<ErrorLogEntry> entries = [];
  final List<ExportHeader> exports = [];
  int clears = 0;
  final StreamController<void> _changes = StreamController.broadcast();

  @override
  Stream<void> get changes => _changes.stream;

  @override
  String get fileName => ErrorLog.mainFileName;

  @override
  int get maxBytes => ErrorLog.mainMaxBytes;

  @override
  bool get rotate => true;

  @override
  Future<void> record(ErrorLogEntry e) async {
    entries.add(e);
    _changes.add(null);
  }

  @override
  Future<void> flush() async {}

  @override
  Future<int> entryCount() async => entries.length;

  @override
  Future<File> buildExport(ExportHeader header) async {
    exports.add(header);
    return File('kfm-errors-test.txt');
  }

  @override
  Future<void> clear() async {
    clears++;
    entries.clear();
    _changes.add(null);
  }
}
