import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// TASK-E1: a dialog closed "from outside" with
/// `Navigator.of(context, rootNavigator: true).pop()` pops whatever is on
/// top: a sheet or dialog above it, or, with no dialog open (it was not
/// shown yet, or already answered), the app's last page. That left a black
/// screen on the PC and the phone after Stop sharing. Close such dialogs
/// with `DialogHandle` (lib/app/safe_nav.dart) instead.
void main() {
  test('no blind pops of the root navigator', () {
    final offenders = <String>[];
    final direct = RegExp(
      r'Navigator\.of\(\s*\w+\s*,\s*rootNavigator:\s*true\s*,?\s*\)\s*\.pop\(',
    );
    final captured = RegExp(
      r'(\w+)\s*=\s*Navigator\.of\(\s*\w+\s*,\s*rootNavigator:\s*true\s*,?\s*\)',
    );
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (f) =>
              f.path.endsWith('.dart') &&
              !f.path.endsWith('.g.dart') &&
              !f.path.replaceAll(r'\', '/').endsWith('lib/app/safe_nav.dart'),
        );
    String at(File file, String text, int offset) =>
        '${file.path}:${'\n'.allMatches(text.substring(0, offset)).length + 1}';
    for (final file in files) {
      final text = file.readAsStringSync();
      for (final m in direct.allMatches(text)) {
        offenders.add(at(file, text, m.start));
      }
      for (final m in captured.allMatches(text)) {
        final name = RegExp.escape(m.group(1)!);
        final pop = RegExp('\\b$name\\s*\\.pop\\(');
        for (final p in pop.allMatches(text, m.end)) {
          offenders.add(at(file, text, p.start));
        }
      }
    }
    expect(offenders, isEmpty, reason: 'close dialogs with DialogHandle');
  });
}
