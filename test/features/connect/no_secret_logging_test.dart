import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A log call: `debugPrint(`, `print(`, `log(`, `developer.log(`.
final RegExp _logCall = RegExp(
  r'(^|[^\w.])(debugPrint|print|log)\(|developer\.log\(',
);

/// Secret-ish words; `code` only as an identifier (not "statusCode").
final RegExp _secret = RegExp(
  r'token|secret|authorization|privatekey|confirm|(^|[^\w])code\b',
  caseSensitive: false,
);

/// Lines under [root] that log something secret-looking (TASK-N3 step 7).
/// A log call may span lines up to its closing `;`.
List<String> findSecretLogging(Directory root) {
  final hits = <String>[];
  for (final f in root.listSync(recursive: true).whereType<File>()) {
    if (!f.path.endsWith('.dart') || f.path.endsWith('.g.dart')) continue;
    final lines = f.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      if (!_logCall.hasMatch(lines[i])) continue;
      final buf = StringBuffer(lines[i]);
      var j = i;
      while (!lines[j].trimRight().endsWith(';') && j < lines.length - 1) {
        buf.write(lines[++j]);
      }
      if (_secret.hasMatch(buf.toString())) hits.add('${f.path}:${i + 1}');
    }
  }
  return hits;
}

void main() {
  test('nothing under lib/features/connect logs secrets', () {
    expect(findSecretLogging(Directory('lib/features/connect')), isEmpty);
  });

  test('the check catches a token log line', () {
    final dir = Directory.systemTemp.createTempSync('kfm_log_check');
    addTearDown(() => dir.deleteSync(recursive: true));
    File('${dir.path}/a.dart').writeAsStringSync(
      "void f(String token) {\n  debugPrint('token \$token');\n}\n",
    );
    File('${dir.path}/b.dart').writeAsStringSync(
      "void g(int code) {\n  developer.log(\n    'pair \$code',\n  );\n}\n",
    );
    File('${dir.path}/c.dart').writeAsStringSync(
      "void h(int statusCode) {\n  print('status \$statusCode');\n}\n",
    );
    final hits = findSecretLogging(dir);
    expect(hits, hasLength(2));
    expect(hits.any((h) => h.endsWith('a.dart:2')), isTrue);
    expect(hits.any((h) => h.endsWith('b.dart:2')), isTrue);
  });
}
