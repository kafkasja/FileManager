// Randomized UI testing (see monkey_harness.dart). Long runs:
//   KFM_MONKEY_SEEDS=50 KFM_MONKEY_ACTIONS=300 flutter test test/monkey
// Replay one failure: KFM_MONKEY_SEED=<seed> flutter test test/monkey
//   --plain-name "phone monkey seed <seed>"
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';
import 'monkey_harness.dart';

void main() {
  final actions = monkeyActions(150);
  for (final seed in monkeySeeds(defaultSeeds: 4)) {
    testWidgets('phone monkey seed $seed', (tester) async {
      await runMonkey(
        tester,
        seed: seed,
        actions: actions,
        pump: (tester, files, videos) async {
          final app = await pumpApp(tester, files: files, videos: videos);
          // Indexer scan → index change (debounced) → deck reload.
          await tester.pump(const Duration(seconds: 1));
          await tester.pump(const Duration(milliseconds: 500));
          return app;
        },
      );
    }, timeout: const Timeout(Duration(minutes: 5)));
  }
}
