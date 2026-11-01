import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/core/platform/permissions/storage_access.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/features/browse/domain/browse_source_chip.dart';
import 'package:kfm/features/browse/ui/browse_screen.dart';
import 'package:kfm/features/browse/ui/collection_screen.dart';
import 'package:kfm/features/onboarding/ui/permission_gate_screen.dart';
import 'package:kfm/features/search/ui/search_screen.dart';

import '../core/platform/permissions/fake_permission_service.dart';
import '../helpers/pump_app.dart';

/// TASK-H6: a collection page survives a resume and a router refresh.
void main() {
  Future<void> resume(WidgetTester tester, TestApp app) async {
    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    app.container.invalidate(storageAccessControllerProvider);
    await tester.pumpAndSettle();
  }

  Future<void> openHidden(WidgetTester tester, TestApp app) async {
    final router = app.container.read(routerProvider)..go(AppRoutes.browse);
    unawaited(
      router.push(
        AppRoutes.browseCollection,
        extra: const SourceCollection(BrowseSourceChip.hidden),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CollectionScreen), findsOneWidget);
  }

  testWidgets('a resume keeps the collection page and does not refresh the '
      'router', (tester) async {
    final app = await pumpApp(tester);
    await openHidden(tester, app);
    final redirects = debugRouterRedirectCount;

    await resume(tester, app);
    expect(tester.takeException(), isNull);
    expect(find.byType(CollectionScreen), findsOneWidget);
    expect(debugRouterRedirectCount, redirects, reason: 'no router refresh');
  });

  testWidgets('a router refresh keeps the collection (extra codec)', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await openHidden(tester, app);
    final screen = tester.widget<CollectionScreen>(
      find.byType(CollectionScreen),
    );
    expect(screen.collection, const SourceCollection(BrowseSourceChip.hidden));

    app.container.read(routerProvider).refresh();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester.widget<CollectionScreen>(find.byType(CollectionScreen)).collection,
      const SourceCollection(BrowseSourceChip.hidden),
    );
  });

  testWidgets('a collection route without its extra goes back to Browse', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    app.container.read(routerProvider).go(AppRoutes.browseCollection);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(CollectionScreen), findsNothing);
    expect(find.byType(BrowseScreen), findsOneWidget);
  });

  testWidgets('B8 search keeps its folder through a refresh', (tester) async {
    final app = await pumpApp(tester);
    final router = app.container.read(routerProvider)..go(AppRoutes.browse);
    unawaited(router.push(AppRoutes.search, extra: '/storage/emulated/0/DCIM'));
    await tester.pumpAndSettle();
    app.container.read(routerProvider).refresh();
    await tester.pumpAndSettle();
    expect(
      tester.widget<SearchScreen>(find.byType(SearchScreen)).folder,
      '/storage/emulated/0/DCIM',
    );
  });

  testWidgets('access revoked while away still redirects to the gate', (
    tester,
  ) async {
    final permissions = FakePermissionService();
    final app = await pumpApp(tester, permissions: permissions);
    await openHidden(tester, app);

    permissions.current = grantedAccess.copyWith(media: MediaAccess.denied);
    await resume(tester, app);
    expect(find.byType(PermissionGateScreen), findsOneWidget);
    // Let the left pages' timers (debounces) run out.
    await tester.pump(const Duration(seconds: 5));
  });
}
