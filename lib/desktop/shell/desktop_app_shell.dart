import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/app/widgets/db_error_banner.dart';
import 'package:kfm/app/widgets/db_startup_banner.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/platform/host_platform.dart';
import 'package:kfm/core/platform/windows/desktop_shell_provider.dart';
import 'package:kfm/core/platform/windows/drag_drop_channel.dart';
import 'package:kfm/core/platform/windows/startup_hints.dart';
import 'package:kfm/desktop/shell/desktop_drops.dart';
import 'package:kfm/desktop/shell/desktop_shell_state.dart';
import 'package:kfm/desktop/shell/desktop_sidebar.dart';
import 'package:kfm/desktop/shell/desktop_status_bar.dart';
import 'package:kfm/desktop/shell/window_memory.dart';
import 'package:kfm/desktop/widgets/desktop_drag.dart';
import 'package:kfm/desktop/widgets/desktop_keys.dart';
import 'package:kfm/desktop/widgets/desktop_metrics.dart';
import 'package:kfm/features/connect/ui/incoming_offer_prompter.dart';
import 'package:kfm/features/connect/ui/windows_close_host.dart';
import 'package:kfm/features/details/ui/file_details_sheet.dart';
import 'package:kfm/features/external_storage/ui/external_notices.dart';
import 'package:kfm/features/onboarding/ui/limited_access_banner.dart';
import 'package:kfm/features/search/ui/search_controller.dart';
import 'package:kfm/features/share_in/ui/share_in_prompter.dart';
import 'package:kfm/features/trash/ui/no_trash_prompter.dart';
import 'package:kfm/features/updates/ui/update_banner.dart';
import 'package:path_provider/path_provider.dart';

/// The desktop app's frame (TASK-PL3): left sidebar, a top bar with the
/// search box, the section's screen, an optional details pane on the right
/// and a status bar. Wraps the same shell branches as the phone's
/// `AppScaffold` (plus Devices), so every route keeps working.
class DesktopAppShell extends ConsumerStatefulWidget {
  const new({required this.shell, super.key});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<DesktopAppShell> createState() => _DesktopAppShellState();
}

