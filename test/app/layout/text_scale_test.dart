import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/layout/text_scale.dart';
import 'package:kfm/core/db/settings/app_settings.dart';

/// Grows big fonts less than small ones (like Android 14+).
class _Nonlinear extends TextScaler {
  const new();

  @override
  double scale(double fontSize) => fontSize < 20 ? fontSize * 1.3 : fontSize;

  @Deprecated('Use scale')
  @override
  double get textScaleFactor => 1.3;
}

void main() {
  test('Large multiplies the system scaler by 1.3', () {
    const scaler = AppTextScaler(TextScaler.linear(1.2), 1.3);
    expect(scaler.scale(10), closeTo(15.6, 1e-9));
  });

  test('the factor is capped at 2x the font size', () {
    const scaler = AppTextScaler(TextScaler.linear(1.25), 1.6);
    expect(scaler.scale(14), closeTo(28, 1e-9));
  });

  test('never smaller than the system size (platform 2.2 + Large)', () {
    const scaler = AppTextScaler(TextScaler.linear(2.2), 1.3);
    expect(scaler.scale(14), closeTo(14 * 2.2, 1e-9));
  });

  test('a nonlinear platform scaler stays nonlinear', () {
    const scaler = AppTextScaler(_Nonlinear(), 1.3);
    final heading = scaler.scale(32) / 32;
    final body = scaler.scale(14) / 14;
    expect(heading, lessThan(body));
  });

  test('equality covers base, factor and cap', () {
    expect(
      const AppTextScaler(TextScaler.linear(1.1), 1.3),
      const AppTextScaler(TextScaler.linear(1.1), 1.3),
    );
    expect(
      const AppTextScaler(TextScaler.linear(1.1), 1.3),
      isNot(const AppTextScaler(TextScaler.linear(1.1), 1.6)),
    );
    expect(
      const AppTextScaler(TextScaler.linear(1.1), 1.3).hashCode,
      const AppTextScaler(TextScaler.linear(1.1), 1.3).hashCode,
    );
  });

  test('unknown stored value reads as System', () {
    expect(AppSettings.textSize.decodeFromDb('"huge"'), AppTextSize.system);
    expect(AppSettings.textSize.decodeFromDb('not json'), AppTextSize.system);
    expect(
      AppSettings.textSize.decodeFromDb('"extraLarge"'),
      AppTextSize.extraLarge,
    );
  });

  testWidgets('System keeps the platform scaler object itself', (tester) async {
    const platform = TextScaler.linear(0.85);
    TextScaler? seen;
    final child = Builder(
      builder: (context) {
        seen = MediaQuery.textScalerOf(context);
        return const SizedBox.shrink();
      },
    );
    Widget host(AppTextSize size) => MediaQuery(
      data: const MediaQueryData(textScaler: platform),
      child: Builder(
        builder: (context) => applyTextScale(context, child, size),
      ),
    );

    await tester.pumpWidget(host(AppTextSize.system));
    expect(identical(seen, platform), isTrue);

    await tester.pumpWidget(host(AppTextSize.extraLarge));
    expect(seen, const AppTextScaler(platform, 1.6));
  });
}
