import 'package:kfm/features/connect/data/path_guard.dart';
import 'package:kfm/features/connect/domain/share_scope.dart';
import 'package:kfm/features/external_storage/domain/storage_place.dart';
import 'package:kfm/features/external_storage/ui/place_labels.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';
import 'package:path/path.dart' as p;

/// TASK-E1 "Let `peer` see my files": every storage root of this device,
/// writable (uploads never overwrite; collisions get a new name).
/// Android: the primary volume + mounted direct-path places (SD card, USB;
/// without All files access the server lists media only anyway).
/// Windows: the user's folder (`%USERPROFILE%`) + every mounted drive but
/// the system one. `PathGuard` still excludes app data, `Android/data`,
/// `AppData`, `$Recycle.Bin` and dot folders inside them. Roots that fail
/// to canonicalise are skipped.
Future<List<SharedRoot>> allStorageRoots({
  required String primaryRoot,
  required String primaryLabel,
  required List<StoragePlace> places,
  required List<int> salt,
  required PathGuard guard,
  required AppLocalizations l10n,
}) async {
  final out = <SharedRoot>[];
  Future<void> add(String path, String label) async {
    final String canonical;
    try {
      canonical = await guard.canonicalise(path);
    } on Object {
      return;
    }
    if (PathGuard.isExcluded(canonical)) return;
    if (out.any((r) => r.path.toLowerCase() == canonical.toLowerCase())) {
      return;
    }
    out.add(
      SharedRoot(
        id: PathGuard.rootId(salt, canonical),
        path: canonical,
        label: label,
        readOnly: false,
      ),
    );
  }

  await add(primaryRoot, primaryLabel);
  for (final place in places) {
    final root = place.rootPath;
    if (root == null ||
        !place.isMounted ||
        place.id == kInternalPlaceId ||
        place.kind == PlaceKind.camera ||
        place.access != AccessMethod.directPath) {
      continue;
    }
    await add(root, placeLabel(l10n, place));
  }
  return List.unmodifiable(out);
}

/// The label of the primary root: "Internal storage" on a phone, the
/// user folder's name on Windows.
String primaryRootLabel(
  AppLocalizations l10n,
  String primaryRoot, {
  required bool windows,
}) => windows ? p.posix.basename(primaryRoot) : l10n.externalInternal;
