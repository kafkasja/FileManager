import 'package:flutter/material.dart';
import 'package:kfm/app/theme/app_tokens.dart';

/// Shows a label pill for ~900 ms. A new [show] replaces the current label
/// at once (no queue), so fast swiping never shows a stale label.
class SwipeToastController extends ValueNotifier<(String, int)?> {
  new() : super(null);

  int _seq = 0;

  void show(String text) => value = (text, ++_seq);
}

class SwipeToast extends StatefulWidget {
  const new({required this.controller, super.key});

  final SwipeToastController controller;

  static const fadeIn = Duration(milliseconds: 120);
  static const hold = Duration(milliseconds: 900);
  static const fadeOut = Duration(milliseconds: 200);

  @override
  State<SwipeToast> createState() => _SwipeToastState();
}

class _SwipeToastState extends State<SwipeToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: SwipeToast.fadeIn + SwipeToast.hold + SwipeToast.fadeOut,
  );

  late final Animation<double> _opacity = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 0, end: 1),
      weight: SwipeToast.fadeIn.inMilliseconds.toDouble(),
    ),
    TweenSequenceItem(
      tween: ConstantTween(1),
      weight: SwipeToast.hold.inMilliseconds.toDouble(),
    ),
    TweenSequenceItem(
      tween: Tween(begin: 1, end: 0),
      weight: SwipeToast.fadeOut.inMilliseconds.toDouble(),
    ),
  ]).animate(_anim);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_restart);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_restart);
    _anim.dispose();
    super.dispose();
  }

  void _restart() {
    setState(() {});
    _anim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.value?.$1;
    if (text == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: FadeTransition(
        opacity: _opacity,
        child: Container(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: context.tokens.spacing * 2,
            vertical: context.tokens.spacing,
          ),
          decoration: BoxDecoration(
            color: scheme.inverseSurface,
            borderRadius: BorderRadius.circular(context.tokens.radius * 2),
          ),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: scheme.onInverseSurface),
          ),
        ),
      ),
    );
  }
}
