import 'dart:convert';

import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/ui/swipe_deck_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'swipe_layout_controller.g.dart';

/// The layout edited on "Customize swipes" (TASK-P1): the active session's
/// layout, or the saved default when no session is active.
@riverpod
class SwipeLayoutController extends _$SwipeLayoutController {
  @override
  Future<SwipeLayout> build() async {
    final session = await ref.watch(sessionRepositoryProvider).active();
    if (session != null) return session.layout;
    final raw = await ref
        .watch(settingsRepositoryProvider)
        .read(AppSettings.swipeLayoutCurrent);
    return SwipeLayout.decode(raw);
  }

  /// [action] null = the direction does nothing.
  Future<void> setDirection(SwipeDirection direction, SwipeAction? action) =>
      _save((current) => current.withDirection(direction, action));

  Future<void> resetToBasic() => _save((_) => SwipeLayout.basic);

  Future<void> _save(SwipeLayout Function(SwipeLayout current) change) async {
    final next = change(await future);
    if (!ref.mounted) return;
    state = AsyncData(next);
    try {
      final sessions = ref.read(sessionRepositoryProvider);
      final session = await sessions.active();
      if (session != null) {
        // Session row + saved default in one transaction.
        await sessions.saveLayout(session.id, next);
      } else {
        // Never start a session here: that would skip D1's confirmation.
        await ref
            .read(settingsRepositoryProvider)
            .write(AppSettings.swipeLayoutCurrent, jsonEncode(next.toJson()));
      }
      if (ref.mounted && ref.exists(swipeDeckControllerProvider)) {
        await ref.read(swipeDeckControllerProvider.notifier).reloadSession();
      }
    } on Object catch (e, st) {
      if (ref.mounted) state = AsyncError(e, st);
    }
  }
}
