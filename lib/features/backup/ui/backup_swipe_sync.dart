import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/features/backup/data/backup_providers.dart';
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

/// "Undo last import" with the swipe deck in step (X6 follow-up): first
/// switches to the preset the undo returns to (the pre-import one, else
/// Basic) while the imported presets still exist, so the switch can commit
/// the open session's queued deletes. A blocked switch throws and nothing
/// is undone. Then undoes and syncs as after an import.
Future<void> undoImportAndSync(ProviderContainer container) async {
  final service = container.read(backupServiceProvider);
  final target = await service.undoPresetTarget();
  if (target == null) throw StateError('no import to undo');
  // A pre-import preset deleted since comes back with the undo: go through
  // Basic, the undo's own switch moves on to it.
  final first = target.exists ? target.presetId : 0;
  await container
      .read(activePresetControllerProvider.notifier)
      .switchTo(first == 0 ? null : first);
  if (container.read(activePresetControllerProvider) case AsyncError(
    :final error,
    :final stackTrace,
  )) {
    Error.throwWithStackTrace(error, stackTrace);
  }
  await syncSwipeAfterBackup(container, await service.undoLastImport());
}
