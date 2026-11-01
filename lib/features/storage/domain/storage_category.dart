import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/source_rule.dart';
import 'package:kfm/core/platform/device_space.dart';
import 'package:kfm/features/filters/domain/file_filter.dart';
import 'package:meta/meta.dart';

/// The Storage overview's rows (TASK-C1).
enum StorageCategoryId { videos, screenshots, bigFiles, whatsapp, downloads }

/// A row: a P5 filter (handed unchanged to SS1's FilterSourceRequest) and
/// whether hidden rows count in its totals.
@immutable
class StorageCategory {
  const new({required this.id, required this.filter, this.countHidden = false});

  final StorageCategoryId id;
  final FileFilter filter;

  /// Totals include hidden rows; "Clean up" swipes only visible ones.
  final bool countHidden;
}

/// [bigFileBytes] from `AppSettings.storageBigFileThresholdBytes`.
List<StorageCategory> storageCategories({required int bigFileBytes}) => [
  const StorageCategory(
    id: StorageCategoryId.videos,
    filter: FileFilter(kinds: {FileKind.video}),
  ),
  const StorageCategory(
    id: StorageCategoryId.screenshots,
    filter: FileFilter(screenshotsOnly: true),
  ),
  StorageCategory(
    id: StorageCategoryId.bigFiles,
    filter: FileFilter(minSizeBytes: bigFileBytes),
  ),
  const StorageCategory(
    id: StorageCategoryId.whatsapp,
    filter: FileFilter(sources: {SourceBucket.whatsapp}),
    // Sent and .Statuses are .nomedia / dot folders.
    countHidden: true,
  ),
  const StorageCategory(
    id: StorageCategoryId.downloads,
    filter: FileFilter(sources: {SourceBucket.downloads}),
  ),
];

@immutable
class StorageCategoryTotal {
  const new({
    required this.category,
    required this.fileCount,
    required this.totalBytes,
    required this.swipeableCount,
    this.needsAccess = false,
  });

  final StorageCategory category;
  final int fileCount;
  final int totalBytes;

  /// Visible photos/videos ("Clean up" shows these). 0 → no button.
  final int swipeableCount;

  /// Some of its files can't be seen without All files access.
  final bool needsAccess;
}

@immutable
class StorageOverview {
  const new({
    required this.space,
    required this.categories,
    required this.biggestFiles,
    required this.scanning,
    required this.allFilesAccess,
  });

  /// Null when the platform call failed ("Unknown").
  final DeviceSpace? space;

  /// Sorted by totalBytes, largest first. Categories overlap: never summed.
  final List<StorageCategoryTotal> categories;

  /// Top 20 by size, all visible kinds.
  final List<FileRef> biggestFiles;
  final bool scanning;
  final bool allFilesAccess;
}
