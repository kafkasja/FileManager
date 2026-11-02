import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/theme/app_theme.dart';
import 'package:kfm/app/theme/app_tokens.dart';

/// WCAG 2.x contrast ratio.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  test('blue keeps F6 seed (default look unchanged)', () {
    expect(kAccentSeeds[AppAccent.blue], const Color(0xFF3F51B5));
    expect(accentSeed(AppAccent.blue), const Color(0xFF3F51B5));
    // System without a wallpaper palette falls back to blue.
    expect(accentSeed(AppAccent.system), const Color(0xFF3F51B5));
    expect(
      accentSeed(AppAccent.system, systemSeed: const Color(0xFF00897B)),
      const Color(0xFF00897B),
    );
    for (final b in Brightness.values) {
      expect(
        buildTheme(b).colorScheme,
        ColorScheme.fromSeed(seedColor: const Color(0xFF3F51B5), brightness: b),
      );
    }
  });

  for (final accent in AppAccent.values.where((a) => a != AppAccent.system)) {
    for (final brightness in Brightness.values) {
      test('${accent.name} ${brightness.name}: text pairs reach WCAG AA', () {
        final theme = buildTheme(
          brightness,
          seed: accentSeed(accent),
          monochrome: accent == AppAccent.mono,
        );
        final s = theme.colorScheme;
        final pairs = <String, (Color, Color)>{
          'onPrimary/primary': (s.onPrimary, s.primary),
          'onSurface/surface': (s.onSurface, s.surface),
          'onSurfaceVariant/surface': (s.onSurfaceVariant, s.surface),
          'onPrimaryContainer/primaryContainer': (
            s.onPrimaryContainer,
            s.primaryContainer,
          ),
          'onSecondaryContainer/secondaryContainer': (
            s.onSecondaryContainer,
            s.secondaryContainer,
          ),
          'primary/surface': (s.primary, s.surface),
          'onError/error': (s.onError, s.error),
        };
        for (final MapEntry(:key, :value) in pairs.entries) {
          expect(
            _contrast(value.$1, value.$2),
            greaterThanOrEqualTo(4.5),
            reason: key,
          );
        }
        // Swipe colors never follow the accent.
        expect(
          theme.extension<AppTokens>(),
          brightness == Brightness.light ? AppTokens.light : AppTokens.dark,
        );
      });
    }
  }
}
