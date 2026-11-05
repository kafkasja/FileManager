import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A dialog on the root navigator that can be closed from elsewhere (a gate
/// event, a stream, the end of a job) without popping whatever sits above
/// it or, with no dialog open, the page below (TASK-E1: a blind
/// `Navigator.of(context, rootNavigator: true).pop()` removed the app's
/// last page and left a black screen).
///
/// [close] removes exactly the route [show] pushed, and only while it is
/// still on the navigator. `test/app/no_blind_root_pop_test.dart` bans the
/// blind pop everywhere else.
final class DialogHandle<T> {
  DialogRoute<T>? _route;
  NavigatorState? _navigator;

  /// Whether the dialog [show] opened is still on the navigator.
  bool get isOpen => _route?.isActive ?? false;

  /// Like `showDialog` (root navigator). Completes with the dialog's result,
  /// or with the result given to [close].
  Future<T?> show(
    BuildContext context, {
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    final navigator = Navigator.of(context, rootNavigator: true);
    final theme = Theme.of(context);
    final route = DialogRoute<T>(
      context: context,
      builder: builder,
      barrierDismissible: barrierDismissible,
      barrierColor: theme.dialogTheme.barrierColor ?? Colors.black54,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      themes: InheritedTheme.capture(from: context, to: navigator.context),
    );
    _route = route;
    _navigator = navigator;
    return navigator.push(route).whenComplete(() {
      if (identical(_route, route)) {
        _route = null;
        _navigator = null;
      }
    });
  }

  /// Closes the dialog if it is still open; a no-op otherwise (it was
  /// answered, closed already, or never shown).
  void close([T? result]) {
    final route = _route;
    final navigator = _navigator;
    _route = null;
    _navigator = null;
    if (route == null || navigator == null) return;
    if (!navigator.mounted || !route.isActive) return;
    navigator.removeRoute(route, result);
  }
}

/// Back from a pushed page: pops when something is below it, otherwise goes
/// to [fallback] (a tab root such as `AppRoutes.swipe`, or
/// `AppRoutes.devices` on desktop). A page restored as the only location
/// (process death, a deep link) has nothing to pop.
void safePop<T extends Object?>(
  BuildContext context, {
  required String fallback,
  T? result,
}) {
  if (GoRouter.maybeOf(context) == null) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop(result);
    return;
  }
  if (context.canPop()) {
    context.pop(result);
  } else {
    context.go(fallback);
  }
}
