import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';

/// A draggable card. The drag offset lives in a ValueNotifier, so dragging
/// never rebuilds anything above the card. Commits past ⅓ of the width
/// (height for up/down) or on a fling; otherwise springs back. Directions
/// without an action ([canSwipe] false) always spring back. With
/// [verticalEnabled] (P1) a drag must clearly favour one axis (diagonal
/// guard); without it, left/right behave exactly as in the basic layout.
class SwipeCard extends StatefulWidget {
  const new({
    required this.child,
    required this.onSwiped,
    required this.canSwipe,
    this.verticalEnabled = false,
    this.onBlocked,
    this.hintFor,
    this.onThresholdCrossed,
    this.onTap,
    this.onDoubleTapDown,
    this.onPinchUpdate,
    this.onPinchEnd,
    super.key,
  });

  final Widget child;

  /// Called after the fly-out animation.
  final void Function(SwipeDirection direction) onSwiped;
  final bool Function(SwipeDirection direction) canSwipe;

  /// Up or down has an action: turns on the diagonal guard.
  final bool verticalEnabled;

  /// Released past the threshold in a direction [canSwipe] refused (the
  /// card springs back). P2 explains why, e.g. a deleted tag.
  final void Function(SwipeDirection direction)? onBlocked;

  /// Colour + icon shown on the card while it is past the threshold (S4).
  final SwipeHint? Function(SwipeDirection direction)? hintFor;

  /// Fired once each time the drag crosses into a committing position.
  final VoidCallback? onThresholdCrossed;

  /// A tap (not the end of a drag): S3 opens the viewer.
  final VoidCallback? onTap;

  /// S3: double-tap zoom at the tapped point.
  final GestureTapDownCallback? onDoubleTapDown;

  /// S3: two-finger pinch on the card (zoom in the viewer). While pinching,
  /// the card doesn't move.
  final void Function(ScaleUpdateDetails details)? onPinchUpdate;
  final VoidCallback? onPinchEnd;

  static const commitFraction = 0.33;
  static const flingVelocity = 800.0;
  static const double maxRotation = 12 * math.pi / 180;
  static const flyOutDuration = Duration(milliseconds: 180);

  /// With [verticalEnabled], the dominant axis must be this many times the
  /// other one; anything closer to diagonal springs back.
  static const dominance = 1.5;

  /// Decides what a released drag does; null = spring back.
  static SwipeDirection? directionFor({
    required Offset offset,
    required Offset velocity,
    required Size size,
    bool verticalEnabled = false,
  }) {
    final bool horizontal;
    if (verticalEnabled) {
      // A quick flick barely moves the card: judge it by its velocity.
      final v = offset.distance < kTouchSlop ? velocity : offset;
      if (v.dx.abs() > v.dy.abs() * dominance) {
        horizontal = true;
      } else if (v.dy.abs() > v.dx.abs() * dominance) {
        horizontal = false;
      } else {
        return null;
      }
    } else {
      horizontal = offset.dx.abs() >= offset.dy.abs();
    }
    if (horizontal) {
      final past = offset.dx.abs() > size.width * commitFraction;
      final fling =
          velocity.dx.abs() > flingVelocity &&
          velocity.dx.sign == offset.dx.sign;
      if (!past && !fling) return null;
      return offset.dx < 0 ? SwipeDirection.left : SwipeDirection.right;
    }
    final past = offset.dy.abs() > size.height * commitFraction;
    final fling =
        velocity.dy.abs() > flingVelocity && velocity.dy.sign == offset.dy.sign;
    if (!past && !fling) return null;
    return offset.dy < 0 ? SwipeDirection.up : SwipeDirection.down;
  }

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

/// What a direction looks like while dragging; `label` e.g. "→ Trash" (P1).
typedef SwipeHint = ({Color color, IconData icon, String label});

class _SwipeCardState extends State<SwipeCard>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<Offset> _offset = ValueNotifier(Offset.zero);
  late final AnimationController _controller = AnimationController.unbounded(
    vsync: this,
  );
  SwipeDirection? _armed;
  Offset _from = Offset.zero;
  Offset _to = Offset.zero;
  bool _flying = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(
      () => _offset.value = Offset.lerp(_from, _to, _controller.value)!,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _offset.dispose();
    super.dispose();
  }

  bool _pinching = false;

