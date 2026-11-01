import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/db/tables/swipe_sources_table.dart';
import 'package:kfm/features/smart_groups/data/smart_groups_providers.dart';
import 'package:kfm/features/smart_groups/ui/group_detail_screen.dart';
import 'package:kfm/features/smart_groups/ui/groups_screen.dart';

import '../../core/files/fake_file_source.dart';
import '../../core/platform/permissions/fake_permission_service.dart';
import '../../helpers/pump_app.dart';

const _root = '/storage/emulated/0';

class _InlineComputer extends GroupsComputer {
  const new();

  @override
  Future<R> call<R>(FutureOr<R> Function() fn) async => await fn();
}

/// 16 camera photos over June 1–2 (a trip by the days rule: no GPS) and one
/// old screenshot.
FakeFileSource _library() {
  final files = FakeFileSource();
  for (var i = 0; i < 16; i++) {
    files.addFile(
      '$_root/DCIM/Camera/p$i.jpg',
      modifiedAt: DateTime(2025, 6, 1, 10).add(Duration(hours: i * 2)),
    );
  }
  files.addFile(
    '$_root/Pictures/Screenshots/Screenshot_1.png',
    modifiedAt: DateTime(2024),
  );
  return files;
}

Future<TestApp> _pump(WidgetTester tester, FakePermissionService p) async {
  tester.view
    ..physicalSize = const Size(800, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final app = await pumpApp(
    tester,
    files: _library(),
    permissions: p,
    overrides: [
      groupsComputerProvider.overrideWithValue(const _InlineComputer()),
    ],
  );
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
  return app;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
  await tester.pumpAndSettle();
}

String _path(TestApp app) => app.container
    .read(routerProvider)
    .routerDelegate
    .currentConfiguration
    .uri
    .path;

void main() {
  testWidgets('location access is asked only when Groups opens; denied hides '
      'Places, Trips and Screenshots still show', (tester) async {
    final permissions = FakePermissionService()..mediaLocationOnRequest = false;
    final app = await _pump(tester, permissions);
    final settings = app.container.read(settingsRepositoryProvider);

    // App start: nothing asked, nothing run.
    expect(permissions.calls, isNot(contains('requestMediaLocation')));
    expect(await settings.read(AppSettings.smartGroupsActivated), isFalse);
    expect(await app.db.select(app.db.mediaLocations).get(), isEmpty);
    expect(await app.db.select(app.db.smartGroups).get(), isEmpty);

    unawaited(app.container.read(routerProvider).push<void>(AppRoutes.groups));
    await _settle(tester);
    expect(find.byType(GroupsScreen), findsOneWidget);
    expect(
      permissions.calls.where((c) => c == 'requestMediaLocation'),
      hasLength(1),
    );
    expect(await settings.read(AppSettings.smartGroupsActivated), isTrue);

    expect(find.text('Screenshots'), findsOneWidget);
    expect(find.text('Trips'), findsOneWidget);
    expect(find.text('16 files'), findsOneWidget);
    expect(find.text('Places'), findsNothing);
    expect(
      find.text('Allow location access to group photos by place'),
      findsOneWidget,
    );

    // Reopening doesn't ask again; the row does.
    app.container.read(routerProvider).pop();
    await tester.pumpAndSettle();
    unawaited(app.container.read(routerProvider).push<void>(AppRoutes.groups));
    await _settle(tester);
    expect(
      permissions.calls.where((c) => c == 'requestMediaLocation'),
      hasLength(1),
    );
    permissions.mediaLocationOnRequest = true;
    await tester.tap(
      find.text('Allow location access to group photos by place'),
    );
    await _settle(tester);
    expect(
      permissions.calls.where((c) => c == 'requestMediaLocation'),
      hasLength(2),
    );
    expect(
      find.text('Allow location access to group photos by place'),
      findsNothing,
    );
  });

  testWidgets('a group that no longer exists shows "This group changed"', (
    tester,
  ) async {
    final app = await _pump(tester, FakePermissionService());
    unawaited(
      app.container.read(routerProvider).push<void>(AppRoutes.groupFor('g999')),
    );
    await _settle(tester);
    expect(find.byType(GroupDetailScreen), findsOneWidget);
    expect(find.text('This group changed'), findsOneWidget);
    await tester.tap(find.text('Back to groups'));
    await _settle(tester);
    expect(_path(app), AppRoutes.groups);
  });

  testWidgets('Swipe this group opens a list source of the trip', (
    tester,
  ) async {
    final app = await _pump(tester, FakePermissionService());
    unawaited(app.container.read(routerProvider).push<void>(AppRoutes.groups));
    await _settle(tester);
    final trip = (await app.db.select(app.db.smartGroups).get()).single;

    await tester.tap(find.text('16 files'));
    await _settle(tester);
    expect(find.byType(GroupDetailScreen), findsOneWidget);

    // Rename survives in the title.
    await tester.tap(find.byTooltip('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Beach');
    await tester.tap(find.text('Save'));
    await _settle(tester);
    expect(find.text('Beach'), findsOneWidget);

    await tester.tap(find.byTooltip('Swipe this group'));
    await _settle(tester);
    final source = (await app.db.select(app.db.swipeSources).get()).single;
    expect(source.origin, SwipeSourceOrigin.smartGroup);
    expect(source.kind, SwipeSourceKind.files);
    expect(source.title, 'Beach');
    expect(source.returnRoute, AppRoutes.groupFor('g${trip.id}'));
    expect(await app.db.select(app.db.swipeSourceItems).get(), hasLength(16));
    expect(_path(app), AppRoutes.swipe);
  });
}
