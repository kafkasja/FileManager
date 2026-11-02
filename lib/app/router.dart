import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/app_scaffold.dart';
import 'package:kfm/app/router_extra_codec.dart';
import 'package:kfm/core/platform/permissions/storage_access.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/features/ai_labels/ui/ai_models_details_screen.dart';
import 'package:kfm/features/browse/domain/browse_source_chip.dart';
import 'package:kfm/features/browse/ui/browse_screen.dart';
import 'package:kfm/features/browse/ui/collection_screen.dart';
import 'package:kfm/features/connect/ui/connect_screen.dart';
import 'package:kfm/features/connect/ui/remembered_devices_screen.dart';
import 'package:kfm/features/connect/ui/remote_browse_screen.dart';
import 'package:kfm/features/connect/ui/remote_swipe_screen.dart';
import 'package:kfm/features/connect/ui/share_screen.dart';
import 'package:kfm/features/external_storage/ui/place_browser_screen.dart';
import 'package:kfm/features/onboarding/ui/permission_gate_screen.dart';
import 'package:kfm/features/presets/ui/manage_presets_screen.dart';
import 'package:kfm/features/presets/ui/preset_editor_screen.dart';
import 'package:kfm/features/rename/ui/rename_batch_screen.dart';
import 'package:kfm/features/search/ui/search_screen.dart';
import 'package:kfm/features/selection/ui/selected_files_screen.dart';
import 'package:kfm/features/settings/ui/settings_screen.dart';
import 'package:kfm/features/share_in/ui/shared_files_screen.dart';
import 'package:kfm/features/similar/ui/clean_duplicates_screen.dart';
import 'package:kfm/features/similar/ui/similar_screen.dart';
import 'package:kfm/features/smart_groups/ui/group_detail_screen.dart';
import 'package:kfm/features/smart_groups/ui/groups_screen.dart';
import 'package:kfm/features/smart_groups/ui/smart_group_titles.dart';
import 'package:kfm/features/stats/ui/stats_screen.dart';
import 'package:kfm/features/storage/ui/storage_overview_screen.dart';
import 'package:kfm/features/swipe/ui/customize_swipes_screen.dart';
import 'package:kfm/features/swipe/ui/swipe_screen.dart';
import 'package:kfm/features/tags/ui/collections_screen.dart';
import 'package:kfm/features/tags/ui/tag_files_screen.dart';
import 'package:kfm/features/transfers/ui/send_flow.dart';
import 'package:kfm/features/transfers/ui/transfers_screen.dart';
import 'package:kfm/features/trash/ui/trash_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

enum AppTab { swipe, browse, trash, settings }

/// U2: the place browser at [root] (a volume path or `mtp:<device>`).
String placeBrowserLocation({required String root, required String title}) =>
    Uri(
      path: AppRoutes.browsePlace,
      queryParameters: {'root': root, 'title': title},
    ).toString();

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

  /// U2 place browser (SAF volumes, cameras); see [placeBrowserLocation].
  static const browsePlace = '/browse/place';

  /// B8 search; `extra` is the folder it was opened from (or null).
  static const search = '/browse/search';

  /// C2 Similar photos and its Clean duplicates flow.
  static const similar = '/browse/similar';
  static const similarClean = '/browse/similar/clean';

  /// C1 Storage overview.
  static const storage = '/browse/storage';

  /// C5 Smart groups and one group's grid (`GroupKey.value`).
  static const groups = '/browse/groups';
  static String groupFor(String key) => '/browse/groups/$key';

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

  /// C3: the AI model details screen (shown before any download).
  static const aiModels = '/settings/ai-models';

  /// N1/N2: top-level (cover the tab bar), opened with `context.push`.
  static const connect = '/connect';
  static const connectShare = '/connect/share';

  /// N12 "Receive files": the share screen headed for receiving.
  static const connectReceive = '/connect/share?receive=1';

  /// N12: the Connect screen pairing send-only for a pending send.
  static const connectSend = '/connect?send=1';

  /// N6: remembered devices. From the Connect screen with `?from=connect`
  /// (Reconnect then goes back to it instead of pushing a new one).
  static const connectDevices = '/connect/devices';
  static const connectDevicesFromConnect = '/connect/devices?from=connect';

  /// N7: browse the connected device `:fp` (its pinned fingerprint).
  static const connectBrowse = '/connect/browse/:fp';
  static String connectBrowseFor(String peerFingerprint) =>
      '/connect/browse/$peerFingerprint';

  /// N9: Wi-Fi transfers (Downloads · Uploads).
  static const transfers = '/transfers';

  /// X1: files shared into KFM from another app (pushed over the shell).
  static const shared = '/shared';

  /// N8: swipe the connected device `:fp`'s folder (its session).
  static const connectSwipe = '/connect/swipe/:fp';
  static String connectSwipeFor(String peerFingerprint) =>
      '/connect/swipe/$peerFingerprint';
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

