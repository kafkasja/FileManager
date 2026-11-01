import 'dart:io';

import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/services.dart';

/// An [AssetBundle] with only the given term files (asset key → file on
/// disk) and a matching asset manifest, for the language mechanism tests.
class FixtureTermsBundle extends CachingAssetBundle {
  new(this.files);

  /// Fixture term files as `assets/search/terms_<lang>.json` → path.
  factory langs(Map<String, String> langToFile) => FixtureTermsBundle({
    for (final MapEntry(:key, :value) in langToFile.entries)
      'assets/search/terms_$key.json': value,
  });

  final Map<String, String> files;

  /// Asset keys whose file was loaded (to prove what was read).
  final List<String> loaded = [];

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') {
      return const StandardMessageCodec().encodeMessage({
        for (final k in files.keys)
          k: [
            {'asset': k},
          ],
      })!;
    }
    final path = files[key];
    if (path == null) throw FlutterError('Unable to load asset: "$key".');
    loaded.add(key);
    final bytes = File(path).readAsBytesSync();
    return ByteData.sublistView(bytes);
  }
}

const fixtureDir = 'test/fixtures/search';

String fixture(String lang) => '$fixtureDir/terms_$lang.json';
