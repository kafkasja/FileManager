import 'package:kfm/core/files/file_ref.dart';
import 'package:meta/meta.dart';

/// A copy of a file without location (TASK-X2).
@immutable
class StrippedFile {
  const new({required this.path, required this.sizeBytes, this.isTemp = true});

  /// Always a readable dart:io path (never content://).
  final String path;

  /// True: under `<cache>/privacy/<sendId>/`, deleted by
  /// [LocationStripper.release] (or at the next app start).
  final bool isTemp;
  final int sizeBytes;
}

/// Why location couldn't be removed.
enum LocationStripFailure {
  /// Location was found again after removal.
  stillHasLocation,

  /// A video container whose metadata KFM can't edit (damaged or too
  /// large `moov`).
  unsupportedFormat,

  /// The file couldn't be read.
  readFailed,
}

/// Location couldn't be removed from [fileId]: the caller must NOT send it.
@immutable
class LocationStripException implements Exception {
  const new(this.reason, this.fileId);

  final LocationStripFailure reason;
  final String fileId;

  @override
  String toString() => 'LocationStripException(${reason.name}, $fileId)';
}

/// Removes location from photos and videos before they leave the device.
abstract interface class LocationStripper {
  /// Only photos and videos carry location KFM removes; other files are
  /// sent as they are.
  static bool appliesTo(FileRef f) => f.isMedia;

  /// A copy without location in `<cache>/privacy/<sendId>/`. The output is
  /// the same bytes every time for the same file (N10 resumes uploads by
  /// offset). Throws [LocationStripException] when location can't be
  /// removed.
  Future<StrippedFile> stripToTemp(FileRef file, {required String sendId});

  /// Deletes `<cache>/privacy/<sendId>/` (send done or cancelled).
  Future<void> release(String sendId);
}
