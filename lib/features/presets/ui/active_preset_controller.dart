import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/features/presets/data/preset_repository.dart';
import 'package:kfm/features/presets/domain/preset.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';
import 'package:kfm/features/swipe/ui/swipe_layout_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'active_preset_controller.g.dart';

/// Switching presets (TASK-P6). Loading while a switch runs; an error
/// (e.g. [PresetSwitchBlocked]) leaves the current preset active.
@Riverpod(keepAlive: true)
class ActivePresetController extends _$ActivePresetController {
  @override
  FutureOr<void> build() {}

  /// [presetId] null = Basic.
  Future<void> switchTo(int? presetId) async {
    final target = presetId ?? 0;
    final sessions = ref.read(sessionRepositoryProvider);
    final settings = ref.read(settingsRepositoryProvider);
    if (await _current() == target) {
      if (await settings.read(AppSettings.activePresetId) != target) {
        await settings.write(AppSettings.activePresetId, target);
      }
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final deletes = ref.read(deleteQueueProvider);
      final active = await sessions.active();
      if (active != null) {
        await sessions.flush();
        // A paused session must never keep queued files (they'd show up in
        // other presets' decks and could stay queued forever).
        await deletes.commitAll(active.id);
        if (await deletes.stillQueued(active.id) > 0) {
          throw const PresetSwitchBlocked();
        }
        await sessions.switchActive(
          fromSessionId: active.id,
          toPresetId: presetId,
        );
      } else {
        await settings.write(AppSettings.activePresetId, target);
      }
    });
    if (!ref.mounted) return;
    ref
      ..invalidate(needsDeleteModeChoiceProvider)
      ..invalidate(swipeDeckControllerProvider)
      ..invalidate(swipeLayoutControllerProvider);
  }

  /// The preset the deck is on: the open local session's, else the
  /// setting. Read from the database, not from activePresetIdProvider's
  /// cached value: that stream is paused while nothing watches it (e.g. on
  /// Settings) and lags behind queued writes, so a backup undo right after
  /// an import saw "already there" and skipped the switch (X6 follow-up).
  Future<int> _current() async {
    final sessions = ref.read(sessionRepositoryProvider);
    await sessions.flush();
    final open = await sessions.active();
    return open == null
        ? await ref
              .read(settingsRepositoryProvider)
              .read(AppSettings.activePresetId)
        : open.presetId ?? 0;
  }

  /// Deletes a preset; the active one switches to Basic first.
  Future<void> delete(int presetId) async {
    if (await _current() == presetId) {
      await switchTo(null);
      if (state.hasError) return;
    }
    await ref.read(presetRepositoryProvider).delete(presetId);
  }
}
