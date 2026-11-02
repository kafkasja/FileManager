import 'package:kfm/features/external_storage/domain/storage_place.dart';

/// The places seen since the app started, by volume root (U2 follow-up):
/// folder names of a volume root (breadcrumbs, the folder picker, results
/// "in …") use the same name as Places ("SDCARD", not "SD card or USB
/// (0000-0000)"). A detached place keeps its last name. Kept current by
/// `placesWatcherProvider`; the label needs the app's strings
/// (`placeLabel`), so the place itself is stored.
abstract final class KnownPlaces {
  static final Map<String, StoragePlace> _byRoot = {};

  /// A new app (or test) starts with nothing known.
  static void reset() => _byRoot.clear();

  static void update(Iterable<StoragePlace> places) {
    for (final p in places) {
      if (p.kind == PlaceKind.internal || p.kind == PlaceKind.camera) {
        continue;
      }
      final root = p.rootPath;
      if (root != null) _byRoot[root] = p;
      // Volume ids are the uuid of `/storage/<uuid>` (also when detached).
      if (!p.id.contains('/')) _byRoot['/storage/${p.id}'] = p;
    }
  }

  /// The place whose root is exactly [root], if seen.
  static StoragePlace? atRoot(String root) => _byRoot[root];
}
