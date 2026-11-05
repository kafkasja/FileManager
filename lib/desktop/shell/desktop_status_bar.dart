import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/index/media_indexer.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/desktop/shell/desktop_drives.dart';
import 'package:kfm/desktop/shell/desktop_location.dart';
import 'package:kfm/desktop/shell/desktop_shell_state.dart';
import 'package:kfm/desktop/tabs/desktop_tabs_controller.dart';
import 'package:kfm/desktop/widgets/desktop_metrics.dart';
import 'package:kfm/features/background_jobs/ui/jobs_indicator.dart';
import 'package:kfm/features/external_storage/data/places_repository.dart';
import 'package:kfm/features/external_storage/domain/storage_place.dart';
import 'package:kfm/features/external_storage/ui/place_labels.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'desktop_status_bar.g.dart';

/// E1 hook: "Connected to `phone`" in the status bar (a link widget);
/// null until E1c fills it.
@Riverpod(keepAlive: true)
Widget? desktopStatusConnection(Ref ref) => null;

/// The view toggles at the end of the status bar (Details / Large icons),
/// set by the screen that has a view (Browse, Sort, Trash).
@immutable
class DesktopViewToggle {
  const new({required this.details, required this.onChanged});

  /// The Details view is on (else an icon view).
  final bool details;
  final ValueChanged<bool> onChanged;
}

@Riverpod(keepAlive: true)
class DesktopViewToggles extends _$DesktopViewToggles {
  @override
  DesktopViewToggle? build(DesktopSection section) => null;

  void set(DesktopViewToggle? toggle) {
    if (toggle?.details != state?.details ||
        (toggle == null) != (state == null)) {
      state = toggle;
    } else {
      _latest = toggle;
    }
  }

  DesktopViewToggle? _latest;

  void change({required bool details}) =>
      (_latest ?? state)?.onChanged(details);
}

/// The drive [path] is on: the place whose root is the longest prefix.
StoragePlace? driveOf(String? path, List<StoragePlace> drives) {
  if (path == null) return null;
  final lower = path.toLowerCase();
  StoragePlace? best;
  for (final d in drives) {
    final root = d.rootPath?.toLowerCase();
    if (root == null) continue;
    if (lower == root ||
        lower.startsWith('$root/') ||
        root.endsWith('/') && lower.startsWith(root)) {
      if (best == null || root.length > best.rootPath!.length) best = d;
    }
  }
  return best;
}

/// Bottom status bar (TASK-E3): items · selection · "N left" · the last
/// action on the left, the drive of the open folder with its free space in
/// the middle, then E1's connection, background work and the view
/// toggles. Never "-- items".
class DesktopStatusBar extends ConsumerStatefulWidget {
  const new({required this.section, super.key});

  final DesktopSection section;

  @override
  ConsumerState<DesktopStatusBar> createState() => _DesktopStatusBarState();
}

class _DesktopStatusBarState extends ConsumerState<DesktopStatusBar> {
  Timer? _refresh;
  Timer? _messageTimer;
  String? _message;

