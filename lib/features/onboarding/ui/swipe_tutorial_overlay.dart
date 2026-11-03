import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/features/onboarding/ui/onboarding_controller.dart';

/// Whether the first-time tutorial is on screen (or may still appear while
/// the setting loads). The swipe screen holds the restore snackbar and the
/// action-bar hint back meanwhile.
final swipeTutorialPendingProvider = Provider<bool>(
  (ref) =>
      !(ref.watch(onboardingControllerProvider).value?.tutorialDone ?? false),
);

/// The 3-step first-time tutorial (TASK-L3), a layer over the real swipe
/// screen. Its own dummy card does the demo swipes; a barrier keeps every
/// touch away from the real deck, buttons and Undo, so nothing is recorded.
class SwipeTutorialOverlay extends ConsumerStatefulWidget {
  const new({required this.undoKey, super.key});

  /// On the real Undo button; step 3 draws a ring around it.
  final GlobalKey undoKey;

  @override
  ConsumerState<SwipeTutorialOverlay> createState() =>
      _SwipeTutorialOverlayState();
}

enum _Step { trash, keep, undo }

class _SwipeTutorialOverlayState extends ConsumerState<SwipeTutorialOverlay>
    with TickerProviderStateMixin {
  _Step _step = _Step.trash;

  /// The demo swipe: out to the side, hold, back to the middle.
  late final AnimationController _demo = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  /// The user's own drag of the dummy card (pixels); springs back.
  late final AnimationController _drag = AnimationController.unbounded(
    vsync: this,
  );

  Rect? _ring;

  static const _dragToAdvance = 80.0;

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_demo.status == AnimationStatus.dismissed && !_demo.isAnimating) {
      _playDemo();
    }
  }

  @override
  void dispose() {
    _demo.dispose();
    _drag.dispose();
    super.dispose();
  }

  void _playDemo() {
    if (_step == _Step.undo) return;
    if (_reduceMotion) {
      // The end position, no movement.
      _demo.value = 0.5;
    } else {
      unawaited(_demo.forward(from: 0).orCancel.catchError((Object _) {}));
    }
  }

  void _next() {
    switch (_step) {
      case _Step.trash:
        setState(() => _step = _Step.keep);
      case _Step.keep:
        setState(() => _step = _Step.undo);
      case _Step.undo:
        _finish();
        return;
    }
    _drag.value = 0;
    _demo.value = 0;
    _playDemo();
  }

  void _finish() =>
      ref.read(onboardingControllerProvider.notifier).finishTutorial();

  /// -1 = left (step 1), 1 = right (step 2).
  double get _direction => _step == _Step.trash ? -1 : 1;

  /// 0 → 1 → hold → 0 over the demo.
  double _demoShift(double t) {
    if (_reduceMotion) return t > 0 ? 1 : 0;
    if (t < 0.4) return Curves.easeOutCubic.transform(t / 0.4);
    if (t < 0.7) return 1;
    final back = ((t - 0.7) / 0.3).clamp(0.0, 1.0);
    return 1 - Curves.easeInOutCubic.transform(back);
  }

  void _onDragUpdate(DragUpdateDetails d) {
    _demo
      ..stop()
      ..value = 0;
    _drag.value += d.delta.dx;
  }

  void _onDragEnd(DragEndDetails d) {
    final moved = _drag.value * _direction;
    final fling = (d.primaryVelocity ?? 0) * _direction;
    if (moved > _dragToAdvance || fling > 800) {
      _next();
      return;
    }
    if (_reduceMotion) {
      _drag.value = 0;
    } else {
      unawaited(
        _drag
            .animateTo(
              0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
            )
            .orCancel
            .catchError((Object _) {}),
      );
    }
  }

  /// Step 3: where the real Undo button is, in this layer's coordinates.
  void _measureRing() {
    if (!mounted || _step != _Step.undo) return;
    final target = widget.undoKey.currentContext?.findRenderObject();
    final self = context.findRenderObject();
    Rect? rect;
    if (target is RenderBox &&
        target.attached &&
        target.hasSize &&
        self is RenderBox &&
        self.attached) {
      final topLeft = self.globalToLocal(target.localToGlobal(Offset.zero));
      rect = topLeft & target.size;
    }
    if (rect != _ring) setState(() => _ring = rect);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final spacing = context.tokens.spacing;
    if (_step == _Step.undo) {
      // Recomputed after every layout (rotation, big text).
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureRing());
    }
    final text = switch (_step) {
      _Step.trash => l10n.tutorialStepTrash,
      _Step.keep => l10n.tutorialStepKeep,
      _Step.undo => l10n.tutorialStepUndo,
    };
    final last = _step == _Step.undo;
    return BlockSemantics(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Transparent: blocks every touch, the real Undo button too.
          const ModalBarrier(dismissible: false),
          IgnorePointer(
            child: CustomPaint(
              painter: _ScrimPainter(
                scrim: scheme.scrim.withValues(alpha: 0.6),
                ring: scheme.primary,
                hole: last ? _ring : null,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                spacing * 3,
                spacing * 3,
                spacing * 3,
                // Keeps the controls above the Undo row in step 3.
                spacing * 3 + 64,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: last
                        ? const SizedBox.shrink()
                        : Center(child: _demoCard(context)),
                  ),
                  SizedBox(height: spacing * 2),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          text,
                          key: const ValueKey('tutorialText'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: spacing * 2),
                  OverflowBar(
                    alignment: MainAxisAlignment.center,
                    spacing: spacing * 2,
                    overflowAlignment: OverflowBarAlignment.center,
                    children: [
                      if (!last)
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _finish,
                          child: Text(l10n.tutorialSkip),
                        ),
                      FilledButton(
                        onPressed: _next,
                        child: Text(
                          last ? l10n.tutorialDone : l10n.tutorialNext,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _demoCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final l10n = context.l10n;
    final trash = _step == _Step.trash;
    final radius = BorderRadius.circular(tokens.radius);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth * 0.62;
        final height = math.min(constraints.maxHeight * 0.9, width * 1.3);
        return GestureDetector(
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          child: AnimatedBuilder(
            animation: Listenable.merge([_demo, _drag]),
            builder: (context, child) {
              final shift = _demoShift(_demo.value);
              final dx =
                  shift * _direction * constraints.maxWidth * 0.28 +
                  _drag.value;
              final progress = (dx.abs() / (constraints.maxWidth * 0.2)).clamp(
                0.0,
                1.0,
              );
              final towards = dx * _direction > 0;
              return Transform.translate(
                offset: Offset(dx, 0),
                child: Transform.rotate(
                  angle: dx / constraints.maxWidth * 0.3,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      child!,
                      if (towards)
                        Opacity(
                          opacity: progress,
                          child: _Pill(
                            text: trash ? l10n.labelTrash : l10n.labelKept,
                            color: trash ? tokens.swipeTrash : tokens.swipeKeep,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
            child: Semantics(
              label: l10n.tutorialDemoCard,
              image: true,
              child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.topStart,
                    end: AlignmentDirectional.bottomEnd,
                    colors: [scheme.primaryContainer, scheme.tertiaryContainer],
                  ),
                ),
                child: Icon(
                  Icons.photo_outlined,
                  size: 72,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Pill extends StatelessWidget {
  const new({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(color: Colors.white),
      ),
    ),
  );
}

/// The dimmed screen; in step 3 with a clear ring around Undo.
class _ScrimPainter extends CustomPainter {
  const new({required this.scrim, required this.ring, required this.hole});

  final Color scrim;
  final Color ring;
  final Rect? hole;

  @override
  void paint(Canvas canvas, Size size) {
    final hole = this.hole;
    final screen = Path()..addRect(Offset.zero & size);
    if (hole == null) {
      canvas.drawPath(screen, Paint()..color = scrim);
      return;
    }
    final radius = hole.longestSide / 2 + 10;
    final circle = Rect.fromCircle(center: hole.center, radius: radius);
    canvas
      ..drawPath(
        Path.combine(PathOperation.difference, screen, Path()..addOval(circle)),
        Paint()..color = scrim,
      )
      ..drawCircle(
        hole.center,
        radius,
        Paint()
          ..color = ring
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
  }

  @override
  bool shouldRepaint(_ScrimPainter old) =>
      old.scrim != scrim || old.ring != ring || old.hole != hole;
}
