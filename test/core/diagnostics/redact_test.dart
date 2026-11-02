import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/diagnostics/redact.dart';

void main() {
  const salt = '00112233445566778899aabbccddeeff';
  String r(String s) => redactForLog(s, salt);
  final token = RegExp('#[0-9a-f]{6}');

  test('internal storage keeps the first folder and the extension', () {
    final out = r('/storage/emulated/0/DCIM/Holiday Paris/IMG_0001.jpg');
    expect(out, startsWith('[int]/DCIM/#'));
    expect(out, endsWith('.jpg'));
    expect(out, isNot(contains('Holiday')));
    expect(out, isNot(contains('IMG_0001')));
    expect(token.allMatches(out), hasLength(2));
  });

  test('SD card, /sdcard and /storage/self/primary', () {
    expect(
      r('/storage/1234-ABCD/Pictures/a/b.png'),
      matches(r'^\[sd\]/Pictures/#[0-9a-f]{6}/#[0-9a-f]{6}\.png$'),
    );
    expect(
      r('/sdcard/Download/secret.pdf'),
      matches(r'^\[int\]/Download/#[0-9a-f]{6}\.pdf$'),
    );
    expect(r('/storage/self/primary/DCIM'), '[int]/DCIM');
    expect(r('/storage/emulated/0'), '[int]');
  });

  test("KFM's own folder is kept", () {
    expect(
      r('/data/user/0/com.kaf.kfm/files/logs/errors.log'),
      '[app]/files/logs/errors.log',
    );
    expect(r('/data/data/com.kaf.kfm/cache/x.tmp'), '[app]/cache/x.tmp');
  });

  test('ids, URIs and stack frames are left alone', () {
    const kept = [
      'content://media/external/images/media/123',
      'ms:4711',
      '#0      Foo.bar (package:kfm/core/files/x.dart:10:5)',
      '#1      _rootRun (dart:async/zone.dart:1525:47)',
      r'C:\Users\me\Pictures\a.jpg',
      'file:///C:/src/flutter/packages/flutter/lib/src/widgets/framework.dart',
      'copied 3/4 files',
    ];
    for (final s in kept) {
      expect(r(s), s, reason: s);
    }
  });

  test('path: ids and paths inside messages', () {
    final out = r(
      'FileSystemException: Cannot open file, path = '
      "'/storage/emulated/0/DCIM/Camera/Bob at beach.jpg' "
      '(OS Error: No such file or directory, errno = 2)',
    );
    expect(out, contains("'[int]/DCIM/#"));
    expect(out, contains(".jpg' (OS Error"));
    expect(out, isNot(contains('Camera')));
    expect(out, isNot(contains('Bob')));

    final id = r('not found: path:/storage/emulated/0/Download/x/report.txt');
    expect(
      id,
      matches(
        r'^not found: path:\[int\]/Download/#[0-9a-f]{6}/#[0-9a-f]{6}\.txt$',
      ),
    );
  });

  test('unknown absolute paths hash every segment after the first', () {
    final out = r('at /mnt/media_rw/USB Stick/Private/a.mp4');
    expect(
      out,
      matches(
        r'^at /mnt/#[0-9a-f]{6}/#[0-9a-f]{6}/#[0-9a-f]{6}/#[0-9a-f]{6}\.mp4$',
      ),
    );
  });

  test('the same salt gives the same token, another salt another', () {
    const p = '/storage/emulated/0/DCIM/Camera/a.jpg';
    expect(r(p), r(p));
    expect(redactForLog(p, 'other'), isNot(r(p)));
    // The same folder in two paths maps to the same token.
    final a = r('/storage/emulated/0/DCIM/Camera/a.jpg').split('/')[2];
    final b = r('/storage/emulated/0/DCIM/Camera/b.jpg').split('/')[2];
    expect(a, b);
  });

  test('multi-line text is redacted per line', () {
    final out = r(
      'first /storage/emulated/0/DCIM/A/x.jpg\n'
      'second /storage/emulated/0/DCIM/B/y.jpg',
    );
    expect(out.split('\n'), hasLength(2));
    expect(out, isNot(contains('/A/')));
    expect(out, isNot(contains('/B/')));
  });
}
