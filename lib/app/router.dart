import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/app_scaffold.dart';
import 'package:kfm/core/platform/permissions/storage_access.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/features/browse/ui/browse_placeholder.dart';
import 'package:kfm/features/onboarding/ui/permission_gate_screen.dart';
import 'package:kfm/features/settings/ui/settings_screen.dart';
import 'package:kfm/features/swipe/ui/swipe_screen.dart';
import 'package:kfm/features/trash/ui/trash_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

enum AppTab { swipe, browse, trash, settings }

abstract final class AppRoutes {
  /// Blank start screen while the first permission check runs.
  static const start = '/';
  static const permission = '/permission';
  static const swipe = '/swipe';
  static const browse = '/browse';
  static const trash = '/trash';
  static const settings = '/settings';
}

/// Where to go for [location] given the current [access]; null = stay.
@visibleForTesting
String? redirectFor(AsyncValue<StorageAccess> access, String location) {
  if (!access.hasValue) {
    if (access.hasError) {
      // The gate shows the error and a retry button; never loop.
      return location == AppRoutes.permission ? null : AppRoutes.permission;
    }
    return location == AppRoutes.start ? null : AppRoutes.start;
  }
  final ok = access.value!.canUseSwipe;
  if (!ok) {
    return location == AppRoutes.permission ? null : AppRoutes.permission;
  }
  if (location == AppRoutes.permission || location == AppRoutes.start) {
    return AppRoutes.swipe;
  }
  return null;
}

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final access = ValueNotifier<AsyncValue<StorageAccess>>(const AsyncLoading());
  ref
    ..listen(
      storageAccessControllerProvider,
      (_, next) => access.value = next,
      fireImmediately: true,
    )
    ..onDispose(access.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.start,
    refreshListenable: access,
    redirect: (context, state) =>
        redirectFor(access.value, state.matchedLocation),
    routes: [
      GoRoute(
        path: AppRoutes.start,
        builder: (context, state) => const Scaffold(),
      ),
      GoRoute(
        path: AppRoutes.permission,
        builder: (context, state) => const PermissionGateScreen(),
      ),
      // indexedStack keeps every tab alive: switching tabs never loses
      // swipe progress.
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppScaffold(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.swipe,
                builder: (context, state) => const SwipeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.browse,
                builder: (context, state) => const BrowsePlaceholder(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.trash,
                builder: (context, state) => const TrashScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}
