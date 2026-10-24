import 'package:flutter/material.dart';
import 'package:kfm/app/theme/app_tokens.dart';

/// [seed] is the hook for L1 color themes. Text sizes come only from the
/// text theme (L5 big text scales them).
ThemeData buildTheme(
  Brightness brightness, {
  Color seed = const Color(0xFF3F51B5),
}) {
  final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
  return ThemeData(
    colorScheme: scheme,
    extensions: [
      if (brightness == Brightness.light) AppTokens.light else AppTokens.dark,
    ],
    visualDensity: VisualDensity.standard,
    // Messages float above each screen's bottom controls (the swipe undo
    // button, Trash selection bar, Rename button) instead of covering them.
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      insetPadding: EdgeInsets.fromLTRB(16, 0, 16, 88),
    ),
  );
}
