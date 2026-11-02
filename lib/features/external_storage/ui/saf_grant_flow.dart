import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/features/external_storage/data/saf_grants.dart';
import 'package:kfm/features/external_storage/domain/storage_place.dart';
import 'package:kfm/features/external_storage/ui/place_labels.dart';

/// U1: makes sure a SAF place has a working grant. A stored grant is
/// re-validated (a reformatted stick fails → asked again). Otherwise:
/// explanation → system picker at the volume → only the volume's root is
/// accepted (a subfolder → explained, Pick again). True when usable.
Future<bool> ensureSafGrant(
  BuildContext context,
  WidgetRef ref,
  StoragePlace place,
) async {
  final uuid = place.volumeUuid;
  final grants = ref.read(safGrantsProvider);
  if (place.access != AccessMethod.saf) return true;
  if (uuid == null || grants == null) return false;
  final stored = place.treeUri;
  if (stored != null) {
    if (await grants.isValid(stored)) return true;
    await grants.drop(uuid);
  }
  if (!context.mounted) return false;
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
