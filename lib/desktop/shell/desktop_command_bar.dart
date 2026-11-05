import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/desktop/shell/desktop_shell_state.dart';
import 'package:kfm/desktop/widgets/desktop_drag.dart';
import 'package:kfm/desktop/widgets/desktop_metrics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'desktop_command_bar.g.dart';

/// One button of the command bar (TASK-E3): icon + label (label hidden on
/// a narrow window, then the tooltip says it with its shortcut), or a menu
/// button when [menu] is set.
@immutable
class DesktopCommand {
  const new({
    required this.id,
    required this.label,
    required this.icon,
    this.onPressed,
    this.shortcut,
    this.menu,
    this.selected,
    this.divider = false,
    this.keepLabel = false,
    this.dropOffer,
    this.color,
    this.badge = false,
    this.key,
  });

  /// Files dragged onto the button (Sort's actions take a Sort drag).
  final DropOfferBuilder? dropOffer;

  /// The icon's colour (Sort: trash red, keep green…).
  final Color? color;

  /// A small dot on the icon (a filter is on, the preset was changed).
  final bool badge;

  /// The widget key; default `cmd-<id>`.
  final Key? key;

  final String id;
  final String label;
  final IconData icon;

  /// Null = disabled.
  final VoidCallback? onPressed;

  /// "Ctrl+X" (tooltip).
  final String? shortcut;

  /// A drop-down (New ▾, View ▾…).
  final List<DesktopCommand>? menu;

  /// A toggle's state (View ▾ entries); null = not a toggle.
  final bool? selected;

  /// A separator before this button.
  final bool divider;

  /// The label stays on a narrow window (the main action).
  final bool keepLabel;

  bool get enabled => onPressed != null || (menu?.isNotEmpty ?? false);

  /// What the bar draws (closures left out): a new list with the same
  /// signature doesn't rebuild the bar.
  String get signature =>
      '$id|$label|$enabled|$selected|$divider|$badge|$color|'
      '${dropOffer != null}|'
      '${menu?.map((m) => m.signature).join(',')}';
}

/// The commands the screen of each section shows in the shell's command
/// bar. Screens publish them after each build.
@Riverpod(keepAlive: true)
class DesktopCommands extends _$DesktopCommands {
  @override
  List<DesktopCommand> build(DesktopSection section) => const [];

  void set(List<DesktopCommand> commands) {
    final same =
        commands.length == state.length &&
        listEquals(
          [for (final c in commands) c.signature],
          [for (final c in state) c.signature],
        );
    // Same look: the fresh closures still replace the old ones, without a
    // rebuild of the bar.
    if (same) {
      _latest = commands;
      return;
    }
    _latest = commands;
    state = commands;
  }

  List<DesktopCommand> _latest = const [];

  /// The newest closures for the command [id].
  DesktopCommand? latest(String id) => _find(_latest, id);

  static DesktopCommand? _find(List<DesktopCommand> list, String id) {
    for (final c in list) {
      if (c.id == id) return c;
      if (c.menu case final m?) {
        if (_find(m, id) case final hit?) return hit;
      }
    }
    return null;
  }
}

/// The row under the address bar (TASK-E3): the active location's
/// commands. Empty locations (Devices, Settings) collapse the row.
class DesktopCommandBar extends ConsumerWidget {
  const new({required this.section, super.key});

  final DesktopSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commands = ref.watch(desktopCommandsProvider(section));
    if (commands.isEmpty) return const SizedBox.shrink();
    // Labels go (icons with tooltips stay) when the row would not fit:
    // a rough width per labelled button (icon + padding + ~7.5 px per
    // character at the text scale).
    final scale = MediaQuery.textScalerOf(context).scale(1);
    double width(DesktopCommand c, {required bool label}) =>
        (c.divider ? 12 : 0) +
        (label
            ? 44 + c.label.length * 7.5 * scale + (c.menu != null ? 18 : 0)
            : 40 + (c.menu != null ? 18 : 0));
    final full = commands.fold<double>(0, (a, c) => a + width(c, label: true));
    final narrow = full > MediaQuery.sizeOf(context).width - 24;
    final ctl = ref.read(desktopCommandsProvider(section).notifier);
    return Container(
      height: scaledExtent(context, 40),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 6),
      alignment: AlignmentDirectional.centerStart,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final c in commands) ...[
              if (c.divider)
                const SizedBox(height: 24, child: VerticalDivider(width: 12)),
              _CommandButton(
                command: c,
                showLabel: !narrow || c.keepLabel,
                latest: ctl.latest,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CommandButton extends StatelessWidget {
  const new({
    required this.command,
    required this.showLabel,
    required this.latest,
  });

  final DesktopCommand command;
  final bool showLabel;
  final DesktopCommand? Function(String id) latest;

  String get _tip => switch (command.shortcut) {
    final s? => '${command.label} ($s)',
    null => command.label,
  };

  void _run(DesktopCommand c) => (latest(c.id) ?? c).onPressed?.call();

  @override
  Widget build(BuildContext context) {
    final button = _button(context);
    final offer = command.dropOffer;
    return offer == null
        ? button
        : DesktopDropTarget(offer: offer, child: button);
  }

  Widget _button(BuildContext context) {
    final c = command;
    final key = c.key ?? ValueKey('cmd-${c.id}');
    final Widget icon = c.badge
        ? Badge(smallSize: 8, child: Icon(c.icon, size: 18, color: c.color))
        : Icon(c.icon, size: 18, color: c.color);
    if (c.menu case final menu?) {
      return MenuAnchor(
        menuChildren: [
          for (final m in menu)
            if (m.selected case final sel?)
              KeyedSubtree(
                key: m.key ?? ValueKey('cmd-${m.id}'),
                child: CheckboxMenuButton(
                  value: sel,
                  onChanged: m.onPressed == null ? null : (_) => _run(m),
                  child: Text(m.label),
                ),
              )
            else
              MenuItemButton(
                key: m.key ?? ValueKey('cmd-${m.id}'),
                leadingIcon: Icon(m.icon, size: 18),
                trailingIcon: m.shortcut == null
                    ? null
                    : Text(
                        m.shortcut!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                onPressed: m.onPressed == null ? null : () => _run(m),
                child: Text(m.label),
              ),
        ],
        builder: (context, controller, _) => Tooltip(
          message: _tip,
          child: TextButton.icon(
            key: key,
            onPressed: c.enabled
                ? () =>
                      controller.isOpen ? controller.close() : controller.open()
                : null,
            icon: icon,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showLabel) Text(c.label),
                const Icon(Icons.arrow_drop_down, size: 18),
              ],
            ),
          ),
        ),
      );
    }
    final onPressed = c.onPressed == null ? null : () => _run(c);
    if (!showLabel) {
      return IconButton(
        key: key,
        tooltip: _tip,
        isSelected: c.selected,
        onPressed: onPressed,
        icon: icon,
      );
    }
    return Tooltip(
      message: _tip,
      child: TextButton.icon(
        key: key,
        onPressed: onPressed,
        icon: icon,
        label: Text(c.label),
      ),
    );
  }
}
