import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/data/share_server.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'share_server_controller.g.dart';

/// Starts and stops "Share this device" (TASK-N1). The share screen calls
/// [startSharing] when opened and [stopSharing] on dispose; N5 adds the
/// app-lifecycle hook here. Errors land in [ShareServerState.error] (rule 8).
@Riverpod(keepAlive: true)
class ShareServerController extends _$ShareServerController {
  /// Bumped by every start/stop, so a start that finishes after a stop
  /// (screen closed while "Preparing…") shuts its server down again.
  int _generation = 0;

  @override
  ShareServerState build() => ShareServerState.stopped;

  Future<void> startSharing() async {
    if (state.status == ShareServerStatus.running ||
        state.status == ShareServerStatus.starting) {
      return;
    }
    final gen = ++_generation;
    state = const ShareServerState(status: ShareServerStatus.starting);
    final server = ref.read(shareServerProvider);
    try {
      final next = await server.start();
      if (gen != _generation) {
        await server.stop();
        return;
      }
      state = next;
    } on Object catch (e) {
      if (gen != _generation) return;
      await server.stop();
      state = ShareServerState(status: ShareServerStatus.error, error: e);
    }
  }

  /// Safe to call from a widget's `dispose`: the state changes only after
  /// the first await (Riverpod forbids changes while the tree finalizes).
  Future<void> stopSharing() async {
    _generation++;
    ref.read(pairNonceStoreProvider).clear();
    await ref.read(shareServerProvider).stop();
    state = ShareServerState.stopped;
  }
}
