import 'dart:convert';

import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/source_rule.dart';
import 'package:meta/meta.dart';

/// The app a file's folder points at (TASK-B10): `Android/media/<pkg>/…`
/// and friends name the package; otherwise B1's [SourceBucket].
@immutable
class PathApp {
  const new({this.packageName, this.bucket = SourceBucket.none});

  /// From `Android/{media,data,obb}/<pkg>`, or the bucket's usual app.
  final String? packageName;

  /// [SourceBucket.none] when the folder named a package directly.
  final SourceBucket bucket;

  @override
  bool operator ==(Object other) =>
      other is PathApp &&
      other.packageName == packageName &&
      other.bucket == bucket;

  @override
  int get hashCode => Object.hash(packageName, bucket);

  @override
  String toString() => 'PathApp($packageName, $bucket)';
}

final _appFolder = RegExp(r'^android/(?:media|data|obb)/([^/]+)(?:/|$)');
final _package = RegExp(r'^[a-z][a-z0-9_]*(?:\.[a-z0-9_]+)+$');

/// 'android/media/com.whatsapp/whatsapp/…' → 'com.whatsapp'. [relFolder]
/// is volume-relative (`volumeRelative`); null when it isn't an app folder
/// or the segment doesn't look like a package name.
String? packageFromFolder(String relFolder) {
  final m = _appFolder.firstMatch(relFolder.toLowerCase());
  final pkg = m?.group(1);
  return pkg != null && _package.hasMatch(pkg) ? pkg : null;
}

/// Pure guess for [file]; null when the folder says nothing.
PathApp? pathAppFor(FileRef file, KnownApps apps) {
  final rel = volumeRelative(file.folderPath);
  if (packageFromFolder(rel) case final pkg?) return PathApp(packageName: pkg);
  final bucket = sourceFor(file.kind, file.folderPath, file.name);
  if (bucket == SourceBucket.none) return null;
  return PathApp(packageName: apps.bucketPackages[bucket], bucket: bucket);
}

/// `assets/details/known_apps.json`: display names for packages that may
/// not be visible (uninstalled, or hidden on API 30+), and each source
/// bucket's usual app.
@immutable
class KnownApps {
  const new({this.names = const {}, this.bucketPackages = const {}});

  /// Throws [FormatException] on a malformed file.
  factory parse(String text) {
    final root = jsonDecode(text);
    if (root case {
      'packages': final Map<String, Object?> packages,
      'buckets': final Map<String, Object?> buckets,
    }) {
      final byName = SourceBucket.values.asNameMap();
      return KnownApps(
        names: {
          for (final MapEntry(:key, :value) in packages.entries)
            key: value is String
                ? value
                : throw FormatException('known apps: $key'),
        },
        bucketPackages: {
          for (final MapEntry(:key, :value) in buckets.entries)
            byName[key] ?? (throw FormatException('known apps: bucket $key')):
                value is String
                ? value
                : throw FormatException('known apps: bucket $key'),
        },
      );
    }
    throw const FormatException('known apps: needs packages and buckets');
  }

  /// Package → display name ('com.whatsapp' → 'WhatsApp').
  final Map<String, String> names;
  final Map<SourceBucket, String> bucketPackages;
}
