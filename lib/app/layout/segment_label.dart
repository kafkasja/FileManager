import 'package:flutter/material.dart';
import 'package:kfm/app/layout/text_scale.dart';

/// True when a [SegmentedButton] of three or more segments has no room for
/// icons next to its labels: big text (L5 / system font) or a narrow screen
/// (TASK-Q, Q2: 320 dp phones). Callers then leave `icon` out.
bool compactSegments(BuildContext context) =>
    isBigText(context) || MediaQuery.sizeOf(context).width < 360;

/// A [ButtonSegment] label that stays on one line and shrinks to fit
/// instead of breaking a word in the middle ("Fold|ers").
class SegmentLabel extends StatelessWidget {
  const new(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(text, maxLines: 1, softWrap: false),
  );
}
