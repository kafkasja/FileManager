// XMP test data is split over adjacent strings exactly as written.
// ignore_for_file: missing_whitespace_between_adjacent_strings

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart' show getCrc32;
import 'package:image/image.dart' as img;

/// Test photos and videos with location (TASK-X2), built in code so every
/// byte is known.

/// A small JPEG whose EXIF has a camera make and a GPS position.
Uint8List jpegWithGps({double lat = 52.37, double lng = 4.89}) {
  final image = img.Image(width: 16, height: 16);
  img.fill(image, color: img.ColorRgb8(200, 30, 30));
  image.exif.imageIfd.make = 'KFM Camera';
  image.exif.gpsIfd.setGpsLocation(latitude: lat, longitude: lng);
  return img.encodeJpg(image);
}

/// A plain JPEG without metadata.
Uint8List plainJpeg() {
  final image = img.Image(width: 16, height: 16);
  img.fill(image, color: img.ColorRgb8(10, 120, 30));
  return img.encodeJpg(image);
}

const String xmpAttributes =
    '<?xpacket begin="" id="W5M0MpCehiHzreSzNTczkc9d"?>'
    '<x:xmpmeta xmlns:x="adobe:ns:meta/"><rdf:RDF '
    'xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">'
    '<rdf:Description rdf:about="" xmlns:exif="http://ns.adobe.com/exif/1.0/" '
    'xmlns:xmp="http://ns.adobe.com/xap/1.0/" '
    'xmlns:photoshop="http://ns.adobe.com/photoshop/1.0/" '
    'xmp:CreatorTool="KFM Editor" exif:GPSLatitude="52,22.2N" '
    'exif:GPSLongitude="4,53.4E" photoshop:City="Amsterdam"/>'
    '</rdf:RDF></x:xmpmeta><?xpacket end="w"?>';

const String xmpElements =
    '<x:xmpmeta xmlns:x="adobe:ns:meta/"><rdf:RDF '
    'xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">'
    '<rdf:Description rdf:about="" xmlns:exif="http://ns.adobe.com/exif/1.0/" '
    'xmlns:xmp="http://ns.adobe.com/xap/1.0/">'
    '<xmp:CreatorTool>KFM Editor</xmp:CreatorTool>'
    '<exif:GPSLatitude>52,22.2N</exif:GPSLatitude>\n'
    '<exif:GPSLongitude>4,53.4E</exif:GPSLongitude>'
    '<exif:GPSAltitude><rdf:Seq><rdf:li>3/1</rdf:li></rdf:Seq>'
    '</exif:GPSAltitude>'
    '</rdf:Description></rdf:RDF></x:xmpmeta>';

/// [jpeg] with an XMP `APP1` segment right after SOI.
Uint8List jpegWithXmp(Uint8List jpeg, String xmp) {
  final payload = [
    ...latin1.encode('http://ns.adobe.com/xap/1.0/'),
    0,
    ...utf8.encode(xmp),
  ];
  final len = payload.length + 2;
  return Uint8List.fromList([
    0xFF, 0xD8, 0xFF, 0xE1, len >> 8, len & 0xFF, ...payload, //
    ...jpeg.sublist(2),
  ]);
}

/// A TIFF block (big- or little-endian) with IFD0 {Make, GPS pointer} and
/// a GPS IFD {LatitudeRef, Latitude (3 rationals), LongitudeRef}.
Uint8List tiffWithGps({bool little = false}) {
  final b = BytesBuilder();
  final bd = ByteData(200);
  final e = little ? Endian.little : Endian.big;
  var p = 0;
  void u8(int v) => bd.setUint8(p++, v);
  void u16(int v) {
    bd.setUint16(p, v, e);
    p += 2;
  }

  void u32(int v) {
    bd.setUint32(p, v, e);
    p += 4;
  }

  if (little) {
    u8(0x49);
    u8(0x49);
  } else {
    u8(0x4D);
    u8(0x4D);
  }
  u16(42);
  u32(8);
  // IFD0 at 8: 2 entries → ends at 8 + 2 + 24 + 4 = 38.
  u16(2);
  u16(0x010F); // Make, ASCII, 4 bytes inline "KFM\0"
  u16(2);
  u32(4);
  'KFM\u0000'.codeUnits.forEach(u8);
  u16(0x8825); // GPS pointer → 38
  u16(4);
  u32(1);
  u32(38);
  u32(0); // next IFD
  // GPS IFD at 38: 3 entries → ends at 38 + 2 + 36 + 4 = 80; data at 80.
  u16(3);
  u16(1); // LatitudeRef 'N'
  u16(2);
  u32(2);
  u8(0x4E);
  u8(0);
  u8(0);
  u8(0);
  u16(2); // Latitude, 3 rationals at 80
  u16(5);
  u32(3);
  u32(80);
  u16(3); // LongitudeRef 'E'
  u16(2);
  u32(2);
  u8(0x45);
  u8(0);
  u8(0);
  u8(0);
  u32(0);
  [52, 1, 22, 1, 12, 1].forEach(u32);
  b.add(bd.buffer.asUint8List(0, p));
  return b.takeBytes();
}

