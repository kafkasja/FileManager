// Downloads the pinned AI models into build/ai_models/ and verifies their
// SHA-256 against assets/ai/models_manifest.json (dev only, for
// test/features/ai_labels/label_worker_test.dart). The app itself never
// uses this: it downloads through AiModelStore after the user's consent.
//
//   dart run tool/fetch_ai_models.dart
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

Future<void> main() async {
  final manifest = jsonDecode(
    File('assets/ai/models_manifest.json').readAsStringSync(),
  ) as Map<String, Object?>;
  final out = Directory('build/ai_models')..createSync(recursive: true);
  final client = HttpClient();
  try {
    for (final m in manifest['models']! as List<Object?>) {
      final model = m! as Map<String, Object?>;
      final file = File('${out.path}/${model['file']}');
      final want = model['sha256']! as String;
      if (file.existsSync() &&
          sha256.convert(file.readAsBytesSync()).toString() == want) {
        stdout.writeln('${model['file']}: already there');
        continue;
      }
      final req = await client.getUrl(Uri.parse(model['url']! as String));
      final res = await req.close();
      if (res.statusCode != HttpStatus.ok) {
        throw HttpException('${model['file']}: HTTP ${res.statusCode}');
      }
      final bytes = <int>[];
      await res.forEach(bytes.addAll);
      final got = sha256.convert(bytes).toString();
      if (got != want) {
        throw StateError('${model['file']}: SHA-256 $got, expected $want');
      }
      file.writeAsBytesSync(bytes);
      stdout.writeln('${model['file']}: ${bytes.length} bytes, verified');
    }
  } finally {
    client.close();
  }
}
