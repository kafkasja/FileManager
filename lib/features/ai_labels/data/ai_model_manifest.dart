import 'dart:convert';

import 'package:meta/meta.dart';

/// One downloadable model (`assets/ai/models_manifest.json`).
@immutable
class AiModelEntry {
  const new({
    required this.id,
    required this.file,
    required this.sizeBytes,
    required this.sha256,
    required this.url,
    required this.name,
    required this.licence,
    required this.publisher,
    required this.sourceUrl,
    this.fallbackUrl,
  });

  factory fromJson(Map<String, Object?> j) => AiModelEntry(
    id: j['id']! as String,
    file: j['file']! as String,
    sizeBytes: j['sizeBytes']! as int,
    sha256: (j['sha256']! as String).toLowerCase(),
    url: j['url']! as String,
    fallbackUrl: j['fallbackUrl'] as String?,
    name: j['name']! as String,
    licence: j['licence']! as String,
    publisher: j['publisher']! as String,
    sourceUrl: j['sourceUrl']! as String,
  );

  /// `classifier` | `detector` (ARB descriptions are keyed by it).
  final String id;

  /// File name inside `ai_models/`.
  final String file;
  final int sizeBytes;

  /// Lowercase hex.
  final String sha256;

  /// HTTPS download URL (today: the publisher's fixed GCS object).
  final String url;

  /// Optional second source; accepted only with the same SHA-256.
  final String? fallbackUrl;
  final String name;
  final String licence;
  final String publisher;

  /// The original release page.
  final String sourceUrl;
}

/// The pinned model set, bundled with the app (TASK-C3 §8).
@immutable
class AiModelManifest {
  const new({required this.modelSetVersion, required this.models});

  factory parse(String json) {
    final root = jsonDecode(json) as Map<String, Object?>;
    return AiModelManifest(
      modelSetVersion: root['modelSetVersion']! as int,
      models: [
        for (final m in root['models']! as List<Object?>)
          AiModelEntry.fromJson(m! as Map<String, Object?>),
      ],
    );
  }

  static const String assetPath = 'assets/ai/models_manifest.json';

  final int modelSetVersion;
  final List<AiModelEntry> models;

  int get totalBytes => models.fold(0, (s, m) => s + m.sizeBytes);

  AiModelEntry byId(String id) => models.firstWhere((m) => m.id == id);
}
