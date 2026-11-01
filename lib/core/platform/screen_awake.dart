import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

part 'screen_awake.g.dart';

/// Keeps the screen on (TASK-N1: while the share screen is open, because
/// screen-off pauses the app, which stops sharing on Android).
abstract interface class ScreenAwake {
  Future<void> keepOn({required bool on});
}

class WakelockScreenAwake implements ScreenAwake {
  const new();

  @override
  Future<void> keepOn({required bool on}) => WakelockPlus.toggle(enable: on);
}

@Riverpod(keepAlive: true)
ScreenAwake screenAwake(Ref ref) => const WakelockScreenAwake();
