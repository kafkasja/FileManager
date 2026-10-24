import 'package:meta/meta.dart';

enum MediaAccess {
  /// Not asked yet.
  unknown,
  granted,

  /// API 34+ "Select photos" / iOS limited: the app sees only the selection.
  limited,
  denied,

  /// "Don't ask again": only the system settings page can change it.
  permanentlyDenied,
}

enum AllFilesAccess {
  /// API ≤29: covered by READ/WRITE_EXTERNAL_STORAGE (+ legacy flag).
  notRequired,
  granted,
  notGranted,
}

/// What KFM may currently see and change. Owned by TASK-F4.
@immutable
class StorageAccess {
  const new({
    required this.media,
    required this.allFiles,
    required this.mediaManagement,
    this.mediaManagementSupported = false,
  });

  final MediaAccess media;
  final AllFilesAccess allFiles;

  /// API 31+ MANAGE_MEDIA special access: skips trash/delete/write
  /// confirmation dialogs.
  final bool mediaManagement;

  /// False below API 31, where Media management doesn't exist.
  final bool mediaManagementSupported;

  bool get canUseSwipe =>
      media == MediaAccess.granted || media == MediaAccess.limited;

  bool get canSeeAllFiles =>
      allFiles != AllFilesAccess.notGranted && canUseSwipe;

  StorageAccess copyWith({
    MediaAccess? media,
    AllFilesAccess? allFiles,
    bool? mediaManagement,
    bool? mediaManagementSupported,
  }) => StorageAccess(
    media: media ?? this.media,
    allFiles: allFiles ?? this.allFiles,
    mediaManagement: mediaManagement ?? this.mediaManagement,
    mediaManagementSupported:
        mediaManagementSupported ?? this.mediaManagementSupported,
  );

  @override
  bool operator ==(Object other) =>
      other is StorageAccess &&
      other.media == media &&
      other.allFiles == allFiles &&
      other.mediaManagement == mediaManagement &&
      other.mediaManagementSupported == mediaManagementSupported;

  @override
  int get hashCode =>
      Object.hash(media, allFiles, mediaManagement, mediaManagementSupported);

  @override
  String toString() => 'StorageAccess($media, $allFiles, mm=$mediaManagement)';
}