  @override
  void initState() {
    super.initState();
    ref.listenManual(desktopStatusMessageProvider, (_, next) {
      _messageTimer?.cancel();
      setState(() => _message = next?.$1);
      _messageTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _message = null);
      });
    });
    // Free space changes as files are written: every 30 s while shown.
    _refresh = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) ref.invalidate(placesProvider);
    });
  }

  @override
  void dispose() {
    _refresh?.cancel();
    _messageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final section = widget.section;
    final status = ref.watch(desktopStatusLineProvider(section));
    final locale = Localizations.localeOf(context).toLanguageTag();
    final index = ref.watch(indexStatusProvider).value;
    final loc = ref.watch(desktopTabsControllerProvider).current.location;
    final drives = desktopDrivesOf(ref.watch(placesProvider).value ?? const []);
    final hint =
        status.driveHint ??
        switch (loc) {
          FolderLocation(:final path) => path,
          SearchLocation(:final scope) => scope,
          _ => null,
        };
    final drive =
        driveOf(hint, drives) ??
        drives.where((d) => d.id == kInternalPlaceId).firstOrNull;
    final toggle = ref.watch(desktopViewTogglesProvider(section));
    final connection = ref.watch(desktopStatusConnectionProvider);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final left = <Widget>[
      if (status.items case final items?)
        Text(
          l10n.desktopStatusItems(items),
          key: const ValueKey('desktop-status-items'),
        ),
      if (status.selected > 0)
        Text(
          l10n.desktopStatusSelected(
            status.selected,
            formatBytes(status.selectedBytes, locale: locale),
          ),
          key: const ValueKey('desktop-status-selected'),
        ),
      if (status.left case final n?)
        Text(
          l10n.desktopStatusLeft(n),
          key: const ValueKey('desktop-status-left'),
        ),
      if (status.totalBytes case final b?) Text(formatBytes(b, locale: locale)),
      if (status.message ?? _message case final m?)
        Text(m, key: const ValueKey('desktop-status-message')),
    ];
    return Container(
      height: scaledExtent(context, 28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
      child: DefaultTextStyle.merge(
        style: style,
        child: Row(
          children: [
            for (final (i, w) in left.indexed) ...[if (i > 0) const _Dot(), w],
            const Spacer(),
            if (drive != null) _DriveSpace(drive: drive),
            const Spacer(),
            ?connection,
            if (index case IndexScanning(:final found)) ...[
              const SizedBox(width: 12),
              const SizedBox.square(
                dimension: 12,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
              const SizedBox(width: 6),
              Text(l10n.indexingCount(found)),
            ],
            if (index is IndexFailed)
              InkWell(
                onTap: () => ref.read(mediaIndexerProvider).start().ignore(),
                child: Text(l10n.indexingPaused),
              ),
            // X8: transfers and copies with their progress.
            const SizedBox(width: 12),
            const JobsIndicator(compact: true),
            if (toggle != null) ...[
              const SizedBox(width: 8),
              _ViewButton(
                key: const ValueKey('status-view-details'),
                icon: Icons.view_list_outlined,
                tooltip: l10n.desktopLayoutDetails,
                selected: toggle.details,
                onPressed: () => ref
                    .read(desktopViewTogglesProvider(section).notifier)
                    .change(details: true),
              ),
              _ViewButton(
                key: const ValueKey('status-view-icons'),
                icon: Icons.grid_view_outlined,
                tooltip: l10n.desktopLayoutLargeIcons,
                selected: !toggle.details,
                onPressed: () => ref
                    .read(desktopViewTogglesProvider(section).notifier)
                    .change(details: false),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsetsDirectional.symmetric(horizontal: 8),
    child: Icon(Icons.circle, size: 3),
  );
}

class _ViewButton extends StatelessWidget {
  const new({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    isSelected: selected,
    iconSize: 16,
    visualDensity: VisualDensity.compact,
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints.tightFor(width: 26, height: 24),
    onPressed: onPressed,
    icon: Icon(icon),
  );
}

/// `C: 120 GB free of 476 GB` + a 60 px bar (red under 10 % free); click
/// opens the drive.
class _DriveSpace extends ConsumerWidget {
  const new({required this.drive});

  final StoragePlace drive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final total = drive.totalBytes;
    final free = drive.freeBytes;
    final root = drive.rootPath!;
    final name = drive.id == kInternalPlaceId ? root : placeLabel(l10n, drive);
    final hasSpace = total != null && free != null && total > 0;
    final used = hasSpace ? (1 - free / total).clamp(0.0, 1.0) : 0.0;
    final low = hasSpace && free / total < 0.10;
    return InkWell(
      key: const ValueKey('desktop-status-drive'),
      onTap: () => ref
          .read(desktopTabsControllerProvider.notifier)
          .navigate(FolderLocation(root)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            hasSpace
                ? l10n.desktopStatusDriveFree(
                    name,
                    formatBytes(free, locale: locale),
                    formatBytes(total, locale: locale),
                  )
                : name,
          ),
          if (hasSpace) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 60,
              height: 6,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  key: ValueKey(low ? 'drive-bar-low' : 'drive-bar'),
                  value: used,
                  color: low ? colors.error : colors.primary,
                  backgroundColor: colors.surfaceContainerHighest,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
