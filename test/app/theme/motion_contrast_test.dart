import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/ui/swipe_card.dart';

import '../../core/files/fake_file_source.dart';
import '../../helpers/pump_app.dart';

/// TASK-E2 §7: Reduce motion and High contrast.
void main() {
  testWidgets('Reduce motion: animations off app-wide; a swiped card fades '
      'in place', (tester) async {
    final files = FakeFileSource();
    for (var i = 0; i < 3; i++) {
      files.addFile(
        '/s/DCIM/p$i.jpg',
        modifiedAt: DateTime.utc(2025, 1, 1, 0, i),
      );
    }
    final app = await pumpApp(tester, files: files);
    BuildContext ctx() => tester.element(find.byType(SwipeCard));
    expect(MediaQuery.of(ctx()).disableAnimations, isFalse);

    await app.container
        .read(settingsRepositoryProvider)
        .write(AppSettings.reduceMotion, true);
    await tester.pumpAndSettle();
    expect(MediaQuery.of(ctx()).disableAnimations, isTrue);

    final before = tester.getTopLeft(find.byType(SwipeCard));
    final card = tester.widget<SwipeCard>(find.byType(SwipeCard));
    card.controller!.flyOff(SwipeDirection.left);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    // Mid-fade: the card hasn't moved, it's fading.
    final opacity = tester.widget<Opacity>(
      find
          .descendant(
            of: find.byType(SwipeCard),
            matching: find.byType(Opacity),
          )
          .first,
    );
    expect(opacity.opacity, lessThan(1));
    expect(tester.getTopLeft(find.byType(SwipeCard)), before);
    await tester.pumpAndSettle();
  });

  testWidgets('High contrast changes the color scheme', (tester) async {
    final app = await pumpApp(tester);
    ColorScheme scheme() =>
        tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!.colorScheme;
    final normal = scheme();
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).highContrastTheme,
      isNotNull,
    );
    await app.container
        .read(settingsRepositoryProvider)
        .write(AppSettings.highContrast, true);
    await tester.pumpAndSettle();
    expect(scheme().primary, isNot(normal.primary));
  });
}
