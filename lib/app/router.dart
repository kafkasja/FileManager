import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/app_scaffold.dart';
import 'package:kfm/core/platform/permissions/storage_access.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/features/browse/domain/browse_source_chip.dart';
import 'package:kfm/features/browse/ui/browse_screen.dart';
import 'package:kfm/features/browse/ui/collection_screen.dart';
import 'package:kfm/features/onboarding/ui/permission_gate_screen.dart';
import 'package:kfm/features/presets/ui/manage_presets_screen.dart';
import 'package:kfm/features/presets/ui/preset_editor_screen.dart';
import 'package:kfm/features/rename/ui/rename_batch_screen.dart';
import 'package:kfm/features/search/ui/search_screen.dart';
import 'package:kfm/features/selection/ui/selected_files_screen.dart';
import 'package:kfm/features/settings/ui/settings_screen.dart';
import 'package:kfm/features/stats/ui/stats_screen.dart';
import 'package:kfm/features/swipe/ui/customize_swipes_screen.dart';
import 'package:kfm/features/swipe/ui/swipe_screen.dart';
import 'package:kfm/features/tags/ui/collections_screen.dart';
import 'package:kfm/features/tags/ui/tag_files_screen.dart';
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

  /// A carousel card's page; `extra` is the `BrowseCollection`.
  static const browseCollection = '/browse/collection';

  /// B6 "View selected".
  static const browseSelected = '/browse/selected';

  /// B8 search; `extra` is the folder it was opened from (or null).
  static const search = '/browse/search';

  /// B9 Tags & favorites.
  static const collections = '/browse/collections';
  static const collectionFavorites = '/browse/collections/favorites';
  static String collectionTagFor(int id) => '/browse/collections/tag/$id';
  static const trash = '/trash';
  static const settings = '/settings';
  static const customizeSwipes = '/settings/swipes';
  static const renameBatch = '/swipe/rename';
  static const presets = '/settings/presets';
  static const stats = '/settings/stats';
  static String presetEditorFor(int id) => '/settings/presets/$id';
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
                routes: [
                  GoRoute(
                    path: 'rename',
                    builder: (context, state) => const RenameBatchScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.browse,
                builder: (context, state) => const BrowseScreen(),
                routes: [
                  GoRoute(
                    path: 'collection',
                    // `extra` is lost after process death: back to Browse.
                    redirect: (context, state) =>
                        state.extra is BrowseCollection
                        ? null
                        : AppRoutes.browse,
                    builder: (context, state) => CollectionScreen(
                      collection: state.extra! as BrowseCollection,
                    ),
                  ),
                  GoRoute(
                    path: 'selected',
                    builder: (context, state) => const SelectedFilesScreen(),
                  ),
                  GoRoute(
                    path: 'collections',
                    builder: (context, state) => const CollectionsScreen(),
                    routes: [
                      GoRoute(
                        path: 'favorites',
                        builder: (context, state) => const CollectionScreen(
                          collection: FavoritesCollection(),
                        ),
                      ),
                      GoRoute(
                        path: 'tag/:id',
                        redirect: (context, state) =>
                            int.tryParse(state.pathParameters['id'] ?? '') ==
                                null
                            ? AppRoutes.collections
                            : null,
                        builder: (context, state) => TagFilesScreen(
                          tagId: int.parse(state.pathParameters['id']!),
                        ),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'search',
                    builder: (context, state) => SearchScreen(
                      folder: switch (state.extra) {
                        final String folder => folder,
                        _ => null,
                      },
                    ),
                  ),
                ],
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
                routes: [
                  GoRoute(
                    path: 'swipes',
                    builder: (context, state) => const CustomizeSwipesScreen(),
                  ),
                  GoRoute(
                    path: 'stats',
                    builder: (context, state) => const StatsScreen(),
                  ),
                  GoRoute(
                    path: 'presets',
                    builder: (context, state) => const ManagePresetsScreen(),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (context, state) => PresetEditorScreen(
                          presetId:
                              int.tryParse(state.pathParameters['id'] ?? '') ??
                              0,
                        ),
                      ),
                    ],
                  ),
                ],
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
