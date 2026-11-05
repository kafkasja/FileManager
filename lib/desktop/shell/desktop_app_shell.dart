import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/widgets/db_error_banner.dart';
import 'package:kfm/app/widgets/db_startup_banner.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/platform/host_platform.dart';
import 'package:kfm/core/platform/windows/desktop_shell_provider.dart';
import 'package:kfm/core/platform/windows/drag_drop_channel.dart';
import 'package:kfm/core/platform/windows/startup_hints.dart';
import 'package:kfm/desktop/settings/desktop_icon_choice_dialog.dart';
import 'package:kfm/desktop/shell/desktop_address_bar.dart';
import 'package:kfm/desktop/shell/desktop_command_bar.dart';
import 'package:kfm/desktop/shell/desktop_drops.dart';
import 'package:kfm/desktop/shell/desktop_layout.dart';
import 'package:kfm/desktop/shell/desktop_location.dart';
import 'package:kfm/desktop/shell/desktop_nav_pane.dart';
import 'package:kfm/desktop/shell/desktop_shell_state.dart';
import 'package:kfm/desktop/shell/desktop_status_bar.dart';
import 'package:kfm/desktop/shell/desktop_tab_router.dart';
import 'package:kfm/desktop/shell/window_memory.dart';
import 'package:kfm/desktop/tabs/desktop_tab_strip.dart';
import 'package:kfm/desktop/tabs/desktop_tabs_controller.dart';
import 'package:kfm/desktop/widgets/desktop_drag.dart';
import 'package:kfm/desktop/widgets/desktop_keys.dart';
import 'package:kfm/features/connect/ui/incoming_offer_prompter.dart';
import 'package:kfm/features/connect/ui/windows_close_host.dart';
import 'package:kfm/features/details/ui/file_details_sheet.dart';
import 'package:kfm/features/external_storage/ui/external_notices.dart';
import 'package:kfm/features/share_in/ui/share_in_prompter.dart';
import 'package:kfm/features/trash/ui/no_trash_prompter.dart';
import 'package:kfm/features/updates/ui/update_banner.dart';
import 'package:path_provider/path_provider.dart';

/// The desktop app's frame (TASK-PL3, E3 File Explorer layout): tabs,
/// address bar with search, command bar, navigation pane, the section's
/// screen, an optional details pane on the right and a status bar. Wraps the same shell branches as the phone's
/// `AppScaffold` (plus Devices), so every route keeps working.
class DesktopAppShell extends ConsumerStatefulWidget {
  const new({required this.shell, super.key});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<DesktopAppShell> createState() => _DesktopAppShellState();
}

