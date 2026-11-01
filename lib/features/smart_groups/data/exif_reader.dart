import 'package:kfm/core/files/android/files_channel.dart';
import 'package:meta/meta.dart';

/// EXIF facts of one image (TASK-C5), or the error reading it.
@immutable
class ExifFacts {
  const new({
    required this.fileId,
    this.lat,
    this.lng,
    this.frontCamera = false,
    this.locationReadable = true,
    this.error,
  });

  final String fileId;
  final double? lat;
  final double? lng;
  final bool frontCamera;

  /// GPS could be read (not stripped for lack of ACCESS_MEDIA_LOCATION).
  final bool locationReadable;

  /// Set when this file couldn't be read (counted, never written).
  final String? error;
}

/// Reads EXIF for a batch of file ids (`ms:<id>` or `path:<path>`).
abstract interface class ExifReader {
  Future<List<ExifFacts>> read(List<String> fileIds);
}

/// Android: one batched call per id kind on `com.kaf.kfm/files`.
class ChannelExifReader implements ExifReader {
  const new(this._channel);

  final FilesChannel _channel;

  @override
  Future<List<ExifFacts>> read(List<String> fileIds) async {
    final ms = <int>[];
    final paths = <String>[];
    for (final id in fileIds) {
      if (id.startsWith('ms:')) {
        final n = int.tryParse(id.substring(3));
        if (n != null) ms.add(n);
      } else if (id.startsWith('path:')) {
        paths.add(id.substring(5));
      }
    }
    return [
      if (ms.isNotEmpty)
        for (final r in await _channel.readExif(ms)) _facts('ms:${r['id']}', r),
      if (paths.isNotEmpty)
        for (final r in await _channel.readExifPaths(paths))
          _facts('path:${r['id']}', r),
    ];
  }

  static ExifFacts _facts(String fileId, MediaRow r) {
    if (r['error'] case final String error) {
      return ExifFacts(fileId: fileId, error: error);
    }
    final lat = r['lat'];
    final lng = r['lng'];
    final hasGps = lat is num && lng is num;
    return ExifFacts(
      fileId: fileId,
      lat: hasGps ? lat.toDouble() : null,
      lng: hasGps ? lng.toDouble() : null,
      frontCamera: r['frontCamera'] == true,
      locationReadable: r['locationReadable'] != false,
    );
  }
}
