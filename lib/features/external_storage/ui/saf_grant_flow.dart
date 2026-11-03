import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/features/external_storage/data/places_repository.dart';
import 'package:kfm/features/external_storage/data/saf_grants.dart';
import 'package:kfm/features/external_storage/domain/storage_place.dart';
import 'package:kfm/features/external_storage/ui/place_labels.dart';

/// U1 follow-up (f): from API 30 Android's folder picker refuses the root
/// of an SD card or USB drive ("Can't use this folder"), so a volume root
/// without a stored grant can only be opened with All files access there.
bool needsAllFilesForPlace(StoragePlace place, int sdkInt) =>
    place.access == AccessMethod.saf && place.treeUri == null && sdkInt >= 30;

/// U1: makes [place] usable and returns it with the access it now has (a
/// SAF place that just got All files access comes back as direct path), or
/// null when it can't be opened. A stored SAF grant is re-validated (a
/// reformatted stick fails → asked again; a grant kept from API ≤29 still
/// works on 30+). Without one, API ≤29: explanation → system picker at the
/// volume → only the volume's root is accepted (a subfolder → explained,
/// Pick again). API 30+: explains that All files access is needed and
/// opens its system page (the picker can't grant a drive's root there).
Future<StoragePlace?> ensurePlaceAccess(
  BuildContext context,
  WidgetRef ref,
  StoragePlace place,
) async {
  if (place.access != AccessMethod.saf) return place;
  final uuid = place.volumeUuid;
  if (uuid == null) return null;
  final grants = ref.read(safGrantsProvider);
  final stored = place.treeUri;
  var current = place;
  if (stored != null && grants != null) {
    if (await grants.isValid(stored)) return place;
    await grants.drop(uuid);
    current = place.copyWith(treeUri: () => null);
  }
  final sdkInt = ref.read(deviceStorageProvider).value?.sdkInt ?? 0;
  if (!context.mounted) return null;
  if (needsAllFilesForPlace(current, sdkInt)) {
    return await _viaAllFilesAccess(context, ref, current);
  }
  if (grants == null) return null;
  return await _safGrant(context, grants, place, uuid) ? current : null;
}

Future<StoragePlace?> _viaAllFilesAccess(
  BuildContext context,
  WidgetRef ref,
  StoragePlace place,
) async {
  final l10n = context.l10n;
  final label = placeLabel(l10n, place);
  final messenger = ScaffoldMessenger.of(context);
  final go = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.externalAllFilesTitle(label)),
      content: Text(l10n.externalAllFilesExplain(label)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.allFilesTurnOn),
        ),
      ],
    ),
  );
  if (go != true) return null;
  final controller = ref.read(storageAccessControllerProvider.notifier);
  // permission_handler returns once the user leaves the system page.
  await controller.openAllFilesSettings();
  final access = await controller.recheck();
  if (!access.canSeeAllFiles) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.externalAllFilesStillOff(label))),
    );
    return null;
  }
  return place.copyWith(access: AccessMethod.directPath, treeUri: () => null);
}

Future<bool> _safGrant(
  BuildContext context,
  SafGrants grants,
  StoragePlace place,
  String uuid,
) async {
  final l10n = context.l10n;
  final go = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.externalGrantTitle(placeLabel(l10n, place))),
      content: Text(l10n.externalGrantExplain),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.externalGrantContinue),
        ),
      ],
    ),
  );
  if (go != true) return false;
  while (true) {
    final outcome = await grants.grant(uuid);
    if (!context.mounted) return outcome == GrantOutcome.granted;
    switch (outcome) {
      case GrantOutcome.granted:
        return true;
      case GrantOutcome.cancelled:
        return false;
      case GrantOutcome.failed:
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.externalGrantFailed)));
        return false;
      case GrantOutcome.wrongFolder:
        final retry = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.externalPickRootTitle),
            content: Text(l10n.externalPickRootHint),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.externalRetry),
              ),
            ],
          ),
        );
        if (retry != true || !context.mounted) return false;
    }
  }
}
