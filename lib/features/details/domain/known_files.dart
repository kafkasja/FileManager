import 'dart:convert';

import 'package:meta/meta.dart';

/// A soft hint shown under an explanation (TASK-B10). It never triggers
/// anything and is never worded as a recommendation to delete.
enum DeletableHint { usually, careful, unknown }

/// One "What is this?" explanation.
@immutable
class KnownFileKind {
  const new({
    required this.id,
    required this.title,
    required this.body,
    this.deletable = DeletableHint.unknown,
  });

  final String id;
  final String title;
  final String body;
  final DeletableHint deletable;

  @override
  bool operator ==(Object other) =>
      other is KnownFileKind &&
      other.id == id &&
      other.title == title &&
      other.body == body &&
      other.deletable == deletable;

  @override
  int get hashCode => Object.hash(id, title, body, deletable);
}

/// A glob → kind rule. [inFolder]: names rules only, an extra folder glob
/// one of the file's folders must match.
@immutable
class KnownFileRule {
  new(this.glob, this.kind, {this.inFolder})
    : _re = globToRegExp(glob),
      _inRe = inFolder == null ? null : globToRegExp(inFolder);

  final String glob;
  final String kind;
  final String? inFolder;
  final RegExp _re;
  final RegExp? _inRe;
}

/// The "What is this?" table (`assets/details/known_files_<lang>.json`).
/// Match priority: `names` > `folders` > `extensions`. Paths are matched
/// volume-relative and lower case ('android/media/com.whatsapp/…').
@immutable
class KnownFiles {
  const new({
    required this.extensions,
    required this.names,
    required this.folders,
    required this.kinds,
  });

  /// Throws [FormatException] on a malformed file.
  factory parse(String text) {
    final root = jsonDecode(text);
    if (root is! Map<String, Object?>) {
      throw const FormatException('known files: not an object');
    }
    Map<String, Object?> obj(Object? v, String what) =>
        v is Map<String, Object?>
        ? v
        : throw FormatException('known files: $what is not an object');
    List<KnownFileRule> rules(Object? v, String what) {
      if (v is! List<Object?>) {
        throw FormatException('known files: $what is not a list');
      }
      return [
        for (final r in v)
          switch (r) {
            {'glob': final String glob, 'kind': final String kind} =>
              KnownFileRule(
                glob.toLowerCase(),
                kind,
                inFolder: switch (r['in']) {
                  final String f => f.toLowerCase(),
                  _ => null,
                },
              ),
            _ => throw FormatException('known files: bad $what rule $r'),
          },
      ];
    }

    final kinds = <String, KnownFileKind>{};
    for (final MapEntry(:key, :value) in obj(root['kinds'], 'kinds').entries) {
      final k = obj(value, 'kind $key');
      final title = k['title'];
      final body = k['body'];
      if (title is! String || body is! String) {
        throw FormatException('known files: kind $key needs title and body');
      }
      kinds[key] = KnownFileKind(
        id: key,
        title: title,
        body: body,
        deletable:
            DeletableHint.values.asNameMap()[k['deletable']] ??
            DeletableHint.unknown,
      );
    }
    return KnownFiles(
      extensions: {
        for (final MapEntry(:key, :value) in obj(
          root['extensions'],
          'extensions',
        ).entries)
          key.toLowerCase(): value is String
              ? value
              : throw FormatException('known files: extension $key'),
      },
      names: rules(root['names'], 'names'),
      folders: rules(root['folders'], 'folders'),
      kinds: kinds,
    );
  }

  final Map<String, String> extensions;
  final List<KnownFileRule> names;
  final List<KnownFileRule> folders;
  final Map<String, KnownFileKind> kinds;

  /// Every kind id a rule refers to (asset test: all must exist).
  Iterable<String> get referencedKinds => [
    ...extensions.values,
    for (final r in names) r.kind,
    for (final r in folders) r.kind,
  ];

  /// The explanation for [name] in [relFolder] (volume-relative, as from
  /// `volumeRelative`), or null. Conservative: no match → null (the sheet
  /// then shows only the MIME family).
  KnownFileKind? match(String relFolder, String name) {
    final folder = _trimSlashes(relFolder.toLowerCase());
    final lowerName = name.toLowerCase();
    final ancestors = _ancestors(folder);
    for (final r in names) {
      if (!r._re.hasMatch(lowerName)) continue;
      final inRe = r._inRe;
      if (inRe != null && !ancestors.any(inRe.hasMatch)) continue;
      if (kinds[r.kind] case final k?) return k;
    }
    // Deepest folder first: `…/Backups/Stickers` beats `…/Backups`.
    for (final a in ancestors) {
      for (final r in folders) {
        if (r._re.hasMatch(a)) {
          if (kinds[r.kind] case final k?) return k;
        }
      }
    }
    final dot = lowerName.lastIndexOf('.');
    if (dot > 0 && dot < lowerName.length - 1) {
      final ext = lowerName.substring(dot + 1);
      if (kinds[extensions[ext]] case final k?) return k;
    }
    return null;
  }

  static String _trimSlashes(String s) {
    var r = s;
    while (r.startsWith('/')) {
      r = r.substring(1);
    }
    while (r.endsWith('/')) {
      r = r.substring(0, r.length - 1);
    }
    return r;
  }

  /// 'a/b/c' → ['a/b/c', 'a/b', 'a'].
  static List<String> _ancestors(String folder) {
    if (folder.isEmpty) return const [];
    final parts = folder.split('/');
    return [for (var n = parts.length; n > 0; n--) parts.take(n).join('/')];
  }
}

/// Glob → anchored RegExp. `*` = any run inside one path segment, `?` =
/// one character, `**/` = zero or more whole segments, `**` = anything.
RegExp globToRegExp(String glob) {
  final b = StringBuffer('^');
  for (var i = 0; i < glob.length; i++) {
    final c = glob[i];
    if (c == '*') {
      if (i + 1 < glob.length && glob[i + 1] == '*') {
        if (i + 2 < glob.length && glob[i + 2] == '/') {
          b.write('(?:[^/]+/)*');
          i += 2;
        } else {
          b.write('.*');
          i += 1;
        }
      } else {
        b.write('[^/]*');
      }
    } else if (c == '?') {
      b.write('[^/]');
    } else {
      b.write(RegExp.escape(c));
    }
  }
  b.write(r'$');
  return RegExp(b.toString());
}
