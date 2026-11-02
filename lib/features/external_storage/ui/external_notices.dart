import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/features/browse/ui/browse_controller.dart';
import 'package:kfm/features/external_storage/data/places_watcher.dart';
import 'package:kfm/features/external_storage/ui/place_labels.dart';
import 'package:kfm/features/external_storage/ui/places_list.dart';

/// U1: app-wide snackbars for storage plugged in ("USB drive connected ·
/// Open"), removed ("Storage removed"; Browse leaves a folder on it) and
/// the USB format help. Draws nothing.
class ExternalNotices extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<ExternalNotices> createState() => _ExternalNoticesState();
}

class _ExternalNoticesState extends ConsumerState<ExternalNotices> {
  StreamSubscription<ExternalNotice>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = ref.read(placesWatcherProvider).notices.listen(_show);
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  void _show(ExternalNotice notice) {
    if (!mounted) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    switch (notice) {
      case PlaceAttached(:final place):
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.externalAttached(placeLabel(l10n, place))),
            persist: false,
            action: SnackBarAction(
              label: l10n.externalOpen,
              onPressed: () => unawaited(openPlace(context, ref, place)),
            ),
          ),
        );
      case PlaceRemoved(:final place):
        final root = place.rootPath;
        if (root != null && ref.exists(browseViewControllerProvider)) {
          final browse = ref.read(browseViewControllerProvider.notifier);
          final folder = ref.read(browseViewControllerProvider).folder;
          if (folder != null &&
              (folder == root || folder.startsWith('$root/'))) {
            browse.openFolder(null);
          }
        }
        messenger.showSnackBar(SnackBar(content: Text(l10n.externalRemoved)));
      case UsbFormatHelp():
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.externalFormatHelp),
            duration: const Duration(seconds: 10),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
