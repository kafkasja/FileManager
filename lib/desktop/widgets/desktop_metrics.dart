import 'package:flutter/widgets.dart';

/// L5 on the desktop (TASK-PL3 big-text pass): how much bigger body text is
/// than normal (system font size × KFM's text size), 1–2. Fixed heights
/// and widths of the desktop screens (rows, bars, columns, tile labels)
/// are multiplied by it so big text never clips.
double desktopTextScale(BuildContext context) =>
    (MediaQuery.textScalerOf(context).scale(14) / 14).clamp(1.0, 2.0);

/// [base] logical pixels grown with [desktopTextScale].
double scaledExtent(BuildContext context, double base) =>
    base * desktopTextScale(context);
