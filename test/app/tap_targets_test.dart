import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/features/browse/ui/widgets/file_tile.dart';

import '../core/files/fake_file_source.dart';
import '../helpers/pump_app.dart';

/// TASK-E4 (A3): the phone's main screens meet Android's 48 dp tap target
/// size at 360x640 (labels are E2's a11y test).
void main() {
  FakeFileSource library() {
    final files = FakeFileSource();
    for (var i = 0; i < 6; i++) {
      files.addFile(
        '/storage/emulated/0/DCIM/Camera/p$i.jpg',
        modifiedAt: DateTime.utc(2025).add(Duration(minutes: i)),
      );
    }
    return files;
  }

  Future<void> pumpPhone(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1080, 1920)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await pumpApp(tester, files: library());
  }

  testWidgets('Swipe', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpPhone(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('Browse', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpPhone(tester);
    await tester.tap(find.text('Browse').last);
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('Viewer', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpPhone(tester);
    await tester.tap(find.text('Browse').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FileGridTile).first);
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('Transfers', (tester) async {
    final handle = tester.ensureSemantics();
    tester.view
      ..physicalSize = const Size(1080, 1920)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final app = await pumpApp(tester, files: library());
    app.container.read(routerProvider).go(AppRoutes.transfers);
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    handle.dispose();
    await tester.pump(const Duration(seconds: 6));
  });
}
