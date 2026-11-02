import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/features/filters/domain/file_filter.dart';
import 'package:kfm/features/presets/data/preset_repository.dart';
import 'package:kfm/features/presets/domain/preset.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/session/domain/session.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';
import 'package:kfm/features/swipe/ui/swipe_layout_controller.dart';

/// S6: whether [session] (of [preset]) differs from what the preset saved:
/// its layout, its filter, or whether it includes reviewed files (P7: the
/// session's switch, else the preset's).
bool presetSetupModified(Session session, Preset preset) {
  if (session.layout != preset.layout) return true;
  final ours = FileFilter.decode(session.filterJson);
  final saved = FileFilter.decode(preset.filterJson);
  if (ours.copyWith(clearIncludeReviewed: true) !=
      saved.copyWith(clearIncludeReviewed: true)) {
    return true;
  }
  return (ours.includeReviewed ?? preset.includeReviewed) !=
      (saved.includeReviewed ?? preset.includeReviewed);
}

/// The Swipe tab's session (null while the deck loads).
final Provider<Session?> _localSessionProvider = Provider.autoDispose<Session?>(
  (ref) =>
      ref.watch(swipeDeckControllerProvider.select((d) => d.value?.session)),
);

/// S6: the preset the Swipe tab uses (null = Basic), as saved.
final Provider<PresetEntry?> activePresetEntryProvider =
    Provider.autoDispose<PresetEntry?>((ref) {
      final id = ref.watch(activePresetIdProvider).value ?? 0;
      if (id == 0) return null;
      final presets = ref.watch(presetsProvider).value ?? const [];
      return presets.where((p) => p.id == id).firstOrNull;
    });

/// S6: the active preset's session has unsaved changes (S6-3 a: edits apply
/// to the session at once and never write the preset silently).
final Provider<bool> presetModifiedProvider = Provider.autoDispose<bool>((ref) {
  final preset = ref.watch(activePresetEntryProvider);
  final session = ref.watch(_localSessionProvider);
  if (preset is! Preset || session == null) return false;
  if (session.presetId != preset.id) return false;
  return presetSetupModified(session, preset);
});

final StreamProvider<bool> _basicIncludeReviewedProvider =
    StreamProvider.autoDispose<bool>(
      (ref) => ref
          .watch(settingsRepositoryProvider)
          .watch(AppSettings.basicIncludeReviewed),
    );

/// S6/P7: whether the Swipe tab's deck shows reviewed files now (null
/// while loading).
final Provider<bool?> swipeIncludesReviewedProvider =
    Provider.autoDispose<bool?>((ref) {
      final session = ref.watch(_localSessionProvider);
      if (session == null) return null;
      final override = FileFilter.decode(session.filterJson).includeReviewed;
      if (override != null) return override;
      final key = session.presetId ?? 0;
      if (key == 0) return ref.watch(_basicIncludeReviewedProvider).value;
      final presets = ref.watch(presetsProvider).value ?? const [];
      final preset = presets.where((p) => p.id == key).firstOrNull;
      return preset is Preset && preset.includeReviewed;
    });

/// S6 setup actions on the Swipe tab's session and its preset.
extension PresetSetupActions on WidgetRef {
  /// Save: writes the session's layout, filter and include-reviewed into
  /// its preset. False when there is no readable preset.
  Future<bool> saveSessionToPreset() async {
    final session = read(swipeDeckControllerProvider).value?.session;
    final id = session?.presetId;
    if (session == null || id == null) return false;
    final repo = read(presetRepositoryProvider);
    final preset = await repo.byId(id);
    if (preset is! Preset) return false;
    final filter = FileFilter.decode(session.filterJson);
    final base = filter.copyWith(clearIncludeReviewed: true);
    await repo.updateSetup(
      id,
      layout: session.layout,
      filterJson: base.isEmpty ? null : jsonEncode(base.toJson()),
    );
    await repo.setIncludeReviewed(
      id,
      value: filter.includeReviewed ?? preset.includeReviewed,
    );
    return true;
  }

  /// Revert: the session takes the preset's saved setup again (no deletes
  /// are committed: it's the same session).
  Future<void> revertSessionToPreset() async {
    final id = read(swipeDeckControllerProvider).value?.session.presetId;
    if (id == null) return;
    final preset = await read(presetRepositoryProvider).byId(id);
    if (preset is! Preset) return;
    await read(sessionRepositoryProvider).applyPresetToOpenSession(
      id,
      layout: preset.layout,
      filterJson: preset.filterJson,
    );
    invalidate(swipeDeckControllerProvider);
    invalidate(swipeLayoutControllerProvider);
  }

  /// P7 switch: Basic's own setting, or this session's override in a
  /// preset (like the filter sheet).
  Future<void> setSwipeIncludeReviewed({required bool value}) async {
    final deck = read(swipeDeckControllerProvider.notifier);
    final filter = deck.filter;
    if (deck.presetKey == 0) {
      await read(settingsRepositoryProvider)
          .write(AppSettings.basicIncludeReviewed, value);
      await deck.applyFilter(filter.copyWith(clearIncludeReviewed: true));
    } else {
      await deck.applyFilter(filter.copyWith(includeReviewed: value));
    }
  }
}
