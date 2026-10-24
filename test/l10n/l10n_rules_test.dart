import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/app_info.dart';

Map<String, Object?> _arb(File f) =>
    (jsonDecode(f.readAsStringSync()) as Map).cast<String, Object?>();

Set<String> _keys(Map<String, Object?> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

void main() {
  test('every ARB file has every key of app_en.arb', () {
    final english = _keys(_arb(File('lib/l10n/app_en.arb')));
    final others = Directory('lib/l10n').listSync().whereType<File>().where(
      (f) => f.path.endsWith('.arb') && !f.path.endsWith('app_en.arb'),
    );
    for (final file in others) {
      final missing = english.difference(_keys(_arb(file)));
      expect(missing, isEmpty, reason: '${file.path} is missing $missing');
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
  });
}
