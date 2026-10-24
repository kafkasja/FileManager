import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// The only place raw design values live. Widgets read them with
/// `Theme.of(context).extension<AppTokens>()!` (or `context.tokens`).
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const new({
    required this.swipeKeep,
    required this.swipeTrash,
    required this.swipeOther,
    required this.radius,
    required this.spacing,
  });

  /// S1/S4 overlay colors.
  final Color swipeKeep;
  final Color swipeTrash;
  final Color swipeOther;
  final double radius;

  /// Base spacing unit; use multiples of it.
  final double spacing;

  static const light = AppTokens(
    swipeKeep: Color(0xFF2E7D32),
    swipeTrash: Color(0xFFC62828),
    swipeOther: Color(0xFF1565C0),
    radius: 16,
    spacing: 8,
  );

  static const dark = AppTokens(
    swipeKeep: Color(0xFF81C784),
    swipeTrash: Color(0xFFEF9A9A),
    swipeOther: Color(0xFF90CAF9),
    radius: 16,
    spacing: 8,
  );

  @override
  AppTokens copyWith({
    Color? swipeKeep,
    Color? swipeTrash,
    Color? swipeOther,
    double? radius,
    double? spacing,
  }) => AppTokens(
    swipeKeep: swipeKeep ?? this.swipeKeep,
    swipeTrash: swipeTrash ?? this.swipeTrash,
    swipeOther: swipeOther ?? this.swipeOther,
    radius: radius ?? this.radius,
    spacing: spacing ?? this.spacing,
  );

  @override
  AppTokens lerp(AppTokens? other, double t) => other == null
      ? this
      : AppTokens(
          swipeKeep: Color.lerp(swipeKeep, other.swipeKeep, t)!,
          swipeTrash: Color.lerp(swipeTrash, other.swipeTrash, t)!,
          swipeOther: Color.lerp(swipeOther, other.swipeOther, t)!,
          radius: lerpDouble(radius, other.radius, t)!,
          spacing: lerpDouble(spacing, other.spacing, t)!,
        );
}

extension AppTokensContext on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
}
