import 'package:flutter/material.dart';
import 'package:kfm/app/l10n_ext.dart';

/// What the user chose in [showLocationMoveWarning].
enum LocationMoveChoice { moveAnyway, copyInstead }

/// X2: "Remove location" is on and the user moves photos or videos to
/// another device: the copies lose their location and the originals (the
/// only files with it) would be deleted. Copy instead is the default
/// button; null = Cancel.
Future<LocationMoveChoice?> showLocationMoveWarning(BuildContext context) =>
    showDialog<LocationMoveChoice>(
      context: context,
      builder: (context) {
        final l10n = context.l10n;
        return AlertDialog(
          icon: const Icon(Icons.location_off_outlined),
          title: Text(l10n.privacyMoveWarningTitle),
          content: Text(l10n.privacyMoveWarningBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              key: const ValueKey('privacy-move-anyway'),
              onPressed: () =>
                  Navigator.pop(context, LocationMoveChoice.moveAnyway),
              child: Text(l10n.privacyMoveAnyway),
            ),
            FilledButton(
              key: const ValueKey('privacy-copy-instead'),
              autofocus: true,
              onPressed: () =>
                  Navigator.pop(context, LocationMoveChoice.copyInstead),
              child: Text(l10n.privacyCopyInstead),
            ),
          ],
        );
      },
    );
