import 'package:flutter/foundation.dart' show setEquals;
import 'package:meta/meta.dart';

/// Explorer-style selection over an ordered list of ids (TASK-PL3): click,
/// Ctrl+click, Shift+click, Ctrl+Shift+click, keyboard focus moves, select
/// all and rubber band. Immutable; every change returns a new value.
///
/// [anchor] is where a Shift range starts; [focus] is the item the keyboard
/// is on (the details pane shows it).
@immutable
class ExplorerSelection {
  const new({this.ids = const {}, this.anchor, this.focus});

  static const empty = ExplorerSelection();

  final Set<String> ids;
  final String? anchor;
  final String? focus;

  bool get isEmpty => ids.isEmpty;
  int get count => ids.length;
  bool contains(String id) => ids.contains(id);

  /// Selected ids in [order].
  List<String> ordered(List<String> order) => [
    for (final id in order)
      if (ids.contains(id)) id,
  ];

  /// A mouse click on [id].
  ExplorerSelection click(
    String id,
    List<String> order, {
    bool ctrl = false,
    bool shift = false,
  }) {
    if (shift) {
      final range = _range(order, anchor ?? focus ?? id, id);
      return ExplorerSelection(
        ids: ctrl ? {...ids, ...range} : range,
        anchor: anchor ?? id,
        focus: id,
      );
    }
    if (ctrl) {
      final next = {...ids};
      if (!next.remove(id)) next.add(id);
      return ExplorerSelection(ids: next, anchor: id, focus: id);
    }
    return ExplorerSelection(ids: {id}, anchor: id, focus: id);
  }

  /// A right-click on [id]: keeps a selection it belongs to, else selects
  /// only it (what Explorer does before showing the menu).
  ExplorerSelection secondaryClick(String id) => ids.contains(id)
      ? ExplorerSelection(ids: ids, anchor: anchor, focus: id)
      : ExplorerSelection(ids: {id}, anchor: id, focus: id);

  /// Keyboard: the focus moves to [order]\[index]. Plain = select only it;
  /// Shift = range from the anchor; Ctrl = move the focus only.
  ExplorerSelection moveTo(
    int index,
    List<String> order, {
    bool shift = false,
    bool ctrl = false,
  }) {
    if (order.isEmpty) return empty;
    final id = order[index.clamp(0, order.length - 1)];
    if (shift) {
      final from = anchor ?? focus ?? id;
      return ExplorerSelection(
        ids: _range(order, from, id),
        anchor: from,
        focus: id,
      );
    }
    if (ctrl) return ExplorerSelection(ids: ids, anchor: anchor, focus: id);
    return ExplorerSelection(ids: {id}, anchor: id, focus: id);
  }

  /// Ctrl+Space: toggles the focused item.
  ExplorerSelection toggleFocus() {
    final f = focus;
    if (f == null) return this;
    final next = {...ids};
    if (!next.remove(f)) next.add(f);
    return ExplorerSelection(ids: next, anchor: f, focus: f);
  }

  ExplorerSelection selectAll(List<String> order) => ExplorerSelection(
    ids: order.toSet(),
    anchor: order.isEmpty ? null : order.first,
    focus: focus ?? (order.isEmpty ? null : order.first),
  );

  /// Rubber band: [hit] (plus [base] with Ctrl held, Explorer's add-band).
  ExplorerSelection band(Set<String> hit, {Set<String> base = const {}}) =>
      ExplorerSelection(ids: {...base, ...hit}, anchor: anchor, focus: focus);

  /// Index of [focus] in [order] (-1 = none).
  int focusIndex(List<String> order) =>
      focus == null ? -1 : order.indexOf(focus!);

  /// Drops ids that left [order] (sorted away, deleted). When the focused
  /// item left, the focus goes to the item now at its old place, so
  /// pressing an action key again acts on the next file.
  ExplorerSelection retain(List<String> order, {List<String>? before}) {
    final present = order.toSet();
    final kept = {
      for (final id in ids)
        if (present.contains(id)) id,
    };
    var f = focus;
    if (f != null && !present.contains(f)) {
      final old = before?.indexOf(f) ?? -1;
      f = null;
      if (old >= 0 && before != null) {
        // The first item after the old focus that is still there.
        for (var i = old + 1; i < before.length; i++) {
          if (present.contains(before[i])) {
            f = before[i];
            break;
          }
        }
        if (f == null) {
          for (var i = old - 1; i >= 0; i--) {
            if (present.contains(before[i])) {
              f = before[i];
              break;
            }
          }
        }
      }
      if (f != null && kept.isEmpty) kept.add(f);
    }
    final a = anchor != null && present.contains(anchor) ? anchor : f;
    if (setEquals(kept, ids) && f == focus && a == anchor) return this;
    return ExplorerSelection(ids: kept, anchor: a, focus: f);
  }

  static Set<String> _range(List<String> order, String from, String to) {
    var a = order.indexOf(from);
    var b = order.indexOf(to);
    if (a < 0) a = b;
    if (b < 0) return const {};
    if (a > b) (a, b) = (b, a);
    return order.sublist(a, b + 1).toSet();
  }

  @override
  bool operator ==(Object other) =>
      other is ExplorerSelection &&
      other.anchor == anchor &&
      other.focus == focus &&
      setEquals(other.ids, ids);

  @override
  int get hashCode => Object.hash(anchor, focus, ids.length);
}
