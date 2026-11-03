import 'package:kfm/core/db/tables/cloud_destinations_table.dart';
import 'package:meta/meta.dart';

export 'package:kfm/core/db/tables/cloud_destinations_table.dart'
    show CloudProviderGuess;

/// A folder in one of the user's own cloud apps (TASK-X3). KFM writes into
/// it; the cloud app uploads.
@immutable
class CloudDestination {
  const new({
    required this.id,
    required this.label,
    required this.provider,
    required this.location,
    required this.addedAt,
    this.removedAt,
  });

  final int id;
  final String label;
  final CloudProviderGuess provider;

  /// Android: the persisted tree URI.
  final String location;
  final DateTime addedAt;
  final DateTime? removedAt;

  bool get isActive => removedAt == null;

  @override
  bool operator ==(Object other) =>
      other is CloudDestination &&
      other.id == id &&
      other.label == label &&
      other.provider == provider &&
      other.location == location &&
      other.addedAt == addedAt &&
      other.removedAt == removedAt;

  @override
  int get hashCode =>
      Object.hash(id, label, provider, location, addedAt, removedAt);
}

/// In-memory, from the persisted-permission check.
enum CloudDestinationHealth { ok, needsReconnecting }

/// The provider from a tree URI's authority (label and icon only).
CloudProviderGuess guessProvider(String? authority) => switch (authority) {
  'com.google.android.apps.docs.storage' ||
  'com.google.android.apps.docs.storage.legacy' =>
    CloudProviderGuess.googleDrive,
  'com.microsoft.skydrive.content.StorageAccessProvider' =>
    CloudProviderGuess.oneDrive,
  'com.dropbox.android.FileCache' ||
  'com.dropbox.product.android.dbapp.document_provider.documents' =>
    CloudProviderGuess.dropbox,
  _ => CloudProviderGuess.other,
};

/// Brand names stay untranslated.
String? providerName(CloudProviderGuess p) => switch (p) {
  CloudProviderGuess.googleDrive => 'Google Drive',
  CloudProviderGuess.oneDrive => 'OneDrive',
  CloudProviderGuess.dropbox => 'Dropbox',
  CloudProviderGuess.iCloud => 'iCloud Drive',
  CloudProviderGuess.other => null,
};

/// Longest label (`cloud_destinations.label`).
const int kCloudLabelMax = 60;

/// "Google Drive › Photos" (or just the folder name for other providers),
/// at most [kCloudLabelMax] characters, never empty.
String defaultCloudLabel(CloudProviderGuess p, String? folderName) {
  final folder = (folderName ?? '').trim();
  final brand = providerName(p);
  final raw = brand == null
      ? (folder.isEmpty ? 'Cloud' : folder)
      : (folder.isEmpty ? brand : '$brand › $folder');
  return clampCloudLabel(raw);
}

/// Trims and shortens [label] to [kCloudLabelMax] characters.
String clampCloudLabel(String label) {
  final t = label.trim();
  final runes = t.runes.toList();
  return runes.length <= kCloudLabelMax
      ? t
      : String.fromCharCodes(runes.take(kCloudLabelMax)).trim();
}
