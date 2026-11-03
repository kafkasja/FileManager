import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/app_info.dart';

Map<String, Object?> _arb(File f) =>
    (jsonDecode(f.readAsStringSync()) as Map).cast<String, Object?>();

Set<String> _keys(Map<String, Object?> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

/// Names under `@key.placeholders` in [arb].
Set<String> _declaredPlaceholders(Map<String, Object?> arb, String key) {
  final meta = arb['@$key'];
  if (meta is! Map) return const {};
  final placeholders = meta['placeholders'];
  if (placeholders is! Map) return const {};
  return placeholders.keys.cast<String>().toSet();
}

/// The declared placeholder names [message] uses: `{name}` and the
/// `{name, plural|select, …}` selectors. Case keywords and the text inside
/// ICU cases are not names, so only [declared] names count.
Set<String> _usedPlaceholders(String message, Set<String> declared) => {
  for (final m in RegExp(r'\{\s*([A-Za-z_]\w*)\s*[,}]').allMatches(message))
    if (declared.contains(m.group(1))) m.group(1)!,
};

void main() {
  group('translations (TASK-L2)', () {
    final english = _arb(File('lib/l10n/app_en.arb'));
    final englishKeys = _keys(english);
    final others = Directory('lib/l10n')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.arb') && !f.path.endsWith('app_en.arb'))
        .toList();

    test('nl and tr are bundled', () {
      final names = others.map((f) => f.uri.pathSegments.last).toSet();
      expect(names, containsAll(['app_nl.arb', 'app_tr.arb']));
    });

    for (final file in others) {
      final name = file.uri.pathSegments.last;
      final arb = _arb(file);

      test('$name has exactly the keys of app_en.arb', () {
        final keys = _keys(arb);
        final missing = englishKeys.difference(keys);
        final extra = keys.difference(englishKeys);
        expect(missing, isEmpty, reason: '$name is missing $missing');
        expect(extra, isEmpty, reason: '$name has keys en lacks: $extra');
        expect(arb['@@locale'], name.substring(4, name.length - 4));
      });

      test('$name: every message is non-empty', () {
        final empty = [
          for (final k in _keys(arb))
            if (arb[k] is! String || (arb[k]! as String).trim().isEmpty) k,
        ];
        expect(empty, isEmpty, reason: '$name has empty messages: $empty');
      });

      test('$name uses the same placeholders as app_en.arb', () {
        final wrong = <String>[];
        for (final key in englishKeys) {
          final declared = _declaredPlaceholders(english, key);
          if (declared.isEmpty) continue;
          final message = arb[key];
          if (message is! String) continue;
          final want = _usedPlaceholders(english[key]! as String, declared);
          final got = _usedPlaceholders(message, declared);
          if (want.length != got.length || !want.containsAll(got)) {
            wrong.add('$key: en $want, $name $got');
          }
        }
        expect(wrong, isEmpty, reason: wrong.join('\n'));
      });
    }
  });

  test('no hard-coded Text literals in UI code', () {
    final literal = RegExp(r'''Text\(\s*['"]''');
    final offenders = <String>[];
    final roots = [Directory('lib/app'), Directory('lib/features')];
    for (final root in roots) {
      for (final f in root.listSync(recursive: true).whereType<File>()) {
        final path = f.path.replaceAll(r'\', '/');
        if (!path.endsWith('.dart') || path.endsWith('.g.dart')) continue;
        final isUi = path.contains('/ui/') || path.startsWith('lib/app');
        if (isUi && literal.hasMatch(f.readAsStringSync())) {
          offenders.add(path);
        }
      }
    }
    expect(offenders, isEmpty, reason: 'use AppLocalizations instead');
  });

  test('appVersion matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final version = RegExp(
      r'^version:\s*([^+\s]+)',
      multiLine: true,
    ).firstMatch(pubspec)!.group(1);
    expect(appVersion, version);
    final build = RegExp(
      r'^version:\s*[^+\s]+\+(\d+)',
      multiLine: true,
    ).firstMatch(pubspec)!.group(1);
    expect(appBuildNumber, build);
  });
}