class _DesktopAppShellState extends ConsumerState<DesktopAppShell>
    implements ExplorerDropListener {
  final _search = TextEditingController();
  final _searchFocus = FocusNode(debugLabel: 'desktopSearch');
  late final DesktopDragController _drag;
  WindowsDragDrop? _native;
  WindowMemory? _memory;

  /// Speed fix: bounds + background colour for the runner's next start.
  StartupHintsFile? _hints;

  DesktopSection get _section =>
      DesktopSection.ofBranch(widget.shell.currentIndex);

  @override
  void initState() {
    super.initState();
    _drag = ref.read(desktopDragControllerProvider)..windowSize = _windowSize;
    if (isWindowsHost) {
      final native = _native = WindowsDragDrop();
      // A KFM drag that leaves the window becomes an Explorer drag of the
      // files' paths (copy).
      _drag.onLeaveWindow = (data) => native.startDrag(data.allPaths);
      native.listen(this);
    }
    // PL3 polish: the window opens where the user left it.
    if (ref.read(desktopShellProvider) case final shell?) {
      final hints = _hints = isWindowsHost
          ? StartupHintsFile(
              () async => (await getApplicationSupportDirectory()).path,
            )
          : null;
      _memory = WindowMemory(
        shell,
        ref.read(settingsRepositoryProvider),
        hints: hints,
      )..start().ignore();
    }
  }

  Size? _windowSize() {
    if (!mounted) return null;
    final view = View.of(context);
    return view.physicalSize / view.devicePixelRatio;
  }

  @override
  void dispose() {
    _native?.listen(null);
    _memory?.dispose();
    _drag
      ..cancel()
      ..onLeaveWindow = null
      ..windowSize = null;
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // --- files dragged in from Explorer (Windows' drop target) ---------------

  @override
  bool onDragEnter(Offset position, List<String> paths) {
    _drag.begin(
      DesktopDragData(origin: DragOrigin.explorer, paths: paths),
      position,
    );
    return _drag.offer != null;
  }

  @override
  bool onDragOver(Offset position) {
    _drag.update(position);
    return _drag.offer != null;
  }

  @override
  void onDragLeave() => _drag.cancel();

  @override
  Future<void> onDrop(Offset position, List<String> paths) async {
    if (!_drag.active) {
      _drag.begin(
        DesktopDragData(origin: DragOrigin.explorer, paths: paths),
        position,
      );
    } else {
      _drag.update(position);
    }
    await _drag.drop();
  }

  void _go(DesktopSection section) => widget.shell.goBranch(
    section.branch,
    initialLocation: section.branch == widget.shell.currentIndex,
  );

  /// B8 search: the phone's search screen (inside the Browse branch) with
  /// the typed text.
  void _submitSearch(String text) {
    GoRouter.of(context).go(AppRoutes.search);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(searchScreenControllerProvider(null).notifier).edit(text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final section = _section;
    final details = ref.watch(desktopDetailsPaneProvider);
    final focused = ref.watch(desktopFocusedFileProvider(section));
    final colors = base.colorScheme;
    final l10n = context.l10n;
    // The colour the runner paints before the next start's first frame.
    if (_hints case final hints?) {
      hints.update(background: colors.surface).ignore();
    }
    final onMedia =
        section == DesktopSection.sort || section == DesktopSection.browse;
    final content = Column(
      children: [
        const DbErrorBanner(),
        const DbStartupBanner(),
        const ExternalNotices(),
        const IncomingOfferPrompter(),
        const ShareInPrompter(),
        const NoTrashPrompter(),
        if (isWindowsHost) const WindowsCloseHost(),
        if (section != DesktopSection.sort) const UpdateBanner(),
        if (onMedia) const LimitedAccessBanner(),
        _TopBar(
          title: desktopSectionLabel(l10n, section),
          search: _search,
          searchFocus: _searchFocus,
          onSearch: _submitSearch,
          detailsShown: details,
        ),
        const Divider(height: 1),
        Expanded(
          child: Row(
            children: [
              Expanded(child: widget.shell),
              if (details) ...[
                const VerticalDivider(width: 1),
                SizedBox(
                  width: 340,
                  child: focused == null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsetsDirectional.all(24),
                            child: Text(
                              l10n.desktopDetailsNothing,
                              textAlign: TextAlign.center,
                              style: base.textTheme.bodyMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                      : FileDetailsView(
                          key: ValueKey(focused.id),
                          file: focused,
                        ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
    return Theme(
      // Desktop density: compact controls, same L1 colours.
      data: base.copyWith(visualDensity: VisualDensity.compact),
      child: CallbackShortcuts(
        bindings: {
          DesktopKeys.details: () =>
              ref.read(desktopDetailsPaneProvider.notifier).toggle(),
          DesktopKeys.find: _searchFocus.requestFocus,
        },
        child: FocusScope(
          autofocus: true,
          child: Scaffold(
            backgroundColor: colors.surface,
            body: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          DesktopSidebar(current: section, onSelect: _go),
                          const VerticalDivider(width: 1),
                          Expanded(child: content),
                        ],
                      ),
                    ),
                    DesktopStatusBar(section: section),
                  ],
                ),
                Positioned.fill(child: DesktopDragOverlay(controller: _drag)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const new({
    required this.title,
    required this.search,
    required this.searchFocus,
    required this.onSearch,
    required this.detailsShown,
  });

  final String title;
  final TextEditingController search;
  final FocusNode searchFocus;
  final ValueChanged<String> onSearch;
  final bool detailsShown;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return SizedBox(
      height: scaledExtent(context, 52),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: 300,
              height: scaledExtent(context, 36),
              child: TextField(
                key: const ValueKey('desktop-search'),
                controller: search,
                focusNode: searchFocus,
                textInputAction: TextInputAction.search,
                onSubmitted: (text) {
                  if (text.trim().isNotEmpty) onSearch(text.trim());
                },
                decoration: InputDecoration(
                  isDense: true,
                  hintText: shortcutHint(
                    l10n,
                    l10n.searchHint,
                    DesktopKeys.label(DesktopKeys.find),
                  ),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              key: const ValueKey('desktop-details-toggle'),
              isSelected: detailsShown,
              tooltip: shortcutHint(
                l10n,
                l10n.fileMenuDetails,
                DesktopKeys.label(DesktopKeys.details),
              ),
              icon: const Icon(Icons.vertical_split_outlined),
              selectedIcon: const Icon(Icons.vertical_split),
              onPressed: () =>
                  ref.read(desktopDetailsPaneProvider.notifier).toggle(),
            ),
          ],
        ),
      ),
    );
  }
}
