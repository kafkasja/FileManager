import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Since Flutter 3.29 a SnackBar with an `action` stays until dismissed
/// unless `persist: false` is set. KFM's action snackbars ("Show",
/// "Change", "Undo") must time out like the others: on the S22 a "connected ·
/// Change" snackbar stayed for hours and blocked scrolling (2026-11-02).
void main() {
  test('every SnackBar with an action sets persist', () {
    final offenders = <String>[];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'));
    for (final file in files) {
      final text = file.readAsStringSync();
      for (final m in RegExp(r'\bSnackBar\(').allMatches(text)) {
        // This SnackBar's own top-level arguments only.
        var depth = 1;
        var i = m.end;
        final top = StringBuffer();
        while (i < text.length && depth > 0) {
          final c = text[i];
          if ('([{'.contains(c)) depth++;
          if (')]}'.contains(c)) depth--;
          if (depth == 1 && !'([{'.contains(c)) top.write(c);
          i++;
        }
        final args = top.toString();
        if (RegExp(r'\baction\s*:').hasMatch(args) &&
            !RegExp(r'\bpersist\s*:').hasMatch(args)) {
          final line = '\n'.allMatches(text.substring(0, m.start)).length + 1;
          offenders.add('${file.path}:$line');
        }
      }
    }
    expect(offenders, isEmpty, reason: 'add `persist: false`');
  });
}
