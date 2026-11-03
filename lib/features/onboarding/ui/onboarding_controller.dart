import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/features/onboarding/domain/onboarding_state.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_controller.g.dart';

/// The first-time tutorial and one-time hints (TASK-L3), over two settings.
/// Writes go through the settings write queue (latest value wins); failures
/// surface on `dbWriteErrorsProvider`.
@Riverpod(keepAlive: true)
class OnboardingController extends _$OnboardingController {
  @override
  Future<OnboardingState> build() async {
    final settings = ref.watch(settingsRepositoryProvider);
    var done = await settings.read(AppSettings.onboardingTutorialDone);
    final hints = await settings.read(AppSettings.onboardingSeenHints);
    // An install that already swiped doesn't need the tutorial. Checked only
    // once per install, so "Show tutorial again" survives a restart.
    if (!await settings.read(AppSettings.onboardingExistingChecked)) {
      if (!done && await ref.read(undoRepositoryProvider).hasAnyAction()) {
        done = true;
        settings
            .write(AppSettings.onboardingTutorialDone, true)
            .fireAndForget();
      }
      settings
          .write(AppSettings.onboardingExistingChecked, true)
          .fireAndForget();
    }
    return OnboardingState(tutorialDone: done, seenHints: hints.toSet());
  }

  OnboardingState get _current =>
      state.value ?? const OnboardingState(tutorialDone: false, seenHints: {});

  /// Done or Skip. A tutorial left by killing the app shows again.
  void finishTutorial() {
    state = AsyncData(_current.copyWith(tutorialDone: true));
    ref
        .read(settingsRepositoryProvider)
        .write(AppSettings.onboardingTutorialDone, true)
        .fireAndForget();
  }

  /// Settings → Swiping → Show tutorial again: the tutorial and every hint.
  void showAgain() {
    state = const AsyncData(
      OnboardingState(tutorialDone: false, seenHints: {}),
    );
    final settings = ref.read(settingsRepositoryProvider);
    settings.write(AppSettings.onboardingTutorialDone, false).fireAndForget();
    settings
        .write(AppSettings.onboardingSeenHints, const <String>[])
        .fireAndForget();
  }

  /// A hint was shown; it won't show again.
  void markHintSeen(String id) {
    final current = _current;
    if (current.seenHints.contains(id)) return;
    final hints = {...current.seenHints, id};
    state = AsyncData(current.copyWith(seenHints: hints));
    ref
        .read(settingsRepositoryProvider)
        .write(
          AppSettings.onboardingSeenHints,
          List<String>.unmodifiable(hints),
        )
        .fireAndForget();
  }
}
