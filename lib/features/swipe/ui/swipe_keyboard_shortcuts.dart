import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';

/// Keyboard swiping (TASK-PL1, any platform with a keyboard): the arrow
/// keys swipe in their direction (the same `flyOff` as P9's buttons),
/// Delete swipes the way that trashes, Ctrl+Z undoes, Space opens the
/// viewer. Unmapped directions snap back like an unmapped drag.
class SwipeKeyboardShortcuts extends StatelessWidget {
  const new({
    required this.layout,
    required this.onSwipe,
    required this.onUndo,
    required this.onOpen,
    required this.child,
    super.key,
  });

  final SwipeLayout layout;
  final void Function(SwipeDirection direction) onSwipe;
  final VoidCallback onUndo;
  final VoidCallback onOpen;
  final Widget child;

  /// The direction whose action is trash (Delete), if any.
  SwipeDirection? get _trashDirection {
    for (final d in SwipeDirection.values) {
      if (layout.actionFor(d)?.type == SwipeActionType.trash) return d;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final trash = _trashDirection;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            onSwipe(SwipeDirection.left),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            onSwipe(SwipeDirection.right),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
            onSwipe(SwipeDirection.up),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            onSwipe(SwipeDirection.down),
        if (trash != null)
          const SingleActivator(LogicalKeyboardKey.delete): () =>
              onSwipe(trash),
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): onUndo,
        const SingleActivator(LogicalKeyboardKey.space): onOpen,
      },
      child: Focus(autofocus: true, child: child),
    );
  }
}
