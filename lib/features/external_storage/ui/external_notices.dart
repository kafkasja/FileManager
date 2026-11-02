import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/features/browse/ui/browse_controller.dart';
import 'package:kfm/features/external_storage/data/eject_watch.dart';
import 'package:kfm/features/external_storage/data/places_watcher.dart';
import 'package:kfm/features/external_storage/ui/eject_flow.dart';
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
  StreamSubscription<EjectNotYet>? _ejectSub;

  @override
  void initState() {
    super.initState();
    _sub = ref.read(placesWatcherProvider).notices.listen(_show);
    _ejectSub = ref.read(ejectWatchProvider).notices.listen(_notYet);
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    unawaited(_ejectSub?.cancel());
    super.dispose();
  }

  /// U3: back from settings, the place is still mounted.
  void _notYet(EjectNotYet notice) {
    if (!mounted) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.ejectNotYet),
        persist: false,
        action: SnackBarAction(
          label: l10n.ejectOpenAgain,
          onPressed: () => unawaited(
            openEjectSettings(ref, notice.place, messenger, l10n.ejectFailed),
          ),
        ),
      ),
    );
  }

  void _leaveFolderOn(String? root) {
    if (root == null || !ref.exists(browseViewControllerProvider)) return;
    final browse = ref.read(browseViewControllerProvider.notifier);
    final folder = ref.read(browseViewControllerProvider).folder;
    if (folder != null && (folder == root || folder.startsWith('$root/'))) {
      browse.openFolder(null);
    }
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
        _leaveFolderOn(place.rootPath);
        messenger.showSnackBar(SnackBar(content: Text(l10n.externalRemoved)));
      case PlaceEjected(:final place):
        _leaveFolderOn(place.rootPath);
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.ejectSafe(placeLabel(l10n, place)))),
        );
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
