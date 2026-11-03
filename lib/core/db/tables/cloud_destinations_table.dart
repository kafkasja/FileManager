import 'package:drift/drift.dart';

enum CloudProviderGuess { googleDrive, oneDrive, dropbox, iCloud, other }

/// Folders in the user's own cloud apps (TASK-X3). Soft-deleted: a removed
/// destination keeps its row so cloud_items history (X4 badge) stays valid.
@DataClassName('CloudDestinationRow')
class CloudDestinations extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// "Drive › Photos"; the user can rename it. 1–60 chars.
  TextColumn get label => text().withLength(min: 1, max: 60)();
  TextColumn get providerGuess => textEnum<CloudProviderGuess>()();

  /// Android tree URI | Windows path | iOS bookmark (base64). Unique: adding
  /// the same folder again re-activates the removed row instead.
  TextColumn get location => text().unique()();
  DateTimeColumn get addedAt => dateTime()();

  /// Set when removed; null = active.
  DateTimeColumn get removedAt => dateTime().nullable()();
}
