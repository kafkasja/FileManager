import 'dart:convert';
import 'dart:typed_data';

/// XMP properties that carry a location (TASK-X2): every `*:GPS…` property
/// (`exif:GPSLatitude`, `exifEX:GPS…`), and the IPTC/Photoshop place names.
const String _locationName =
    r'(?:[A-Za-z][\w.-]*:GPS[A-Za-z]*'
    '|photoshop:(?:City|State|Country)'
    '|Iptc4xmpCore:(?:Location|CountryCode)'
    '|Iptc4xmpExt:(?:LocationCreated|LocationShown))';

/// `name="value"` / `name='value'` inside a start tag.
final RegExp _attribute = RegExp(
  '(?<=\\s)$_locationName\\s*=\\s*(?:"[^"]*"|\'[^\']*\')',
);

/// `<name …/>` or `<name …>…</name>` (the content may be nested elements).
final RegExp _element = RegExp(
  '<($_locationName)(?=[\\s/>])[^>]*?(?:/>|>[\\s\\S]*?</\\1\\s*>)',
);

/// Text that proves location is still there (the byte scan of the plan).
final RegExp _leftover = RegExp('GPSLatitude|GPSLongitude|ISO6709');

/// Overwrites every XMP location property in `bytes[start, end)` with
/// spaces, in place: the length never changes, so offsets around it (box and
/// chunk sizes) stay valid and the XML stays well-formed. Returns how many
/// properties were blanked.
int blankXmpLocation(Uint8List bytes, [int start = 0, int? end]) {
  final stop = end ?? bytes.length;
  if (stop - start < 8) return 0;
  // Latin-1 maps each byte to one code unit, so string indexes are offsets.
  final text = latin1.decode(Uint8List.sublistView(bytes, start, stop));
  if (!text.contains('GPS') &&
      !text.contains('photoshop:') &&
      !text.contains('Iptc4xmp')) {
    return 0;
  }
  var count = 0;
  for (final re in [_element, _attribute]) {
    for (final m in re.allMatches(text)) {
      // An attribute inside an element blanked before is spaces now.
      if (bytes[start + m.start] == 0x20) continue;
      bytes.fillRange(start + m.start, start + m.end, 0x20);
      count++;
    }
  }
  return count;
}

/// Whether `bytes[start, end)` still contains `GPSLatitude`, `GPSLongitude`
/// or an Apple `ISO6709` location key as text.
bool hasLocationText(Uint8List bytes, [int start = 0, int? end]) {
  final stop = end ?? bytes.length;
  if (stop <= start) return false;
  return _leftover.hasMatch(
    latin1.decode(Uint8List.sublistView(bytes, start, stop)),
  );
}
