import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/form_factor.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/features/onboarding/ui/onboarding_controller.dart';
import 'package:kfm/features/reviewed/ui/reset_reviewed_dialog.dart';
import 'package:kfm/features/session/ui/clear_sheet.dart';
import 'package:kfm/features/settings/ui/settings_section.dart';
import 'package:kfm/features/settings/ui/widgets/settings_tiles.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'swipe_settings_section.g.dart';

/// Vibration on swipes (S4), cached so a swipe never waits for the DB.
@Riverpod(keepAlive: true)
Stream<bool> hapticsEnabled(Ref ref) =>
    ref.watch(settingsRepositoryProvider).watch(AppSettings.hapticsEnabled);

/// P7: the "Reviewed" badge on swipe cards.
@Riverpod(keepAlive: true)
Stream<bool> showReviewedBadge(Ref ref) =>
    ref.watch(settingsRepositoryProvider).watch(AppSettings.showReviewedBadge);

/// P9: buttons under the card instead of (or next to) swiping.
@Riverpod(keepAlive: true)
Stream<bool> swipeButtonsMode(Ref ref) =>
    ref.watch(settingsRepositoryProvider).watch(AppSettings.swipeButtonsMode);

/// P8: summary sheet after Done.
@Riverpod(keepAlive: true)
Stream<bool> sessionSummaryEnabled(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watch(AppSettings.statsShowSessionSummary);

/// P4: the optional action bar under the card.
@Riverpod(keepAlive: true)
Stream<bool> actionBarEnabled(Ref ref) =>
    ref.watch(settingsRepositoryProvider).watch(AppSettings.actionBarEnabled);

// Settings → Swiping (S4; P1/P2/P7/P8/P9 rows) as entries (TASK-E2). Desktop
// Sort has presets, the reviewed badge, stats and the summary, but no swipe
// directions, buttons mode, vibration or tutorial.

final swipeCustomizeEntry = SettingsEntry(
  id: 'swipe.customize',
  titleBuilder: (c) => c.l10n.customizeSwipes,
  subtitleBuilder: (c) => c.l10n.customizeSwipesHelp,
  formFactors: const {FormFactor.mobile},
  builder: (c) => SettingsTile(
    icon: Icons.swipe_outlined,
    title: c.l10n.customizeSwipes,
    subtitle: c.l10n.customizeSwipesHelp,
    chevron: true,
    onTap: () => c.go(AppRoutes.customizeSwipes),
  ),
);

final swipePresetsEntry = SettingsEntry(
  id: 'swipe.presets',
  titleBuilder: (c) => c.l10n.settingsPresets,
  subtitleBuilder: (c) => c.l10n.settingsPresetsHelp,
  builder: (c) => SettingsTile(
    icon: Icons.tune,
    title: c.l10n.settingsPresets,
    subtitle: c.l10n.settingsPresetsHelp,
    chevron: true,
    onTap: () => c.go(AppRoutes.presets),
  ),
);

final swipeButtonsModeEntry = SettingsEntry(
  id: 'swipe.buttonsMode',
  titleBuilder: (c) => c.l10n.settingsSwipeButtons,
  subtitleBuilder: (c) => c.l10n.settingsSwipeButtonsHelp,
  formFactors: const {FormFactor.mobile},
  builder: (_) => BoolSettingSwitch(
    icon: Icons.touch_app_outlined,
    title: (l10n) => l10n.settingsSwipeButtons,
    subtitle: (l10n) => l10n.settingsSwipeButtonsHelp,
    provider: swipeButtonsModeProvider,
    setting: AppSettings.swipeButtonsMode,
  ),
);

/// Vibration on swipes (S4): phones only, in Accessibility (TASK-E2).
final hapticsEntry = SettingsEntry(
  id: 'a11y.haptics',
  titleBuilder: (c) => c.l10n.settingsHaptics,
  subtitleBuilder: (c) => c.l10n.settingsHapticsHelp,
  formFactors: const {FormFactor.mobile},
  builder: (_) => BoolSettingSwitch(
    icon: Icons.vibration,
    title: (l10n) => l10n.settingsHaptics,
    subtitle: (l10n) => l10n.settingsHapticsHelp,
    provider: hapticsEnabledProvider,
    setting: AppSettings.hapticsEnabled,
  ),
);

final swipeReviewedBadgeEntry = SettingsEntry(
  id: 'swipe.reviewedBadge',
  titleBuilder: (c) => c.l10n.settingsShowReviewedBadge,
  subtitleBuilder: (c) => c.l10n.settingsShowReviewedBadgeHelp,
  builder: (_) => BoolSettingSwitch(
    icon: Icons.check_circle_outline,
    title: (l10n) => l10n.settingsShowReviewedBadge,
    subtitle: (l10n) => l10n.settingsShowReviewedBadgeHelp,
    provider: showReviewedBadgeProvider,
    setting: AppSettings.showReviewedBadge,
    afterWrite: (ref) => ref.invalidate(swipeDeckControllerProvider),
  ),
);

final swipeStatsEntry = SettingsEntry(
  id: 'swipe.stats',
  titleBuilder: (c) => c.l10n.settingsStats,
  subtitleBuilder: (c) => c.l10n.settingsStatsHelp,
  builder: (c) => SettingsTile(
    icon: Icons.insights_outlined,
    title: c.l10n.settingsStats,
    subtitle: c.l10n.settingsStatsHelp,
    chevron: true,
    onTap: () => c.go(AppRoutes.stats),
  ),
);

final swipeSessionSummaryEntry = SettingsEntry(
  id: 'swipe.sessionSummary',
  titleBuilder: (c) => c.l10n.settingsShowSessionSummary,
  subtitleBuilder: (c) => c.l10n.settingsShowSessionSummaryHelp,
  builder: (_) => BoolSettingSwitch(
    icon: Icons.summarize_outlined,
    title: (l10n) => l10n.settingsShowSessionSummary,
    subtitle: (l10n) => l10n.settingsShowSessionSummaryHelp,
    provider: sessionSummaryEnabledProvider,
    setting: AppSettings.statsShowSessionSummary,
  ),
);

final swipeResetReviewedEntry = SettingsEntry(
  id: 'swipe.resetReviewed',
  titleBuilder: (c) => c.l10n.reviewedReset,
  subtitleBuilder: (c) => c.l10n.reviewedResetHelp,
  builder: (_) => Consumer(
    builder: (c, ref, _) => SettingsTile(
      icon: Icons.layers_clear_outlined,
      title: c.l10n.reviewedReset,
      subtitle: c.l10n.reviewedResetHelp,
      onTap: () => showResetReviewedDialog(c, ref),
    ),
  ),
);

final swipeFreshStartEntry = SettingsEntry(
  id: 'swipe.freshStart',
  titleBuilder: (c) => c.l10n.settingsFreshStart,
  subtitleBuilder: (c) => c.l10n.settingsFreshStartHelp,
  builder: (_) => Consumer(
    builder: (c, ref, _) => SettingsTile(
      icon: Icons.restart_alt,
      title: c.l10n.settingsFreshStart,
      subtitle: c.l10n.settingsFreshStartHelp,
      onTap: () => showClearSheet(c, ref),
    ),
  ),
);

/// L3: the tutorial and the one-time hints once more. Phones only: the
/// tutorial is about swiping.
final tutorialEntry = SettingsEntry(
  id: 'general.tutorial',
  titleBuilder: (c) => c.l10n.tutorialShowAgain,
  subtitleBuilder: (c) => c.l10n.tutorialShowAgainHelp,
  formFactors: const {FormFactor.mobile},
  builder: (_) => Consumer(
    builder: (c, ref, _) => SettingsTile(
      icon: Icons.school_outlined,
      title: c.l10n.tutorialShowAgain,
      subtitle: c.l10n.tutorialShowAgainHelp,
      onTap: () {
        ref.read(onboardingControllerProvider.notifier).showAgain();
        c.go(AppRoutes.swipe);
      },
    ),
  ),
);
