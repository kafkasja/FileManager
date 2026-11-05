import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// The one bar rule for headers above long phone lists (TASK-E4, user
/// decision): "Hides while scrolling down, but snaps fully back on any
/// small upward scroll and always shows at the top. Never stuck
/// half-hidden."
///
/// A sliver (put it first in a `CustomScrollView`). Scrolling down slides
/// it away with the finger; an upward scroll of [jitter] or more starts the
/// show animation at once (no waiting for the finger to lift); when a
/// scroll settles it is fully shown or fully hidden; at offset 0 it is
/// always shown. While shown over scrolled content it paints over it
/// (Flutter's `FloatingHeaderSnapMode.overlay`), on the surface colour so
/// the grid never shows through.
///
/// Flutter's `SliverFloatingHeader` only snaps when the scroll ends, so a
/// small upward drag would leave it half shown: this is its own sliver.
class HidingHeaderSliver extends StatefulWidget {
  const new({required this.child, super.key});

  final Widget child;

  /// Upward scrolls shorter than this (dp) are finger jitter.
  static const double jitter = 4;

  /// How long showing or hiding takes once it snaps.
  static const Duration duration = Duration(milliseconds: 180);

  @override
  State<HidingHeaderSliver> createState() => _HidingHeaderSliverState();
}

// Not the single-ticker mixin: the sliver recreates its controller when
// it is detached and attached again (monkey test, seed 2).
class _HidingHeaderSliverState extends State<HidingHeaderSliver>
    with TickerProviderStateMixin {
  ScrollPosition? _position;
  final GlobalKey _header = GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _position?.isScrollingNotifier.removeListener(_onScrolling);
    _position = Scrollable.maybeOf(context)?.position;
    _position?.isScrollingNotifier.addListener(_onScrolling);
  }

  @override
  void dispose() {
    _position?.isScrollingNotifier.removeListener(_onScrolling);
    super.dispose();
  }

  void _onScrolling() {
    final position = _position;
    if (position == null || position.isScrollingNotifier.value) return;
    // After the frame that lays out the final offset (the notifier fires
    // before it).
    WidgetsBinding.instance
      ..addPostFrameCallback((_) {
        if (!mounted || position.isScrollingNotifier.value) return;
        final render = _header.currentContext?.findRenderObject();
        if (render is _RenderHidingHeader) render.settle(position);
      })
      ..scheduleFrame();
  }

  @override
  Widget build(BuildContext context) => _HidingHeader(
    key: _header,
    vsync: this,
    child: Material(
      color: Theme.of(context).colorScheme.surface,
      child: widget.child,
    ),
  );
}

class _HidingHeader extends SingleChildRenderObjectWidget {
  const new({required this.vsync, super.child, super.key});

  final TickerProvider vsync;

  @override
  _RenderHidingHeader createRenderObject(BuildContext context) =>
      _RenderHidingHeader(vsync);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderHidingHeader renderObject,
  ) => renderObject.vsync = vsync;
}

class _RenderHidingHeader extends RenderSliverSingleBoxAdapter {
  new(this.vsync);

  TickerProvider vsync;
  AnimationController? _controller;
  Animation<double>? _animation;

  /// How much of the header is above the viewport's top edge: 0 = fully
  /// shown, `childExtent` = hidden. Never more than the scroll offset (at
  /// the top it is in place).
  double _hidden = 0;
  double? _lastScrollOffset;

  /// Upward scroll since the last downward one (jitter guard).
  double _upward = 0;

  /// The direction of the last movement: true = towards the end.
  bool _lastDown = false;

  double get _childExtent => child == null ? 0 : child!.size.height;

  bool get _animating => _controller?.isAnimating ?? false;

  void _animateTo(double target) {
    final controller = _controller ??= AnimationController(
      vsync: vsync,
      duration: HidingHeaderSliver.duration,
    )..addListener(_tick);
    if (_animating && _animation != null) {
      // Already going there.
      final end = (_animation! as _TweenAnimation).end;
      if (end == target) return;
    }
    if (_hidden == target) {
      controller.stop();
      return;
    }
    _animation = _TweenAnimation(controller, begin: _hidden, end: target);
    controller.forward(from: 0);
  }

  void _tick() {
    final value = _animation?.value;
    if (value == null || value == _hidden) return;
    _hidden = value;
    markNeedsLayout();
  }

  /// The scroll came to rest: fully shown or fully hidden, never between.
  void settle(ScrollPosition position) {
    if (!attached || child == null) return;
    final extent = _childExtent;
    if (_animating) {
      // A show (or hide) that's running finishes on its own.
      return;
    }
    if (_hidden <= 0 || _hidden >= extent) return;
    final scrollOffset = constraints.scrollOffset;
    if (!_lastDown) {
      _animateTo(0);
    } else if (scrollOffset >= extent) {
      _animateTo(extent);
    } else if (position.maxScrollExtent >= extent) {
      // Near the top the header is still in place: scroll it fully away
      // (after the scroll activity that just ended is replaced).
      final target = position.pixels + (extent - scrollOffset);
      scheduleMicrotask(() {
        if (!attached || position.isScrollingNotifier.value) return;
        position
            .animateTo(
              math.min(target, position.maxScrollExtent),
              duration: HidingHeaderSliver.duration,
              curve: Curves.easeOut,
            )
            .ignore();
      });
    } else {
      // Too little content to hide it: show it.
      _animateTo(0);
    }
  }

  @override
  void performLayout() {
    final scrollOffset = constraints.scrollOffset;
    child!.layout(constraints.asBoxConstraints(), parentUsesSize: true);
    final extent = _childExtent;
    final last = _lastScrollOffset;
    if (last == null) {
      _hidden = math.min(scrollOffset, extent);
    } else {
      final delta = scrollOffset - last;
      if (delta > 0) {
        _lastDown = true;
        _upward = 0;
        _controller?.stop();
        _hidden = math.min(extent, _hidden + delta);
      } else if (delta < 0) {
        _lastDown = false;
        _upward -= delta;
        if (_upward >= HidingHeaderSliver.jitter && _hidden > 0) {
          _animateTo(0);
        }
      }
    }
    // In place at the top: never hidden more than scrolled.
    _hidden = _hidden.clamp(0, math.min(scrollOffset, extent));
    _lastScrollOffset = scrollOffset;

    final paintExtent = extent - _hidden;
    // Overlay: the content below lays out as if the header scrolled away.
    final layoutExtent = math.max(0, extent - scrollOffset).toDouble();
    geometry = SliverGeometry(
      paintOrigin: math.min(constraints.overlap, 0),
      scrollExtent: extent,
      paintExtent: paintExtent.clamp(0, constraints.remainingPaintExtent),
      layoutExtent: layoutExtent.clamp(0, constraints.remainingPaintExtent),
      maxPaintExtent: extent,
      hasVisualOverflow: true,
    );
  }

  @override
  double childMainAxisPosition(RenderBox child) =>
      geometry == null ? 0 : math.min(0, geometry!.paintExtent - _childExtent);

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) =>
      applyPaintTransformForBoxChild(child, transform);

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null || !geometry!.visible) return;
    context.paintChild(
      child!,
      offset + Offset(0, childMainAxisPosition(child!)),
    );
  }

  @override
  void detach() {
    _controller?.dispose();
    _controller = null;
    super.detach();
  }
}

class _TweenAnimation extends Animation<double>
    with AnimationWithParentMixin<double> {
  new(this.parent, {required this.begin, required this.end});

  @override
  final Animation<double> parent;
  final double begin;
  final double end;

  @override
  double get value =>
      begin + (end - begin) * Curves.easeOut.transform(parent.value);
}
