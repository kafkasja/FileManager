import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:kfm/app/layout/app_text_size.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'package:kfm/app/layout/app_text_size.dart';

part 'text_scale.g.dart';

const Map<AppTextSize, double> kTextSizeFactor = {
  AppTextSize.system: 1,
  AppTextSize.large: 1.3,
  AppTextSize.extraLarge: 1.6,
};

/// The platform scaler × [factor], at most [maxScale] × fontSize, and never
/// smaller than the platform scaler alone. Wrapping (not replacing) keeps
/// Android 14+ nonlinear scaling: big headings grow less than body text.
@immutable
class AppTextScaler extends TextScaler {
  const new(this.base, this.factor, {this.maxScale = 2.0});

  final TextScaler base;
  final double factor;
  final double maxScale;

  @override
  double scale(double fontSize) {
    final system = base.scale(fontSize);
    final scaled = math.min(system * factor, fontSize * maxScale);
    return math.max(system, scaled);
  }

  // Still abstract in Flutter 3.47, so it must be implemented.
  @Deprecated('Use scale')
  @override
  double get textScaleFactor => scale(14) / 14;

  @override
  bool operator ==(Object other) =>
      other is AppTextScaler &&
      other.base == base &&
      other.factor == factor &&
      other.maxScale == maxScale;

  @override
  int get hashCode => Object.hash(base, factor, maxScale);
}

/// The scaler [size] gives on top of [base] (System = [base] itself).
TextScaler textScalerFor(TextScaler base, AppTextSize size) =>
    size == AppTextSize.system
    ? base
    : AppTextScaler(base, kTextSizeFactor[size]!);

/// MaterialApp.builder hook. System = no override at all.
Widget applyTextScale(BuildContext context, Widget child, AppTextSize size) {
  if (size == AppTextSize.system) return child;
  final mq = MediaQuery.of(context);
  return MediaQuery(
    data: mq.copyWith(textScaler: textScalerFor(mq.textScaler, size)),
    child: child,
  );
}

/// True when body text is scaled 1.5× or more (system font and/or L5):
/// list rows then move wide trailing widgets under their text, so a
/// title never gets squeezed to nothing.
bool isBigText(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(14) >= 14 * 1.5;

/// keepAlive stream like `themeModeProvider`.
@Riverpod(keepAlive: true)
Stream<AppTextSize> textSize(Ref ref) =>
    ref.watch(settingsRepositoryProvider).watch(AppSettings.textSize);
