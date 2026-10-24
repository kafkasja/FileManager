import 'package:kfm/core/files/android/files_channel.dart';
import 'package:kfm/core/files/file_kind_resolver.dart';
import 'package:kfm/core/files/file_names.dart';
import 'package:kfm/core/files/file_ref.dart';

/// Maps a FilesChannel.kt MediaStore row to a [FileRef] with id `ms:<id>`.
/// Files outside [primaryRoot] (SD card, USB) get [FileOrigin.external].
FileRef mediaRefFromRow(MediaRow row, {required String primaryRoot}) {
  final path = row['path']! as String;
  final name = row['name']! as String;
  final mime = row['mime'] as String?;
  final taken = row['taken'] as int?;
  return FileRef(
    id: 'ms:${row['id']! as int}',
    uri: row['uri']! as String,
    name: name,
    mimeType: mime,
    kind: switch (row['mediaType']) {
      'image' => FileKind.image,
      'video' => FileKind.video,
      'audio' => FileKind.audio,
      _ => kindFor(mime, name),
    },
    sizeBytes: row['size'] as int? ?? 0,
    modifiedAt: DateTime.fromMillisecondsSinceEpoch(
      (row['modified'] as int? ?? 0) * 1000,
      isUtc: true,
    ),
    takenAt: taken == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(taken, isUtc: true),
    width: row['width'] as int?,
    height: row['height'] as int?,
    durationMs: row['duration'] as int?,
    folderPath: parentOf(path),
    origin: path.startsWith('$primaryRoot/')
        ? FileOrigin.local
        : FileOrigin.external,
  );
}
