import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/diagnostics/error_log.dart';

void main() {
  late Directory dir;
  var now = DateTime.utc(2026, 11, 2, 10);

  setUp(() {
    dir = Directory.systemTemp.createTempSync('kfm_error_log');
    now = DateTime.utc(2026, 11, 2, 10);
  });
  tearDown(() => dir.deleteSync(recursive: true));

  ErrorLog mainLog({int maxBytes = ErrorLog.mainMaxBytes}) =>
      ErrorLog.main(() async => dir, maxBytes: maxBytes, clock: () => now);

  ErrorLogEntry entry(
    String error, {
    ErrorSource source = ErrorSource.flutter,
    StackTrace? stack,
  }) => ErrorLogEntry(at: now, source: source, error: error, stack: stack);

  const header = ExportHeader(
    appVersion: '0.1.0',
    buildNumber: '1',
    sdkInt: 36,
    deviceModel: 'SM-S908B',
    locale: 'en_US',
    schemaVersion: 20,
  );

  test('records entries with time, source and redacted text', () async {
    final log = mainLog();
    await log.record(
      entry(
        'cannot open /storage/emulated/0/DCIM/Secret/a.jpg',
        stack: StackTrace.fromString(
          '#0 open (package:kfm/x.dart:1:1)\n#1 at /storage/emulated/0/DCIM/Secret/b.jpg',
        ),
      ),
    );
    await log.record(entry('db broke', source: ErrorSource.db));
    expect(await log.entryCount(), 2);
    final text = File('${dir.path}/errors.log').readAsStringSync();
    expect(
      text,
      contains('2026-11-02T10:00:00.000Z [flutter] cannot open [int]/DCIM/#'),
    );
    expect(text, contains('[db] db broke'));
    expect(text, contains('package:kfm/x.dart:1:1'));
    expect(text, isNot(contains('Secret')));
    expect(File('${dir.path}/salt').readAsStringSync(), hasLength(32));
  });

  test('identical errors within 60 s are counted, not repeated', () async {
    final log = mainLog();
    for (var i = 0; i < 5; i++) {
      await log.record(entry('Bad state: loop'));
      now = now.add(const Duration(seconds: 1));
    }
    await log.record(entry('another'));
    now = now.add(const Duration(minutes: 2));
    await log.record(entry('another')); // outside the window: written again
    expect(await log.entryCount(), 3);
    final text = File('${dir.path}/errors.log').readAsStringSync();
    expect('Bad state: loop'.allMatches(text), hasLength(1));
    expect(text, contains('(x5) same error as above'));
  });

  test('rotates once past maxBytes; total stays bounded', () async {
    final log = mainLog(maxBytes: 2000);
    for (var i = 0; i < 200; i++) {
      await log.record(entry('error number $i ${'x' * 80}'));
    }
    await log.flush();
    final current = File('${dir.path}/errors.log').lengthSync();
    final rotated = File('${dir.path}/errors.1.log').lengthSync();
    expect(current, lessThanOrEqualTo(2000));
    expect(rotated, lessThanOrEqualTo(2000));
    final text = File('${dir.path}/errors.log').readAsStringSync();
    expect(text, contains('error number 199'));
  });

  test('the background log keeps its newest half', () async {
    final log = ErrorLog.background(
      () async => dir,
      maxBytes: 2000,
      clock: () => now,
    );
    for (var i = 0; i < 100; i++) {
      await log.record(entry('bg $i ${'y' * 80}', source: ErrorSource.bg));
    }
    await log.flush();
    final file = File('${dir.path}/errors-bg.log');
    expect(file.lengthSync(), lessThanOrEqualTo(2000));
    final text = file.readAsStringSync();
    expect(text, contains('bg 99 '));
    expect(text, startsWith('2026-'));
    expect(File('${dir.path}/errors.log').existsSync(), isFalse);
  });

  test('export holds the header and every file; clear empties all', () async {
    final bg = ErrorLog.background(() async => dir, clock: () => now);
    await bg.record(entry('purge failed', source: ErrorSource.bg));
    await bg.flush();
    final log = mainLog();
    await log.record(entry('ui failed'));
    expect(await log.entryCount(), 2);

    final export = await log.buildExport(header);
    expect(
      export.path.replaceAll(r'\', '/'),
      endsWith('/export/kfm-errors-2026-11-02.txt'),
    );
    final text = export.readAsStringSync();
    expect(text, contains('App: 0.1.0 (1)'));
    expect(text, contains('Android SDK: 36'));
    expect(text, contains('Device: SM-S908B'));
    expect(text, contains('DB schema: 20'));
    expect(text, contains('[bg] purge failed'));
    expect(text, contains('[flutter] ui failed'));
    expect(text.indexOf('purge failed'), lessThan(text.indexOf('ui failed')));

    await log.clear();
    expect(await log.entryCount(), 0);
    expect(Directory('${dir.path}/export').existsSync(), isFalse);
    expect(File('${dir.path}/salt').existsSync(), isTrue);
    // Still records after a clear.
    await log.record(entry('after clear'));
    expect(await log.entryCount(), 1);
  });

  test('record never throws when the folder is unusable', () async {
    final log = ErrorLog.main(() async => throw const FileSystemException('x'));
    await log.record(entry('lost'));
    await expectLater(log.flush(), completes);
  });

  test('the disabled log records nothing', () async {
    final log = ErrorLog.disabled();
    await log.record(entry('x'));
    expect(await log.entryCount(), 0);
  });
}
