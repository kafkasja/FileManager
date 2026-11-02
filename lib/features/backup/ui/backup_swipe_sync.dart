import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/features/presets/ui/active_preset_controller.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';
import 'package:kfm/features/swipe/ui/swipe_layout_controller.dart';

/// After an import or its undo (TASK-X6): switches to [switchTo] (0 =
/// Basic) when the backup service asked for it, and reloads the swipe deck
/// so it picks up the new layout and reviewed labels. A blocked switch
/// (queued deletes) shows up on `activePresetControllerProvider` like any
/// other switch.
Future<void> syncSwipeAfterBackup(
  ProviderContainer container,
  int? switchTo,
) async {
  if (switchTo != null) {
    await container
        .read(activePresetControllerProvider.notifier)
        .switchTo(switchTo == 0 ? null : switchTo);
  }
  container
    ..invalidate(swipeDeckControllerProvider)
    ..invalidate(swipeLayoutControllerProvider);
}
