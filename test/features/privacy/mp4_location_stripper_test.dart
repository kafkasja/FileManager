import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/privacy/domain/mp4_location_stripper.dart';

import 'location_fixtures.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('kfm_mp4_'));
  tearDown(() => dir.deleteSync(recursive: true));

  final mdat = List.generate(4096, (i) => (i * 31) & 0xFF);

  for (final isoMeta in [false, true]) {
    test('every location box goes, media bytes stay '
        '(${isoMeta ? 'ISO' : 'QuickTime'} meta)', () async {
      final input = videoWithLocation(mdat, isoMeta: isoMeta);
      expect(stripIsoLocationBoxes(input, 0, input.length, dryRun: true), 5);
      final file = writeTemp(dir, 'v.mov', input);

      final n = await stripMp4LocationInPlace(file.path);

      expect(n, greaterThanOrEqualTo(5));
      final out = file.readAsBytesSync();
      expect(out.length, input.length);
      expect(stripIsoLocationBoxes(out, 0, out.length, dryRun: true), 0);
      final text = latin1.decode(out);
      expect(text, isNot(contains('©xyz')));
      expect(text, isNot(contains('loci')));
      expect(text, isNot(contains('ISO6709')));
      expect(text, isNot(contains('+52.37')));
      expect(text, isNot(contains('GPSLatitude')));
      // Unrelated metadata stays.
      expect(text, contains('com.apple.quicktime.make'));
      expect(text, contains('Apple'));
      expect(text, contains('KFM Editor'));
      // The mdat payload is unchanged.
      final at = text.indexOf('mdat') + 4;
      expect(out.sublist(at, at + mdat.length), mdat);
    });
  }

  test('the same video always gives the same bytes', () async {
    final a = writeTemp(dir, 'a.mp4', videoWithLocation(mdat));
    final b = writeTemp(dir, 'b.mp4', videoWithLocation(mdat));
    await stripMp4LocationInPlace(a.path);
    await stripMp4LocationInPlace(b.path);
    expect(a.readAsBytesSync(), b.readAsBytesSync());
    // Again: nothing left to change.
    expect(await stripMp4LocationInPlace(a.path), 0);
  });

  test('not ISO-BMFF is refused', () async {
    final file = writeTemp(dir, 'x.mkv', [
      0x1A, 0x45, 0xDF, 0xA3, ...List.filled(60, 1), //
    ]);
    await expectLater(
      stripMp4LocationInPlace(file.path),
      throwsA(isA<Mp4FormatException>()),
    );
  });

  test('a file without moov is refused', () async {
    final file = writeTemp(dir, 'm.mp4', [
      ...box('ftyp', latin1.encode('isom')),
      ...box('mdat', mdat),
    ]);
    await expectLater(
      stripMp4LocationInPlace(file.path),
      throwsA(isA<Mp4FormatException>()),
    );
  });

  test('a truncated box is refused', () async {
    final full = videoWithLocation(mdat);
    final file = writeTemp(
      dir,
      't.mp4',
      Uint8List.sublistView(full, 0, full.length - 10),
    );
    await expectLater(
      stripMp4LocationInPlace(file.path),
      throwsA(isA<Mp4FormatException>()),
    );
  });
}
