import 'package:flutter/material.dart';
import 'package:kfm/app/theme/app_accent.dart';
import 'package:kfm/app/theme/app_tokens.dart';

export 'package:kfm/app/theme/app_accent.dart';

/// F6's seed: the default (blue) look.
const Color kDefaultSeed = Color(0xFF3F51B5);

/// Blue keeps F6's seed, so the default look doesn't change.
const Map<AppAccent, Color> kAccentSeeds = {
  AppAccent.blue: kDefaultSeed,
  AppAccent.green: Color(0xFF2E9D63),
  AppAccent.purple: Color(0xFF7B5BD6),
  AppAccent.orange: Color(0xFFE07A2D),
  AppAccent.mono: Color(0xFF6B6B6B),
};

/// The seed for [accent]. [systemSeed] is the wallpaper color, null when the
/// device has none (then System falls back to blue).
Color accentSeed(AppAccent accent, {Color? systemSeed}) =>
    accent == AppAccent.system
    ? systemSeed ?? kDefaultSeed
    : kAccentSeeds[accent] ?? kDefaultSeed;

/// The color scheme of one color theme. Mono uses the monochrome variant.
ColorScheme accentScheme(
  Brightness brightness, {
  Color seed = kDefaultSeed,
  bool monochrome = false,
}) => ColorScheme.fromSeed(
  seedColor: seed,
  brightness: brightness,
  dynamicSchemeVariant: monochrome
      ? DynamicSchemeVariant.monochrome
      : DynamicSchemeVariant.tonalSpot,
);

/// [seed] + [monochrome] pick the L1 color theme. Swipe colors stay semantic
/// in [AppTokens] and never follow the accent. Text sizes come only from the
/// text theme; L5 scales them through `MediaQuery.textScaler`.
ThemeData buildTheme(
  Brightness brightness, {
  Color seed = kDefaultSeed,
  bool monochrome = false,
}) {
  final scheme = accentScheme(brightness, seed: seed, monochrome: monochrome);
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
