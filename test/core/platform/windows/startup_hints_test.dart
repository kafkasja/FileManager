import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/platform/windows/startup_hints.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('kfm-hints-'));
  tearDown(() => dir.deleteSync(recursive: true));

  File file() => File('${dir.path}/${StartupHintsFile.fileName}');

  test('writes the lines the runner reads (startup_hints.cpp)', () async {
    final hints = StartupHintsFile(() async => dir.path);
    await hints.update(bounds: const Rect.fromLTWH(10.4, -20, 1280, 800));
    await hints.update(background: const Color(0xFF111318));
    expect(
      file().readAsStringSync().replaceAll('\r', ''),
      'bounds=10,-20,1280,800\nbackground=111318\n',
    );
  });

  test(
    'keeps the other hint and reads back what an earlier run wrote',
    () async {
      file().writeAsStringSync('bounds=1,2,900,700\nbackground=F9F9FF\n');
      final hints = StartupHintsFile(() async => dir.path);
      await hints.update(background: const Color(0xFF000000));
      final read = StartupHintsFile.parse(file().readAsStringSync());
      expect(read.bounds, const Rect.fromLTWH(1, 2, 900, 700));
      expect(read.background?.toARGB32(), 0xFF000000);
    },
  );

  test('an unchanged hint does not rewrite the file', () async {
    final hints = StartupHintsFile(() async => dir.path);
    await hints.update(background: const Color(0xFF123456));
    final before = file().lastModifiedSync();
    file().setLastModifiedSync(DateTime(2000));
    await hints.update(background: const Color(0xFF123456));
    expect(file().lastModifiedSync(), DateTime(2000));
    expect(before, isNot(DateTime(2000)));
  });

  test('garbage lines are ignored; a missing folder never throws', () async {
    final read = StartupHintsFile.parse('bounds=a,b\nbackground=zz\nfoo=1');
    expect(read.bounds, isNull);
    expect(read.background, isNull);
    final hints = StartupHintsFile(() async => '${dir.path}/missing/deeper');
    await hints.update(bounds: const Rect.fromLTWH(0, 0, 800, 600));
  });
}
