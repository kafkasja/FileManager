import 'package:kfm/core/db/settings/setting_key.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:photo_manager/photo_manager.dart';

/// How many MediaStore rows each media kind has right now, or null when the
/// platform has no MediaStore (the start reconciliation is then skipped).
typedef MediaStoreCounts = Future<Map<FileKind, int>?> Function();

/// `MediaStore.Files.FileColumns.MEDIA_TYPE_*`.
const Map<FileKind, int> _mediaTypes = {
  FileKind.image: 1,
  FileKind.audio: 2,
  FileKind.video: 3,
};

/// Android: counts the same `MediaStore.Files` rows FilesChannel.queryMedia
/// pages through (by media_type; MediaStore hides pending/trashed rows for
/// both). Only ids are read, so this is cheap even for 50k rows. Any
/// systematic difference to what the index keeps (hidden folders, rows
/// without a path) cancels out through [indexMediaCountOffsets].
Future<Map<FileKind, int>?> photoManagerMediaCounts() async => {
  for (final MapEntry(key: kind, value: type) in _mediaTypes.entries)
    kind: await PhotoManager.getAssetCount(
      type: RequestType.all,
      filterOption: CustomFilter.sql(where: 'media_type = $type'),
    ),
};

/// MediaStore count − index count per media kind, recorded right after a
/// full scan of that kind. A different difference on a later start means
/// files changed while the app wasn't running (deletes the incremental scan
/// can't see), so that kind gets a full scan. Missing kind = never recorded.
///
/// Index-internal bookkeeping, so it lives here rather than in AppSettings.
final SettingKey<Map<String, int>> indexMediaCountOffsets =
    SettingKey<Map<String, int>>(
      'index.mediaCountOffsets',
      const {},
      decode: (j) => j is Map
          ? {
              for (final MapEntry(:key, :value) in j.entries)
                if (key is String && value is int) key: value,
            }
          : const {},
      encode: (v) => v,
    );
