import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/core/platform/permissions/storage_access.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/features/onboarding/ui/permission_gate_screen.dart';
import 'package:kfm/features/swipe/ui/swipe_screen.dart';

import '../core/platform/permissions/fake_permission_service.dart';
import '../helpers/pump_app.dart';

AsyncValue<StorageAccess> _with(MediaAccess media) =>
    AsyncData(grantedAccess.copyWith(media: media));

void main() {
  group('redirectFor', () {
    test('waits on the start screen while loading', () {
      const loading = AsyncLoading<StorageAccess>();
      expect(redirectFor(loading, AppRoutes.start), isNull);
      expect(redirectFor(loading, AppRoutes.swipe), AppRoutes.start);
    });

    test('goes to the gate without media access, and stays there', () {
      for (final media in [
        MediaAccess.unknown,
        MediaAccess.denied,
        MediaAccess.permanentlyDenied,
      ]) {
        expect(
          redirectFor(_with(media), AppRoutes.swipe),
          AppRoutes.permission,
        );
        expect(redirectFor(_with(media), AppRoutes.permission), isNull);
      }
    });

    test('leaves the gate and start screen once access is granted', () {
      for (final media in [MediaAccess.granted, MediaAccess.limited]) {
        expect(
          redirectFor(_with(media), AppRoutes.permission),
          AppRoutes.swipe,
        );
        expect(redirectFor(_with(media), AppRoutes.start), AppRoutes.swipe);
        expect(redirectFor(_with(media), AppRoutes.browse), isNull);
      }
    });

    test('a failed check shows the gate (with retry), never loops', () {
      final error = AsyncError<StorageAccess>(
        StateError('x'),
        StackTrace.empty,
      );
      expect(redirectFor(error, AppRoutes.swipe), AppRoutes.permission);
      expect(redirectFor(error, AppRoutes.permission), isNull);
    });
  });

  testWidgets('first launch: gate → Allow → Swipe', (tester) async {
    final permissions = FakePermissionService(
      grantedAccess.copyWith(media: MediaAccess.unknown),
    );
    await pumpApp(tester, permissions: permissions);
    expect(find.byType(PermissionGateScreen), findsOneWidget);
    expect(find.text('Let KFM see your photos and videos'), findsOneWidget);

    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();
    expect(find.byType(SwipeScreen), findsOneWidget);
    expect(permissions.calls, contains('requestMedia'));
  });

  testWidgets('permanently denied shows Open settings', (tester) async {
    final permissions = FakePermissionService(
      grantedAccess.copyWith(media: MediaAccess.permanentlyDenied),
    );
    await pumpApp(tester, permissions: permissions);
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    expect(permissions.calls, contains('openAppSettings'));
    expect(find.byType(PermissionGateScreen), findsOneWidget);
  });

  testWidgets('revoked while running → gate; re-granted → Swipe', (
    tester,
  ) async {
    final permissions = FakePermissionService();
    final app = await pumpApp(tester, permissions: permissions);
    expect(find.byType(SwipeScreen), findsOneWidget);

    permissions.current = grantedAccess.copyWith(media: MediaAccess.denied);
    await app.container
        .read(storageAccessControllerProvider.notifier)
        .recheck();
    await tester.pumpAndSettle();
    expect(find.byType(PermissionGateScreen), findsOneWidget);

    permissions.current = grantedAccess;
    await app.container
        .read(storageAccessControllerProvider.notifier)
        .recheck();
    await tester.pumpAndSettle();
    expect(find.byType(SwipeScreen), findsOneWidget);
  });

  testWidgets('a failing permission check shows retry on the gate', (
    tester,
  ) async {
    final permissions = FakePermissionService()..checkError = StateError('x');
    await pumpApp(tester, permissions: permissions);
    expect(find.text("Couldn't check the permissions."), findsOneWidget);

    permissions.checkError = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.byType(SwipeScreen), findsOneWidget);
  });

  testWidgets('switching tabs keeps the other tabs mounted', (tester) async {
    await pumpApp(tester);
    final swipeState = tester.element(find.byType(SwipeScreen));
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    expect(find.byType(SwipeScreen, skipOffstage: false), findsOneWidget);
    await tester.tap(find.text('Swipe'));
    await tester.pumpAndSettle();
    expect(tester.element(find.byType(SwipeScreen)), same(swipeState));
    expect(find.byType(Scaffold), findsWidgets);
  });
}