/// One PNG chunk with its CRC.
List<int> pngChunk(String type, List<int> data) {
  final body = [...latin1.encode(type), ...data];
  final crc = getCrc32(body);
  final out = ByteData(4)..setUint32(0, data.length);
  final c = ByteData(4)..setUint32(0, crc);
  return [...out.buffer.asUint8List(), ...body, ...c.buffer.asUint8List()];
}

/// A PNG with extra chunks inserted before IEND.
Uint8List pngWith(List<List<int>> chunks) {
  final image = img.Image(width: 8, height: 8);
  final png = img.encodePng(image);
  // IEND is the last 12 bytes.
  final end = png.length - 12;
  return Uint8List.fromList([
    ...png.sublist(0, end),
    for (final c in chunks) ...c,
    ...png.sublist(end),
  ]);
}

/// Every PNG chunk's CRC is right.
bool pngCrcsValid(Uint8List b) {
  final bd = ByteData.sublistView(b);
  var at = 8;
  while (at + 12 <= b.length) {
    final len = bd.getUint32(at);
    final crc = getCrc32(b.sublist(at + 4, at + 8 + len));
    if (crc != bd.getUint32(at + 8 + len)) return false;
    at += 12 + len;
  }
  return at == b.length;
}

/// ISO-BMFF box.
List<int> box(String type, List<int> payload) {
  final size = ByteData(4)..setUint32(0, 8 + payload.length);
  return [...size.buffer.asUint8List(), ...latin1.encode(type), ...payload];
}

List<int> _u32(int v) => (ByteData(4)..setUint32(0, v)).buffer.asUint8List();

/// A QuickTime/MP4 video with every location kind KFM removes: `©xyz` in
/// `moov/udta`, `loci` in `trak/udta`, Apple `keys`/`ilst`
/// (`com.apple.quicktime.location.ISO6709` + a make key that stays), and an
/// XMP `uuid` box. [isoMeta]: `meta` as an ISO full box instead of the
/// QuickTime form. [mdat] is the media payload (must stay unchanged).
Uint8List videoWithLocation(List<int> mdat, {bool isoMeta = false}) {
  final keys = box('keys', [
    0, 0, 0, 0, ..._u32(2), //
    ..._u32(8 + 36), ...latin1.encode('mdta'),
    ...latin1.encode('com.apple.quicktime.location.ISO6709'),
    ..._u32(8 + 24), ...latin1.encode('mdta'),
    ...latin1.encode('com.apple.quicktime.make'),
  ]);
  List<int> item(int index, String value) {
    final data = box('data', [0, 0, 0, 1, 0, 0, 0, 0, ...utf8.encode(value)]);
    return [..._u32(8 + data.length), ..._u32(index), ...data];
  }

  final ilst = box('ilst', [
    ...item(1, '+52.3700+004.8900+000.000/'),
    ...item(2, 'Apple'),
  ]);
  final hdlr = box('hdlr', [0, 0, 0, 0, ...List.filled(20, 0)]);
  final meta = box('meta', [
    if (isoMeta) ...[0, 0, 0, 0],
    ...hdlr,
    ...keys,
    ...ilst,
  ]);
  final xyz = box('©xyz', [
    0,
    18,
    0x15,
    0xC7,
    ...latin1.encode('+52.37+004.89/'),
  ]);
  final loci = box('loci', [
    0,
    0,
    0,
    0,
    0x15,
    0xC7,
    ...latin1.encode('Home'),
    0,
  ]);
  final mvhd = box('mvhd', List.filled(100, 0));
  final trak = box('trak', [
    ...box('tkhd', List.filled(84, 0)),
    ...box('udta', loci),
  ]);
  final moov = box('moov', [...mvhd, ...trak, ...box('udta', xyz), ...meta]);
  final xmpUuid = [
    0xBE, 0x7A, 0xCF, 0xCB, 0x97, 0xA9, 0x42, 0xE8, //
    0x9C, 0x71, 0x99, 0x94, 0x91, 0xE3, 0xAF, 0xAC,
  ];
  final uuid = box('uuid', [...xmpUuid, ...utf8.encode(xmpAttributes)]);
  return Uint8List.fromList([
    ...box('ftyp', [...latin1.encode('qt  '), 0, 0, 0, 0]),
    ...box('mdat', mdat),
    ...moov,
    ...uuid,
  ]);
}

/// A temp file with [bytes]; deleted at tear-down by the caller's dir.
File writeTemp(Directory dir, String name, List<int> bytes) =>
    File('${dir.path}/$name')..writeAsBytesSync(bytes);
