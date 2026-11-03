import 'package:flutter/foundation.dart';

/// One-time hint ids (TASK-L3).
abstract final class HintIds {
  static const presets = 'presets';
  static const actionBar = 'actionBar';
}

/// What the user has already seen of the first-time help (TASK-L3).
@immutable
class OnboardingState {
  const new({required this.tutorialDone, required this.seenHints});

  final bool tutorialDone;

  /// Hint ids already shown: [HintIds.presets], [HintIds.actionBar].
  final Set<String> seenHints;

  OnboardingState copyWith({bool? tutorialDone, Set<String>? seenHints}) =>
      OnboardingState(
        tutorialDone: tutorialDone ?? this.tutorialDone,
        seenHints: seenHints ?? this.seenHints,
      );

  @override
  bool operator ==(Object other) =>
      other is OnboardingState &&
      other.tutorialDone == tutorialDone &&
      setEquals(other.seenHints, seenHints);

  @override
  int get hashCode =>
      Object.hash(tutorialDone, Object.hashAllUnordered(seenHints));
}
