import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/features/privacy/data/copying_location_stripper.dart';
import 'package:kfm/features/privacy/data/privacy_transfer_preprocessor.dart';
import 'package:kfm/features/privacy/domain/location_stripper.dart';
import 'package:kfm/features/transfers/data/transfer_run.dart';
import 'package:kfm/features/transfers/domain/transfer_job.dart';
import 'package:kfm/features/transfers/domain/transfer_preprocessor.dart';

import '../../core/files/fake_file_source.dart';
import 'location_fixtures.dart';

FileRef _ref(File f, {FileKind kind = FileKind.image}) => FileRef(
  id: 'path:${f.path}',
  uri: f.path,
  name: f.uri.pathSegments.last,
  kind: kind,
  sizeBytes: f.lengthSync(),
  modifiedAt: DateTime.utc(2026, 11, 2),
  folderPath: f.parent.path,
  origin: FileOrigin.local,
);

void main() {
  late Directory dir;
  late Directory root;
  late CopyingLocationStripper stripper;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('kfm_privacy_');
    root = Directory('${dir.path}/cache/privacy');
    stripper = CopyingLocationStripper(
      root: () async => root,
      copy: (f, out) => File(f.path).copy(out),
    );
  });
  tearDown(() => dir.deleteSync(recursive: true));

  group('CopyingLocationStripper', () {
    test('copies into <root>/<sendId>/, the original keeps its GPS', () async {
      final original = writeTemp(dir, 'IMG_1.jpg', jpegWithGps());
      final before = original.readAsBytesSync();

      final copy = await stripper.stripToTemp(_ref(original), sendId: 's1');

      expect(copy.path, '${root.path}/s1/IMG_1.jpg');
      expect(copy.isTemp, isTrue);
      expect(copy.sizeBytes, File(copy.path).lengthSync());
      expect(original.readAsBytesSync(), before);
      expect(img.decodeJpgExif(before)!.gpsIfd.hasGPSLatitude, isTrue);
      final out = File(copy.path).readAsBytesSync();
      expect(img.decodeJpgExif(out)!.gpsIfd.hasGPSLatitude, isFalse);

      await stripper.release('s1');
      expect(Directory('${root.path}/s1').existsSync(), isFalse);
    });

    test('two files with one name in a send get their own copy', () async {
      final a = writeTemp(Directory(dir.path), 'IMG.jpg', jpegWithGps());
      final sub = Directory('${dir.path}/sub')..createSync();
      final b = writeTemp(sub, 'IMG.jpg', jpegWithGps(lat: 1));
      final ca = await stripper.stripToTemp(_ref(a), sendId: 's');
      final cb = await stripper.stripToTemp(_ref(b), sendId: 's');
      expect(ca.path, endsWith('/IMG.jpg'));
      expect(cb.path, endsWith('/IMG (2).jpg'));
    });

    test('videos are stripped too', () async {
      final v = writeTemp(dir, 'VID.mp4', videoWithLocation([1, 2, 3, 4]));
      final copy = await stripper.stripToTemp(
        _ref(v, kind: FileKind.video),
        sendId: 'v',
      );
      final text = latin1.decode(File(copy.path).readAsBytesSync());
      expect(text, isNot(contains('ISO6709')));
      expect(copy.sizeBytes, v.lengthSync());
    });

    test('location that stays → stillHasLocation, no copy left', () async {
      final jpeg = plainJpeg();
      final comment = latin1.encode('GPSLatitude 52.37');
      final f = writeTemp(dir, 'bad.jpg', [
        0xFF, 0xD8, 0xFF, 0xFE, 0, comment.length + 2, ...comment, //
        ...jpeg.sublist(2),
      ]);
      await expectLater(
        stripper.stripToTemp(_ref(f), sendId: 'b'),
        throwsA(
          isA<LocationStripException>().having(
            (e) => e.reason,
            'reason',
            LocationStripFailure.stillHasLocation,
          ),
        ),
      );
      expect(Directory('${root.path}/b').listSync(), isEmpty);
    });

    test('a damaged video → unsupportedFormat', () async {
      final v = writeTemp(dir, 'VID.mp4', [
        ...box('ftyp', latin1.encode('isom')),
        ...box('mdat', [1, 2, 3]),
      ]);
      await expectLater(
        stripper.stripToTemp(_ref(v, kind: FileKind.video), sendId: 'd'),
        throwsA(
          isA<LocationStripException>().having(
            (e) => e.reason,
            'reason',
            LocationStripFailure.unsupportedFormat,
          ),
        ),
      );
    });

    test('an unreadable file → readFailed', () async {
      final gone = File('${dir.path}/gone.jpg');
      final ref = FileRef(
        id: 'path:${gone.path}',
        uri: gone.path,
        name: 'gone.jpg',
        kind: FileKind.image,
        sizeBytes: 1,
        modifiedAt: DateTime.utc(2026),
        folderPath: dir.path,
        origin: FileOrigin.local,
      );
      await expectLater(
        stripper.stripToTemp(ref, sendId: 'g'),
        throwsA(
          isA<LocationStripException>().having(
            (e) => e.reason,
            'reason',
            LocationStripFailure.readFailed,
          ),
        ),
      );
    });

    test('purgeOlderThan deletes sends from before the cutoff', () async {
      final old = Directory('${root.path}/share-old')
        ..createSync(recursive: true);
      File('${old.path}/a.jpg').writeAsBytesSync([1]);
      final past = DateTime.now().subtract(const Duration(hours: 1));
      expect(await stripper.purgeOlderThan(past), 0);
      expect(old.existsSync(), isTrue);
      final future = DateTime.now().add(const Duration(hours: 1));
      expect(await stripper.purgeOlderThan(future), 1);
      expect(old.existsSync(), isFalse);
    });
  });

  group('PrivacyTransferPreprocessor', () {
    late FakeFileSource source;
    setUp(() => source = FakeFileSource());
    tearDown(() => source.dispose());

    Future<List<int>> readAll(PreparedSource p) async => [
      for (final c in await p.read(0, p.sizeBytes).toList()) ...c,
    ];

    test('off: the file is sent as it is', () async {
      final f = writeTemp(dir, 'IMG.jpg', jpegWithGps());
      final p = PrivacyTransferPreprocessor(
        enabled: () async => false,
        stripper: stripper,
        fallback: const _AsItIs(),
      );
      final prepared = await p.prepare(_ref(f), source);
      expect(prepared.path, f.path);
      expect(root.existsSync(), isFalse);
    });

    test('on: a stripped copy, the same bytes every attempt, '
        'deleted after each', () async {
      final f = writeTemp(dir, 'IMG.jpg', jpegWithGps());
      final p = PrivacyTransferPreprocessor(
        enabled: () async => true,
        stripper: stripper,
      );
      final first = await p.prepare(_ref(f), source);
      final a = await readAll(first);
      expect(first.path, isNot(f.path));
      expect(
        img.decodeJpgExif(Uint8List.fromList(a))!.gpsIfd.hasGPSLatitude,
        false,
      );
      await first.cleanup();
      expect(File(first.path!).existsSync(), isFalse);

      final second = await p.prepare(_ref(f), source);
      expect(second.sizeBytes, first.sizeBytes);
      expect(await readAll(second), a);
      await second.cleanup();
      expect(root.listSync(), isEmpty);
    });

    test('on: other files are sent as they are', () async {
      final f = writeTemp(dir, 'notes.txt', utf8.encode('GPSLatitude'));
      final p = PrivacyTransferPreprocessor(
        enabled: () async => true,
        stripper: stripper,
        fallback: const _AsItIs(),
      );
      final prepared = await p.prepare(
        _ref(f, kind: FileKind.document),
        source,
      );
      expect(prepared.path, f.path);
    });

    test('on: location that stays fails the file', () async {
      final jpeg = plainJpeg();
      final comment = latin1.encode('GPSLongitude 4.89');
      final f = writeTemp(dir, 'bad.jpg', [
        0xFF, 0xD8, 0xFF, 0xFE, 0, comment.length + 2, ...comment, //
        ...jpeg.sublist(2),
      ]);
      final p = PrivacyTransferPreprocessor(
        enabled: () async => true,
        stripper: stripper,
      );
      await expectLater(
        p.prepare(_ref(f), source),
        throwsA(
          isA<TransferFailure>().having(
            (e) => e.code,
            'code',
            TransferErrors.locationNotRemoved,
          ),
        ),
      );
      expect(root.listSync(), isEmpty);
    });
  });
}

/// The fallback: the file itself.
class _AsItIs implements TransferPreprocessor {
  const new();

  @override
  Future<PreparedSource> prepare(FileRef f, FileSource source) async =>
      PreparedSource(
        sizeBytes: f.sizeBytes,
        path: f.path,
        read: (start, end) => File(f.path).openRead(start, end),
      );
}
