import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/features/cloud/data/cloud_providers.dart';
import 'package:kfm/features/cloud/domain/cloud_destination.dart';
import 'package:kfm/features/folders/domain/move_target.dart';
import 'package:kfm/features/folders/ui/folder_picker_sheet.dart';

import '../../core/files/fake_file_source.dart';
import '../../helpers/pump_app.dart';
import 'fake_cloud.dart';

void main() {
  late FakeCloudWriter writer;
  late FakeCloudTrees trees;

  setUp(() {
    writer = FakeCloudWriter((_) => null);
    trees = FakeCloudTrees();
  });

  Future<TestApp> pump(WidgetTester tester) => pumpApp(
    tester,
    files: FakeFileSource()..addFile('/storage/emulated/0/DCIM/a.jpg'),
    overrides: [
      cloudWriterProvider.overrideWithValue(writer),
      cloudTreePlatformProvider.overrideWithValue(trees),
    ],
  );

  testWidgets('no destination: no Cloud group, no runner, no channel call', (
    tester,
  ) async {
    final app = await pump(tester);
    expect(
      await tester.runAsync(
        () => app.container.read(cloudResumeProvider.future),
      ),
      isFalse,
    );
    final context = tester.element(find.byType(Scaffold).first);
    showMoveTargetPicker(context).ignore();
    await tester.pumpAndSettle();
    expect(find.text('Move to'), findsOneWidget);
    expect(find.text('Cloud'), findsNothing);
    expect(writer.calls, isEmpty);
    expect(trees.calls, isEmpty);
  });

  testWidgets('a destination shows in Move/Copy targets, never in P2', (
    tester,
  ) async {
    final app = await pump(tester);
    final id = (await tester.runAsync(
      () => app.container
          .read(cloudDestinationsRepositoryProvider)
          .add(
            location: 'content://drive/tree/p',
            label: 'Google Drive › Photos',
            provider: CloudProviderGuess.googleDrive,
          ),
    ))!;
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(Scaffold).first);

    // P2's picker (swipe actions) stays cloud-free.
    showFolderPicker(context).ignore();
    await tester.pumpAndSettle();
    expect(find.text('Google Drive › Photos'), findsNothing);
    Navigator.of(tester.element(find.text('Choose a folder'))).pop();
    await tester.pumpAndSettle();

    final picked = <MoveTarget?>[];
    showMoveTargetPicker(context).then(picked.add).ignore();
    await tester.pumpAndSettle();
    expect(find.text('Cloud'), findsOneWidget);
    await tester.tap(find.text('Google Drive › Photos'));
    await tester.pumpAndSettle();
    expect(picked.single, isA<CloudTarget>());
    expect((picked.single! as CloudTarget).destinationId, id);
    expect(writer.calls, isEmpty);
  });

  testWidgets('destinations screen: add, remove with forget unticked', (
    tester,
  ) async {
    final app = await pump(tester);
    trees.nextPick = 'content://drive/tree/p';
    final router = app.container.read(routerProvider);
    router.go(AppRoutes.cloudSettings);
    await tester.pumpAndSettle();
    expect(find.text('No cloud folders yet'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('cloud-add')));
    await tester.pumpAndSettle();
    expect(find.text('Google Drive › Photos'), findsOneWidget);
    expect(trees.persisted, {'content://drive/tree/p'});

    final dest = (await tester.runAsync(
      () => app.container
          .read(cloudDestinationsRepositoryProvider)
          .watchActive()
          .first,
    ))!.single;
    await tester.tap(find.byKey(ValueKey('cloud-dest-menu-${dest.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('cloud-menu-remove')));
    await tester.pumpAndSettle();
    expect(
      find.text('Also forget which files were uploaded here'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('cloud-remove-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('Google Drive › Photos'), findsNothing);
    expect(trees.persisted, isEmpty);
    final row = await tester.runAsync(
      () =>
          app.container.read(cloudDestinationsRepositoryProvider).byId(dest.id),
    );
    expect(row!.isActive, isFalse, reason: 'soft delete');
  });
}