class _DesktopAppShellState extends ConsumerState<DesktopAppShell>
    implements ExplorerDropListener {
  final _searchFocus = FocusNode(debugLabel: 'desktopSearch');
  final _addressFocus = FocusNode(debugLabel: 'desktopAddress');
  final _address = GlobalKey<DesktopAddressBarState>();
  late final DesktopDragController _drag;
  late final DesktopTabsController _tabsCtl;
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
    _tabsCtl = ref.read(desktopTabsControllerProvider.notifier);
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
    // E3: a pending tab change is written before the window goes.
    _tabsCtl.flush();
    _memory?.dispose();
    _drag
      ..cancel()
      ..onLeaveWindow = null
      ..windowSize = null;
    _searchFocus.dispose();
    _addressFocus.dispose();
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

  void _tabsDo(void Function(DesktopTabsController t) f) =>
      f(ref.read(desktopTabsControllerProvider.notifier));

  /// Text fields keep their keys (Backspace, Alt+←… edit the text).
  bool get _typing {
    final ctx = primaryFocus?.context;
    return ctx != null && ctx.widget is EditableText;
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final section = _section;
    final details = ref.watch(desktopDetailsPaneProvider);
    final navShown = ref.watch(desktopNavPaneShownProvider);
    final focused = ref.watch(desktopFocusedFileProvider(section));
    final colors = base.colorScheme;
    final l10n = context.l10n;
    // The colour the runner paints before the next start's first frame.
    if (_hints case final hints?) {
      hints.update(background: colors.surface).ignore();
    }
    final content = Column(
      children: [
        const DbErrorBanner(),
        const DbStartupBanner(),
        const ExternalNotices(),
        const IncomingOfferPrompter(),
        const ShareInPrompter(),
        const NoTrashPrompter(),
        const DesktopIconChoicePrompter(),
        if (isWindowsHost) const WindowsCloseHost(),
        if (section != DesktopSection.sort) const UpdateBanner(),
        Expanded(
          child: Builder(
            builder: (context) => Row(
              children: [
                Expanded(child: widget.shell),
                if (details) ...[
                  const VerticalDivider(width: 1),
                  SizedBox(
                    // At most a third of a narrow window (800 px minimum), so
                    // the lists keep their room.
                    width: DesktopLayout.detailsWidth(
                      MediaQuery.sizeOf(context).width -
                          (navShown ? ref.watch(desktopNavWidthProvider) : 0) -
                          1,
                    ),
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
        ),
      ],
    );
    void guarded(VoidCallback f) {
      if (!_typing) f();
    }

    return Theme(
      // Desktop density: compact controls, same L1 colours.
      data: base.copyWith(visualDensity: VisualDensity.compact),
      child: DesktopTabRouter(
        shell: widget.shell,
        child: CallbackShortcuts(
          bindings: {
            DesktopKeys.detailsPane: () =>
                ref.read(desktopDetailsPaneProvider.notifier).toggle(),
            DesktopKeys.find: _searchFocus.requestFocus,
            DesktopKeys.searchE: _searchFocus.requestFocus,
            DesktopKeys.searchF3: _searchFocus.requestFocus,
            DesktopKeys.addressBar: _editAddress,
            DesktopKeys.addressBarL: _editAddress,
            DesktopKeys.addressBarF4: _editAddress,
            DesktopKeys.refresh: () => refreshDesktop(ref),
            DesktopKeys.newTab: () =>
                _tabsDo((t) => t.openInNewTab(const HomeLocation())),
            DesktopKeys.closeTab: _closeActiveTab,
            DesktopKeys.closeTabF4: _closeActiveTab,
            DesktopKeys.nextTab: () => _tabsDo((t) => t.cycle()),
            DesktopKeys.previousTab: () =>
                _tabsDo((t) => t.cycle(backwards: true)),
            DesktopKeys.reopenTab: () => _tabsDo((t) => t.reopenClosed()),
            DesktopKeys.back: () => guarded(() => _tabsDo((t) => t.back())),
            DesktopKeys.forward: () =>
                guarded(() => _tabsDo((t) => t.forward())),
            DesktopKeys.up: () => guarded(() => _tabsDo((t) => t.up())),
          },
          // Arrow keys while nothing inside is focused (the shell's own scope
          // has primary focus, e.g. after switching sections) would search
          // every focusable in the window, including pages under the current
          // one that aren't laid out (assert 'hasSize' in debug, a null
          // size in release). Nothing is focused, so there's nowhere to move.
          child: Actions(
            actions: {DirectionalFocusIntent: _ShellDirectionalFocusAction()},
            child: FocusScope(
              autofocus: true,
              child: Scaffold(
                backgroundColor: colors.surface,
                body: Stack(
                  children: [
                    Column(
                      children: [
                        const DesktopTabStrip(),
                        DesktopAddressBar(
                          key: _address,
                          searchFocus: _searchFocus,
                          addressFocus: _addressFocus,
                        ),
                        DesktopCommandBar(section: section),
                        const Divider(height: 1),
                        Expanded(
                          child: Row(
                            children: [
                              if (navShown) ...[
                                const DesktopNavPane(),
                                const DesktopNavSplitter(),
                              ],
                              Expanded(child: content),
                            ],
                          ),
                        ),
                        DesktopStatusBar(section: section),
                      ],
                    ),
                    Positioned.fill(
                      child: DesktopDragOverlay(controller: _drag),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _editAddress() => _address.currentState?.edit();

  void _closeActiveTab() {
    final tabs = ref.read(desktopTabsControllerProvider);
    _tabsDo((t) => t.close(tabs.current.id));
  }
}

/// Moves focus like the default action, except when the focused node is a
/// scope with nothing focused inside (see the shell's build).
class _ShellDirectionalFocusAction extends DirectionalFocusAction {
  @override
  void invoke(DirectionalFocusIntent intent) {
    final primary = primaryFocus;
    if (primary is FocusScopeNode && primary.focusedChild == null) return;
    super.invoke(intent);
  }
}
