import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/form_factor.dart';
import 'package:kfm/features/settings/ui/settings_section.dart';

/// The entries of [section] that show right now on [formFactor].
List<SettingsEntry> visibleEntries(
  WidgetRef ref,
  SettingsSection section,
  FormFactor formFactor,
) => [
  for (final e in section.entriesFor(formFactor))
    if (e.isVisible(ref)) e,
];

/// The section holding entry [id], or null.
SettingsSection? sectionOfEntry(List<SettingsSection> sections, String id) {
  for (final s in sections) {
    if (s.entries.any((e) => e.id == id)) return s;
  }
  return null;
}

/// Scrolls to an entry and flashes it (search results, `/settings?entry=`).
class SettingsJumpController extends ChangeNotifier {
  final Map<String, GlobalKey> _keys = {};

  /// The entry flashing now, and a counter so the same entry flashes again.
  String? flashing;
  int flashToken = 0;

  GlobalKey keyFor(String id) => _keys.putIfAbsent(id, GlobalKey.new);

  /// Scrolls entry [id] into view once it is built (after the next frame,
  /// up to a few frames while a section switch settles) and flashes it.
  void jumpTo(String id) {
    flashing = id;
    flashToken++;
    notifyListeners();
    var tries = 0;
    void attempt(Duration _) {
      final ctx = _keys[id]?.currentContext;
      if (ctx != null && ctx.mounted) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.2,
          duration: const Duration(milliseconds: 250),
        );
      } else if (++tries < 5) {
        WidgetsBinding.instance.addPostFrameCallback(attempt);
        WidgetsBinding.instance.scheduleFrame();
      }
    }

    WidgetsBinding.instance.addPostFrameCallback(attempt);
    WidgetsBinding.instance.scheduleFrame();
  }
}

/// Makes a [SettingsJumpController] reachable from every entry.
class SettingsJumpScope extends InheritedNotifier<SettingsJumpController> {
  const new({
    required SettingsJumpController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static SettingsJumpController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsJumpScope>()?.notifier;
}

/// One entry's rows, keyed `setting-<id>`; flashes when jumped to.
class SettingsEntryView extends StatelessWidget {
  const new({required this.entry, super.key});

  final SettingsEntry entry;

  @override
  Widget build(BuildContext context) {
    final jump = SettingsJumpScope.maybeOf(context);
    final child = entry.builder(context);
    return KeyedSubtree(
      key: entry.key,
      child: jump == null
          ? child
          : _Flash(
              key: jump.keyFor(entry.id),
              token: jump.flashing == entry.id ? jump.flashToken : null,
              child: child,
            ),
    );
  }
}

/// A short highlight behind [child] each time [token] changes to non-null.
class _Flash extends StatefulWidget {
  const new({required this.token, required this.child, super.key});

  final int? token;
  final Widget child;

  @override
  State<_Flash> createState() => _FlashState();
}

class _FlashState extends State<_Flash> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.token != null) _c.forward(from: 0);
  }

  @override
  void didUpdateWidget(_Flash old) {
    super.didUpdateWidget(old);
    if (widget.token != null && widget.token != old.token) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primaryContainer;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        // Up fast, hold, fade out.
        final t = _c.value;
        final a = !_c.isAnimating
            ? 0.0
            : t < 0.15
            ? t / 0.15
            : t < 0.6
            ? 1.0
            : (1 - t) / 0.4;
        // A Material (not a DecoratedBox): ListTiles paint their ink on it.
        return a == 0
            ? Material(type: MaterialType.transparency, child: child)
            : Material(color: color.withValues(alpha: a * 0.7), child: child);
      },
      child: widget.child,
    );
  }
}
