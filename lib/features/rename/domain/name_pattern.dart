import 'package:kfm/core/files/file_names.dart';
import 'package:meta/meta.dart';

/// A rename pattern (TASK-P3): `{n}` counter, `{date}` the file's date
/// (yyyy-MM-dd, local), `{orig}` its original name without extension.
@immutable
class NamePattern {
  const new({required this.template, this.start = 1, this.padding = 3});

  /// Throws [FormatException] on bad data.
  factory fromJson(Map<String, Object?> j) => switch (j) {
    {'template': final String t, 'start': final int s, 'padding': final int p}
        when s >= 0 && p >= 1 && p <= maxPadding =>
      NamePattern(template: t, start: s, padding: p),
    _ => throw FormatException('Bad NamePattern: $j'),
  };

  final String template;
  final int start;

  /// Counter digits, 1..[maxPadding].
  final int padding;

  static const maxPadding = 6;

  Map<String, Object?> toJson() => {
    'template': template,
    'start': start,
    'padding': padding,
  };

  @override
  bool operator ==(Object other) =>
      other is NamePattern &&
      other.template == template &&
      other.start == start &&
      other.padding == padding;

  @override
  int get hashCode => Object.hash(template, start, padding);
}

/// What a name is built from.
typedef NameSource = ({String originalName, DateTime date});

enum PatternError { empty, invalidChars, needsCounter, tooLong }

/// Longest file name the pattern may produce.
const kMaxRenameLength = 200;

final _invalid = RegExp(r'[/\\:*?"<>|\x00-\x1f]');

/// New names in order. The extension is always the original file's
/// (MediaStore rejects extension changes).
List<String> buildNames(NamePattern p, List<NameSource> files) => [
  for (final (i, f) in files.indexed) _build(p, i, f),
];

String _build(NamePattern p, int index, NameSource f) {
  final (base, ext) = splitExtension(f.originalName);
  final d = f.date.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  final date = '${d.year}-${two(d.month)}-${two(d.day)}';
  final name = p.template
      .replaceAll('{n}', (p.start + index).toString().padLeft(p.padding, '0'))
      .replaceAll('{date}', date)
      .replaceAll('{orig}', base)
      .trim();
  return '$name$ext';
}

/// Null = valid.
PatternError? validatePattern(NamePattern p, List<NameSource> files) {
  final template = p.template.trim();
  if (template.isEmpty) return PatternError.empty;
  if (_invalid.hasMatch(template) || template == '.' || template == '..') {
    return PatternError.invalidChars;
  }
  if (files.length > 1 && !template.contains('{n}')) {
    return PatternError.needsCounter;
  }
  if (buildNames(p, files).any((n) => n.length > kMaxRenameLength)) {
    return PatternError.tooLong;
  }
  return null;
}
