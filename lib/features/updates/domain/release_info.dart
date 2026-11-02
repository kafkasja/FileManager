import 'dart:convert';

import 'package:kfm/features/updates/domain/app_version.dart';
import 'package:meta/meta.dart';

/// The only page KFM ever opens from a release response.
const releasePagePrefix = 'https://github.com/kafkasja/FileManager/releases/';

/// True when [url] is a release page of KFM's own repository.
bool isReleasePage(Uri url) =>
    url.toString().startsWith(releasePagePrefix) &&
    url.scheme == 'https' &&
    url.host == 'github.com' &&
    !url.hasFragment &&
    !url.path.contains('..');

/// The latest GitHub release (TASK-X7).
@immutable
class ReleaseInfo {
  const new({
    required this.version,
    required this.title,
    required this.notes,
    required this.pageUrl,
    required this.publishedAt,
  });

  final AppVersion version;
  final String title;
  final String notes;
  final Uri pageUrl;
  final DateTime publishedAt;

  String encode() => jsonEncode({
    'version': '$version',
    'title': title,
    'notes': notes,
    'pageUrl': '$pageUrl',
    'publishedAt': publishedAt.toUtc().toIso8601String(),
  });

  /// Null for '' or anything not written by [encode] (or an unsafe url).
  static ReleaseInfo? tryDecode(String s) {
    if (s.isEmpty) return null;
    try {
      final j = jsonDecode(s);
      if (j is! Map<String, Object?>) return null;
      String str(String k) => j[k] is String ? j[k]! as String : '';
      final version = AppVersion.tryParse(str('version'));
      final url = Uri.tryParse(str('pageUrl'));
      final at = DateTime.tryParse(str('publishedAt'));
      if (version == null || url == null || at == null) return null;
      if (!isReleasePage(url)) return null;
      return ReleaseInfo(
        version: version,
        title: str('title'),
        notes: str('notes'),
        pageUrl: url,
        publishedAt: at,
      );
    } on FormatException {
      return null;
    }
  }
}