/// What [redirectFor] depends on in [access]: loading, error, or whether
/// Swipe may be used. The router refreshes only when this changes (TASK-H6),
/// so a plain resume (which re-checks access) doesn't rebuild the routes.
@visibleForTesting
Object redirectInput(AsyncValue<StorageAccess> access) => switch (access) {
  AsyncValue(hasValue: true, :final value?) => value.canUseSwipe,
  AsyncValue(hasError: true) => #error,
  _ => #loading,
};

/// How often the top-level redirect ran (tests check that a plain resume
/// doesn't refresh the router).
@visibleForTesting
int debugRouterRedirectCount = 0;

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final access = ValueNotifier<AsyncValue<StorageAccess>>(const AsyncLoading());
  ref
    ..listen(storageAccessControllerProvider, (_, next) {
      if (redirectInput(next) != redirectInput(access.value)) {
        access.value = next;
      }
    }, fireImmediately: true)
    ..onDispose(access.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.start,
    refreshListenable: access,
    // Keeps a collection page's `extra` through refreshes and process death.
    extraCodec: const KfmExtraCodec(),
    redirect: (context, state) {
      debugRouterRedirectCount++;
      return redirectFor(access.value, state.matchedLocation);
    },
    routes: [
      GoRoute(
        path: AppRoutes.start,
        builder: (context, state) => const Scaffold(),
      ),
      GoRoute(
        path: AppRoutes.permission,
        builder: (context, state) => const PermissionGateScreen(),
      ),
      GoRoute(
        path: AppRoutes.transfers,
        builder: (context, state) => const TransfersScreen(),
      ),
      GoRoute(
        path: AppRoutes.shared,
        builder: (context, state) => const SharedFilesScreen(),
      ),
      GoRoute(
        path: AppRoutes.connect,
        builder: (context, state) => state.uri.queryParameters['send'] == '1'
            ? const ConnectSendScreen()
            : const ConnectScreen(),
        routes: [
          GoRoute(
            path: 'share',
            // N12: `?receive=1` = "Receive files" (same screen).
            builder: (context, state) => ShareScreen(
              receive: state.uri.queryParameters['receive'] == '1',
            ),
          ),
          GoRoute(
            path: 'devices',
            builder: (context, state) => RememberedDevicesScreen(
              fromConnect: state.uri.queryParameters['from'] == 'connect',
            ),
          ),
          GoRoute(
            path: 'browse/:fp',
            builder: (context, state) => RemoteBrowseScreen(
              peerFingerprint: state.pathParameters['fp']!,
            ),
          ),
          GoRoute(
            path: 'swipe/:fp',
            builder: (context, state) =>
                RemoteSwipeScreen(peerFingerprint: state.pathParameters['fp']!),
          ),
        ],
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
                    // KfmExtraCodec restores `extra`; an unknown (old) shape
                    // comes back null. No route redirect: go_router ignores
                    // one equal to the base URI, so the builder is the guard.
                    builder: (context, state) => switch (state.extra) {
                      final BrowseCollection c => CollectionScreen(
                        collection: c,
                      ),
                      _ => const _BackToBrowse(),
                    },
                  ),
                  GoRoute(
                    path: 'selected',
                    builder: (context, state) => const SelectedFilesScreen(),
                  ),
                  GoRoute(
                    path: 'similar',
                    builder: (context, state) => const SimilarScreen(),
                    routes: [
                      GoRoute(
                        path: 'clean',
                        builder: (context, state) =>
                            const CleanDuplicatesScreen(),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'place',
                    builder: (context, state) => PlaceBrowserScreen(
                      root: state.uri.queryParameters['root'] ?? '',
                      title: state.uri.queryParameters['title'] ?? '',
                    ),
                  ),
                  GoRoute(
                    path: 'storage',
                    builder: (context, state) => const StorageOverviewScreen(),
                  ),
                  GoRoute(
                    path: 'groups',
                    builder: (context, state) => const GroupsScreen(),
                    routes: [
                      GoRoute(
                        path: ':key',
                        redirect: (context, state) =>
                            GroupKey.parse(state.pathParameters['key'] ?? '') ==
                                null
                            ? AppRoutes.groups
                            : null,
                        builder: (context, state) => switch (GroupKey.parse(
                          state.pathParameters['key'] ?? '',
                        )) {
                          final GroupKey key => GroupDetailScreen(
                            groupKey: key,
                          ),
                          null => const _BackToBrowse(),
                        },
                      ),
                    ],
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
                        builder: (context, state) => switch (int.tryParse(
                          state.pathParameters['id'] ?? '',
                        )) {
                          final int id => TagFilesScreen(tagId: id),
                          null => const _BackToBrowse(),
                        },
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
                    path: 'ai-models',
                    builder: (context, state) => const AiModelsDetailsScreen(),
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

/// A route whose arguments couldn't be restored: an empty page that goes
/// back to Browse right after its first frame (never an error screen).
class _BackToBrowse extends StatefulWidget {
  const new();

  @override
  State<_BackToBrowse> createState() => _BackToBrowseState();
}

class _BackToBrowseState extends State<_BackToBrowse> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go(AppRoutes.browse);
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold();
}
