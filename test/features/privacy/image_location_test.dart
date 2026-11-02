import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:kfm/features/privacy/domain/image_location.dart';
import 'package:kfm/features/privacy/domain/mp4_location_stripper.dart';
import 'package:kfm/features/privacy/domain/tiff_location.dart';
import 'package:kfm/features/privacy/domain/xmp_location.dart';

import 'location_fixtures.dart';

void main() {
  group('JPEG EXIF', () {
    test('GPS goes, the rest of EXIF and the image stay', () {
      final input = jpegWithGps();
      final before = img.decodeJpgExif(input)!;
      expect(before.gpsIfd.gpsLatitude, isNotNull);

      final out = stripImageLocation(Uint8List.fromList(input));

      expect(out.length, input.length);
      final after = img.decodeJpgExif(out)!;
      expect(after.gpsIfd.hasGPSLatitude, isFalse);
      expect(after.gpsIfd.hasGPSLongitude, isFalse);
      expect(after.imageIfd.make, 'KFM Camera');
      expect(img.decodeJpg(out), isNotNull);
      expect(imageHasLocation(out), isFalse);
      expect(imageHasLocation(input), isTrue);
    });

    test('the same photo always gives the same bytes', () {
      final input = jpegWithGps();
      final a = stripImageLocation(Uint8List.fromList(input));
      final b = stripImageLocation(Uint8List.fromList(input));
      expect(a, b);
      // Stripping again changes nothing.
      expect(stripImageLocation(Uint8List.fromList(a)), a);
    });

    test('a photo without location comes out byte-identical', () {
      final input = plainJpeg();
      expect(stripImageLocation(Uint8List.fromList(input)), input);
    });
  });

  group('TIFF blocks', () {
    for (final little in [false, true]) {
      test('${little ? 'little' : 'big'}-endian GPS IFD is removed', () {
        final tiff = tiffWithGps(little: little);
        final bytes = Uint8List.fromList([
          ...List.filled(13, 7),
          ...tiff,
          ...List.filled(9, 7),
        ]);
        expect(hasTiffGps(bytes), isTrue);
        expect(stripTiffGps(bytes), 1);
        expect(hasTiffGps(bytes), isFalse);
        // The GPS values (52/1 22/1 12/1) are zeroed.
        final gpsData = bytes.sublist(13 + 80, 13 + 104);
        expect(gpsData.every((b) => b == 0), isTrue);
        // Make "KFM" is still in IFD0 (now 1 entry).
        const ifd0 = 13 + 8;
        final count = little
            ? bytes[ifd0] | bytes[ifd0 + 1] << 8
            : bytes[ifd0] << 8 | bytes[ifd0 + 1];
        expect(count, 1);
        expect(latin1.decode(bytes.sublist(ifd0 + 10, ifd0 + 13)), 'KFM');
      });
    }

    test('HEIF-like file: the Exif item is found anywhere', () {
      final bytes = Uint8List.fromList([
        ...box('ftyp', latin1.encode('heicmif1')),
        ...box('mdat', [
          0,
          0,
          0,
          6,
          ...latin1.encode('Exif'),
          0,
          0,
          ...tiffWithGps(),
          ...List.filled(40, 3),
        ]),
      ]);
      final out = stripImageLocation(bytes);
      expect(out.length, bytes.length);
      expect(hasTiffGps(out), isFalse);
    });
  });

  group('XMP', () {
    test('JPEG with XMP-only GPS (attributes) is cleaned', () {
      final input = jpegWithXmp(plainJpeg(), xmpAttributes);
      expect(imageHasLocation(input), isTrue);

      final out = stripImageLocation(Uint8List.fromList(input));

      expect(out.length, input.length);
      final text = latin1.decode(out);
      expect(text, isNot(contains('GPSLatitude')));
      expect(text, isNot(contains('GPSLongitude')));
      expect(text, isNot(contains('Amsterdam')));
      expect(text, contains('xmp:CreatorTool="KFM Editor"'));
      expect(text, contains('</x:xmpmeta>'));
      expect(img.decodeJpg(out), isNotNull);
    });

    test('element form, nested values included', () {
      final bytes = Uint8List.fromList(utf8.encode(xmpElements));
      expect(blankXmpLocation(bytes), 3);
      final text = utf8.decode(bytes);
      expect(text, isNot(contains('GPS')));
      expect(text, isNot(contains('rdf:Seq')));
      expect(text, contains('<xmp:CreatorTool>KFM Editor</xmp:CreatorTool>'));
      expect(text, endsWith('</rdf:Description></rdf:RDF></x:xmpmeta>'));
      expect(bytes.length, utf8.encode(xmpElements).length);
    });

    test('location text that can not be removed fails the check', () {
      // A JPEG comment segment naming GPSLatitude isn't XMP: refused.
      final jpeg = plainJpeg();
      final comment = latin1.encode('GPSLatitude 52.37');
      final input = Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xFE, 0, comment.length + 2, ...comment, //
        ...jpeg.sublist(2),
      ]);
      expect(
        () => stripImageLocation(input),
        throwsA(isA<ImageLocationException>()),
      );
    });
  });

  group('PNG', () {
    test('eXIf GPS and iTXt XMP are cleaned, CRCs fixed', () {
      final itxt = [
        ...latin1.encode('XML:com.adobe.xmp'),
        0, 0, 0, 0, 0, //
        ...utf8.encode(xmpAttributes),
      ];
      final input = pngWith([
        pngChunk('eXIf', tiffWithGps()),
        pngChunk('iTXt', itxt),
      ]);
      expect(imageHasLocation(input), isTrue);

      final out = stripImageLocation(Uint8List.fromList(input));

      expect(out.length, input.length);
      expect(pngCrcsValid(out), isTrue);
      expect(hasTiffGps(out), isFalse);
      expect(latin1.decode(out), isNot(contains('GPSLatitude')));
      expect(img.decodePng(out), isNotNull);
    });

    test('a compressed XMP chunk with GPS is dropped', () {
      final compressed = ZLibEncoder().convert(utf8.encode(xmpElements));
      final itxt = [
        ...latin1.encode('XML:com.adobe.xmp'),
        0, 1, 0, 0, 0, //
        ...compressed,
      ];
      final input = pngWith([pngChunk('iTXt', itxt)]);
      expect(imageHasLocation(input), isTrue);

      final out = stripImageLocation(Uint8List.fromList(input));

      expect(out.length, input.length - (itxt.length + 12));
      expect(pngCrcsValid(out), isTrue);
      expect(imageHasLocation(out), isFalse);
      expect(img.decodePng(out), isNotNull);
    });

    test('a compressed chunk without location stays', () {
      final compressed = ZLibEncoder().convert(utf8.encode('<x:xmpmeta/>'));
      final itxt = [
        ...latin1.encode('XML:com.adobe.xmp'),
        0, 1, 0, 0, 0, //
        ...compressed,
      ];
      final input = pngWith([pngChunk('iTXt', itxt)]);
      expect(stripImageLocation(Uint8List.fromList(input)), input);
    });
  });

  test('motion photo: the video after the JPEG loses its location', () {
    final mdat = List.generate(64, (i) => i);
    final input = Uint8List.fromList([
      ...plainJpeg(),
      ...videoWithLocation(mdat),
    ]);
    expect(imageHasLocation(input), isTrue);

    final out = stripImageLocation(Uint8List.fromList(input));

    expect(out.length, input.length);
    expect(imageHasLocation(out), isFalse);
    final video = input.length - videoWithLocation(mdat).length;
    expect(stripIsoLocationBoxes(out, video, out.length, dryRun: true), 0);
    expect(img.decodeJpg(out), isNotNull);
  });
}
