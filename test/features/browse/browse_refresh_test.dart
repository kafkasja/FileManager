import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/browse/ui/widgets/file_results_view.dart';
import 'package:kfm/features/browse/ui/widgets/file_tile.dart';

import '../../core/files/fake_file_source.dart';
import '../../helpers/pump_app.dart';

/// TASK-E4 (A5): pull to refresh in Browse rescans and shows new files;
/// a failure would say so.
void main() {
  testWidgets('pull down on All finds a file added since', (tester) async {
    final files = FakeFileSource()
      ..addFile(
        '/storage/emulated/0/DCIM/Camera/a.jpg',
        modifiedAt: DateTime.utc(2025),
      );
    await pumpApp(tester, files: files);
    await tester.tap(find.text('Browse').last);
    await tester.pumpAndSettle();
    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(find.byType(FileGridTile), findsOneWidget);
    files.addFile(
      '/storage/emulated/0/DCIM/Camera/b.jpg',
      modifiedAt: DateTime.now().toUtc().add(const Duration(minutes: 1)),
    );
    await tester.timedDrag(
      find.byType(FileResultsView),
      const Offset(0, 400),
      const Duration(milliseconds: 600),
    );
    await tester.pumpAndSettle();
    expect(find.text("Couldn't refresh. Try again."), findsNothing);
    expect(find.byType(FileGridTile), findsNWidgets(2));
    await tester.pump(const Duration(seconds: 6));
  });
}
