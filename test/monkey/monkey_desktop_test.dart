// Randomized UI testing of the desktop shell (see monkey_harness.dart).
// Replay: KFM_MONKEY_SEED=<seed> flutter test test/monkey/monkey_desktop_test.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../desktop/desktop_helpers.dart';
import 'monkey_harness.dart';

void main() {
  final actions = monkeyActions(150);
  for (final seed in monkeySeeds(defaultSeeds: 2, offset: 1000)) {
    testWidgets(
      'desktop monkey seed $seed',
      (tester) async {
        await runMonkey(
          tester,
          seed: seed,
          actions: actions,
          desktop: true,
          pump: (tester, files, videos) =>
              pumpDesktopApp(tester, files: files, videos: videos),
        );
      },
      // Windows behaviour (no automatic PrimaryScrollController for every
      // vertical list, desktop shortcuts and scrollbars), like the real app.
      variant: TargetPlatformVariant.only(TargetPlatform.windows),
      timeout: const Timeout(Duration(minutes: 5)),
    );
  }
}
