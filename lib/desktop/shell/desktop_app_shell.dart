import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/app/widgets/db_error_banner.dart';
import 'package:kfm/core/platform/host_platform.dart';
import 'package:kfm/desktop/shell/desktop_shell_state.dart';
import 'package:kfm/desktop/shell/desktop_sidebar.dart';
import 'package:kfm/desktop/shell/desktop_status_bar.dart';
import 'package:kfm/desktop/widgets/desktop_keys.dart';
import 'package:kfm/features/connect/ui/incoming_offer_prompter.dart';
import 'package:kfm/features/connect/ui/windows_close_host.dart';
import 'package:kfm/features/details/ui/file_details_sheet.dart';
import 'package:kfm/features/external_storage/ui/external_notices.dart';
import 'package:kfm/features/onboarding/ui/limited_access_banner.dart';
import 'package:kfm/features/search/ui/search_controller.dart';
import 'package:kfm/features/share_in/ui/share_in_prompter.dart';
import 'package:kfm/features/trash/ui/no_trash_prompter.dart';
import 'package:kfm/features/updates/ui/update_banner.dart';

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

class _DesktopAppShellState extends ConsumerState<DesktopAppShell> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode(debugLabel: 'desktopSearch');

  DesktopSection get _section =>
      DesktopSection.ofBranch(widget.shell.currentIndex);

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
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
    final onMedia =
        section == DesktopSection.sort || section == DesktopSection.browse;
    final content = Column(
      children: [
        const DbErrorBanner(),
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
            body: Column(
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
      height: 52,
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
              height: 36,
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