  void _onScaleUpdate(ScaleUpdateDetails d, Size size) {
    if (_flying) return;
    if (d.pointerCount > 1 && widget.onPinchUpdate != null) {
      if (!_pinching) {
        _pinching = true;
        _offset.value = Offset.zero;
        _armed = null;
      }
      widget.onPinchUpdate!(d);
      return;
    }
    if (_pinching) return;
    _offset.value += d.focalPointDelta;
    _updateArmed(size);
  }

  void _onScaleEnd(ScaleEndDetails details, Size size) {
    if (_pinching) {
      _pinching = false;
      widget.onPinchEnd?.call();
      return;
    }
    if (_flying) return;
    final direction = SwipeCard.directionFor(
      offset: _offset.value,
      velocity: details.velocity.pixelsPerSecond,
      size: size,
      verticalEnabled: widget.verticalEnabled,
    );
    if (direction != null && widget.canSwipe(direction)) {
      unawaited(_flyOut(direction, size));
    } else {
      if (direction != null) widget.onBlocked?.call(direction);
      _springBack();
    }
  }

  Future<void> _flyOut(SwipeDirection direction, Size size) async {
    _flying = true;
    _from = _offset.value;
    _to = switch (direction) {
      SwipeDirection.left => Offset(-size.width * 1.5, _from.dy),
      SwipeDirection.right => Offset(size.width * 1.5, _from.dy),
      SwipeDirection.up => Offset(_from.dx, -size.height * 1.5),
      SwipeDirection.down => Offset(_from.dx, size.height * 1.5),
    };
    _controller.value = 0;
    await _controller.animateTo(
      1,
      duration: SwipeCard.flyOutDuration,
      curve: Curves.easeIn,
    );
    if (mounted) widget.onSwiped(direction);
  }

  /// Fires [SwipeCard.onThresholdCrossed] once per crossing.
  void _updateArmed(Size size) {
    final d = SwipeCard.directionFor(
      offset: _offset.value,
      velocity: Offset.zero,
      size: size,
      verticalEnabled: widget.verticalEnabled,
    );
    final armed = d != null && widget.canSwipe(d) ? d : null;
    if (armed != null && armed != _armed) widget.onThresholdCrossed?.call();
    _armed = armed;
  }

  void _springBack() {
    _armed = null;
    _from = _offset.value;
    _to = Offset.zero;
    _controller.value = 0;
    _controller.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 400, damping: 28),
        0,
        1,
        0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        // Scale gestures: one finger drags the card, two fingers pinch
        // (S3 zoom). A plain tap opens the viewer.
        return GestureDetector(
          onTap: widget.onTap,
          onDoubleTapDown: widget.onDoubleTapDown,
          onDoubleTap: widget.onDoubleTapDown == null ? null : () {},
          onScaleStart: (_) => _controller.stop(),
          onScaleUpdate: (d) => _onScaleUpdate(d, size),
          onScaleEnd: (d) => _onScaleEnd(d, size),
          child: ValueListenableBuilder<Offset>(
            valueListenable: _offset,
            child: widget.child,
            builder: (context, offset, child) {
              final turn = (offset.dx / size.width).clamp(-1.0, 1.0);
              final armed = _flying ? null : _armed;
              final hint = armed == null ? null : widget.hintFor?.call(armed);
              return Transform.translate(
                offset: offset,
                child: Transform.rotate(
                  angle: turn * SwipeCard.maxRotation,
                  child: hint == null
                      ? child
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            child!,
                            _HintOverlay(hint: hint, direction: armed!),
                          ],
                        ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _HintOverlay extends StatelessWidget {
  const new({required this.hint, required this.direction});

  final SwipeHint hint;
  final SwipeDirection direction;

  @override
  Widget build(BuildContext context) {
    // Swipe directions are physical, never mirrored for RTL.
    final alignment = switch (direction) {
      SwipeDirection.left => Alignment.centerRight,
      SwipeDirection.right => Alignment.centerLeft,
      SwipeDirection.up => Alignment.bottomCenter,
      SwipeDirection.down => Alignment.topCenter,
    };
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: hint.color, width: 6),
          borderRadius: BorderRadius.circular(16),
          color: hint.color.withValues(alpha: 0.15),
        ),
        child: Align(
          alignment: alignment,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(hint.icon, color: hint.color, size: 72),
                DecoratedBox(
                  decoration: ShapeDecoration(
                    shape: StadiumBorder(side: BorderSide(color: hint.color)),
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Text(
                      hint.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(color: hint.color),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
