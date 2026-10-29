import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';

/// The text viewer reads at most this much (TASK-B1).
const int kTextViewerMaxBytes = 1024 * 1024;

@immutable
sealed class TextPreview {
  const new();
}

class TextPreviewText extends TextPreview {
  const new(this.text, {required this.truncated, required this.latin1});

  final String text;

  /// Only the first [kTextViewerMaxBytes] were read.
  final bool truncated;

  /// Not valid UTF-8: shown as Latin-1.
  final bool latin1;
}

/// Too many control bytes to be text.
class TextPreviewBinary extends TextPreview {
  const new();
}

/// Decodes the start of a file. BOM → UTF-8 / UTF-16LE / UTF-16BE; else
/// strict UTF-8, falling back to Latin-1. [truncated]: [bytes] is a prefix,
/// so a multi-byte sequence cut at the end is dropped first. Pure; run it
/// in an isolate.
TextPreview decodeTextPreview(Uint8List bytes, {required bool truncated}) {
  if (_startsWith(bytes, const [0xEF, 0xBB, 0xBF])) {
    final body = Uint8List.sublistView(bytes, 3);
    return _utf8OrLatin1(truncated ? _trimCutUtf8(body) : body, truncated);
  }
  if (_startsWith(bytes, const [0xFF, 0xFE])) {
    return TextPreviewText(
      _utf16(bytes, littleEndian: true),
      truncated: truncated,
      latin1: false,
    );
  }
  if (_startsWith(bytes, const [0xFE, 0xFF])) {
    return TextPreviewText(
      _utf16(bytes, littleEndian: false),
      truncated: truncated,
      latin1: false,
    );
  }
  if (_looksBinary(bytes)) return const TextPreviewBinary();
  return _utf8OrLatin1(truncated ? _trimCutUtf8(bytes) : bytes, truncated);
}

TextPreview _utf8OrLatin1(Uint8List bytes, bool truncated) {
  try {
    return TextPreviewText(
      utf8.decode(bytes),
      truncated: truncated,
      latin1: false,
    );
  } on FormatException {
    return TextPreviewText(
      latin1.decode(bytes),
      truncated: truncated,
      latin1: true,
    );
  }
}

String _utf16(Uint8List bytes, {required bool littleEndian}) {
  final units = <int>[];
  // Skips the BOM; an odd last byte (cut) is dropped.
  for (var i = 2; i + 1 < bytes.length; i += 2) {
    units.add(
      littleEndian
          ? bytes[i] | (bytes[i + 1] << 8)
          : (bytes[i] << 8) | bytes[i + 1],
    );
  }
  return String.fromCharCodes(units);
}

/// > 10% NUL/control bytes (other than tab, CR, LF) in the first 8 KiB.
bool _looksBinary(Uint8List bytes) {
  final n = bytes.length < 8192 ? bytes.length : 8192;
  if (n == 0) return false;
  var control = 0;
  for (var i = 0; i < n; i++) {
    final b = bytes[i];
    if (b < 0x20 && b != 0x09 && b != 0x0A && b != 0x0D) control++;
  }
  return control * 10 > n;
}

/// Drops a UTF-8 sequence cut off at the end of [bytes].
Uint8List _trimCutUtf8(Uint8List bytes) {
  // Look back at most 3 bytes for the start of the last sequence.
  for (var back = 1; back <= 3 && back <= bytes.length; back++) {
    final b = bytes[bytes.length - back];
    if (b & 0xC0 == 0x80) continue; // continuation byte
    final length = b >= 0xF0
        ? 4
        : b >= 0xE0
        ? 3
        : b >= 0xC0
        ? 2
        : 1;
    return length > back
        ? Uint8List.sublistView(bytes, 0, bytes.length - back)
        : bytes;
  }
  return bytes;
}

bool _startsWith(Uint8List bytes, List<int> prefix) {
  if (bytes.length < prefix.length) return false;
  for (var i = 0; i < prefix.length; i++) {
    if (bytes[i] != prefix[i]) return false;
  }
  return true;
}
