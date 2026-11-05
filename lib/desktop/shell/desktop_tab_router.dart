import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/desktop/shell/desktop_location.dart';
import 'package:kfm/desktop/shell/desktop_shell_state.dart';
import 'package:kfm/desktop/tabs/desktop_tabs_controller.dart';

/// The route a typed location lives at (Browse locations: `/browse`).
String desktopRouteOf(DesktopLocation loc) => switch (loc) {
  RouteLocation(:final uri) => uri,
  SortLocation() => AppRoutes.swipe,
  TrashLocation() => AppRoutes.trash,
  DevicesLocation() => AppRoutes.devices,
  SettingsLocation() => AppRoutes.settings,
  HomeLocation() || FolderLocation() || SearchLocation() => AppRoutes.browse,
};

/// The location a router change (from shared code: `context.go(…)`) means;
/// null when the active tab already shows it.
DesktopLocation? desktopLocationForRoute(String uri, DesktopLocation current) {
  if (desktopRouteOf(current) == uri) return null;
  return switch (uri) {
    AppRoutes.swipe => const SortLocation(),
    AppRoutes.trash => const TrashLocation(),
    AppRoutes.devices => const DevicesLocation(),
    AppRoutes.settings => const SettingsLocation(),
    // `/browse` from shared code: stay in a Browse location, else Home.
    AppRoutes.browse =>
      current.section == DesktopSection.browse && current is! RouteLocation
          ? null
          : const HomeLocation(),
    AppRoutes.start || AppRoutes.permission => null,
    _ => RouteLocation(uri),
  };
}

/// Keeps the active tab and go_router in step (TASK-E3): the tab decides
/// the shell branch and route; a `context.go(…)` from shared code (details
/// sheet, collections, Connect…) changes the active tab instead.
class DesktopTabRouter extends ConsumerStatefulWidget {
  const new({required this.shell, required this.child, super.key});

  final StatefulNavigationShell shell;
  final Widget child;

  @override
  ConsumerState<DesktopTabRouter> createState() => _DesktopTabRouterState();
}

class _DesktopTabRouterState extends ConsumerState<DesktopTabRouter> {
  GoRouter? _router;
  var _applying = false;

  @override
  void initState() {
    super.initState();
    ref.listenManual(desktopTabsControllerProvider, (prev, next) {
      if (prev?.current.location != next.current.location ||
          prev?.current.id != next.current.id) {
        _apply(next.current.location);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.of(context);
    if (router != _router) {
      _router?.routerDelegate.removeListener(_onRoute);
      _router = router..routerDelegate.addListener(_onRoute);
      // The first frame: the router opened at its start route; the
      // (restored) tab wins once it's known.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _apply(ref.read(desktopTabsControllerProvider).current.location);
      });
    }
  }

  @override
  void dispose() {
    _router?.routerDelegate.removeListener(_onRoute);
    super.dispose();
  }

  String get _uri =>
      _router!.routerDelegate.currentConfiguration.uri.toString();

  void _apply(DesktopLocation loc) {
    final router = _router;
    if (router == null || !mounted) return;
    final target = desktopRouteOf(loc);
    if (_uri == target) return;
    _applying = true;
    try {
      router.go(target);
    } finally {
      _applying = false;
    }
  }

  void _onRoute() {
    if (_applying || !mounted) return;
    final uri = _uri;
    final tabs = ref.read(desktopTabsControllerProvider.notifier);
    final current = ref.read(desktopTabsControllerProvider).current.location;
    final next = desktopLocationForRoute(uri, current);
    if (next == null) return;
    // Not during the router's own notification (it may be in a build).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final now = ref.read(desktopTabsControllerProvider).current.location;
      if (desktopLocationForRoute(_uri, now) case final loc?) {
        tabs.navigate(loc);
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
