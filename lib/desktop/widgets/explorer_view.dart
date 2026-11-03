import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kfm/desktop/widgets/desktop_drag.dart';
import 'package:kfm/desktop/widgets/desktop_metrics.dart';
import 'package:kfm/desktop/widgets/explorer_selection.dart';

/// How an [ExplorerView] lays out its items (TASK-PL3: Large icons / Grid
/// / Details).
enum ExplorerLayout { largeIcons, grid, details }

/// One column of the Details layout.
@immutable
class ExplorerColumn<T> {
  const new({
    required this.id,
    required this.label,
    required this.cell,
    this.width = 120,
    this.expand = false,
    this.sortable = false,
    this.alignEnd = false,
  });

  final String id;
  final String label;
  final Widget Function(BuildContext context, T item) cell;

  /// Fixed width (ignored when [expand]).
  final double width;

  /// Takes the remaining width (the Name column).
  final bool expand;
  final bool sortable;

  /// Numbers (size) align to the end.
  final bool alignEnd;
}

/// What a tile builder knows about its item.
typedef ExplorerTileBuilder<T> = Widget Function(
  BuildContext context,
  T item, {
  required double extent,
});

/// An Explorer-like file view (TASK-PL3): grid or details list with
/// Windows selection rules (click, Ctrl/Shift+click, Ctrl+A, rubber band),
/// keyboard navigation (arrows, Home/End, PgUp/PgDn, type-to-find), double
/// click / Enter to open and right-click menus. The selection is owned by
/// the caller ([selection] + [onSelectionChanged]).
class ExplorerView<T> extends StatefulWidget {
  const new({
    required this.items,
    required this.idOf,
    required this.layout,
    required this.selection,
    required this.onSelectionChanged,
    required this.tileBuilder,
    this.columns = const [],
    this.sortColumn,
    this.sortDescending = false,
    this.onSort,
    this.onOpen,
    this.onContextMenu,
    this.onKey,
    this.onNearEnd,
    this.nameOf,
    this.focusNode,
    this.autofocus = false,
    this.scrollController,
    this.dragController,
    this.dragDataOf,
    this.itemDropOffer,
    this.columnWidths = const {},
    this.onColumnWidthsChanged,
    super.key,
  });

  final List<T> items;
  final String Function(T item) idOf;
  final ExplorerLayout layout;
  final ExplorerSelection selection;
  final ValueChanged<ExplorerSelection> onSelectionChanged;

  /// The tile body (thumbnail + name) for the icon layouts; the view draws
  /// hover, selection and focus around it.
  final ExplorerTileBuilder<T> tileBuilder;

  /// Details layout columns.
  final List<ExplorerColumn<T>> columns;
  final String? sortColumn;
  final bool sortDescending;
  final ValueChanged<String>? onSort;

  /// Double-click or Enter.
  final ValueChanged<T>? onOpen;

  /// Right-click (or the context-menu key): `item` null = the background.
  final void Function(T? item, Offset globalPosition)? onContextMenu;

  /// Keys the screen handles first (actions, quick look). Return
  /// [KeyEventResult.handled] to stop the view's own handling.
  final KeyEventResult Function(KeyEvent event)? onKey;

  /// Scrolled close to the end (load the next page).
  final VoidCallback? onNearEnd;

  /// Type-to-find: the name typed letters match (null = off).
  final String Function(T item)? nameOf;

  final FocusNode? focusNode;
  final bool autofocus;
  final ScrollController? scrollController;

  /// Drag & drop (TASK-PL3 step 4): dragging selected items starts a drag
  /// of [dragDataOf]`(the dragged ids)` on [dragController].
  final DesktopDragController? dragController;
  final DesktopDragData? Function(Set<String> ids)? dragDataOf;

  /// Items that take drops (folders); null = none.
  final DropOfferBuilder? Function(T item)? itemDropOffer;

  /// Details column widths the user dragged before (unscaled; by column
  /// id), e.g. remembered in the settings.
  final Map<String, double> columnWidths;

  /// A column was resized or reset: all dragged widths (unscaled).
  final ValueChanged<Map<String, double>>? onColumnWidthsChanged;

  static const padding = 12.0;
  static const gap = 6.0;
  static const rowHeight = 32.0;
  static const headerHeight = 32.0;

  @override
  State<ExplorerView<T>> createState() => ExplorerViewState<T>();
}

/// Geometry of one layout at a width (so hit tests match what is drawn).
@immutable
class _Geometry {
  const new({
    required this.layout,
    required this.cross,
    required this.tileWidth,
    required this.rowExtent,
    required this.width,
    this.header = 0,
  });

  /// [scale]: `desktopTextScale` (L5): rows, header and labels grow.
  factory of(ExplorerLayout layout, double width, {double scale = 1}) {
    if (layout == ExplorerLayout.details) {
      return _Geometry(
        layout: layout,
        cross: 1,
        tileWidth: width,
        rowExtent: ExplorerView.rowHeight * scale,
        width: width,
        header: ExplorerView.headerHeight * scale,
      );
    }
    final extent = layout == ExplorerLayout.largeIcons ? 184.0 : 124.0;
    final label = (layout == ExplorerLayout.largeIcons ? 44.0 : 40.0) * scale;
    const pad = ExplorerView.padding;
    const gap = ExplorerView.gap;
    final double inner = math.max(1, width - 2 * pad);
    final cross = math.max(1, ((inner + gap) / (extent + gap)).floor());
    final tile = (inner - gap * (cross - 1)) / cross;
    return _Geometry(
      layout: layout,
      cross: cross,
      tileWidth: tile,
      rowExtent: tile + label,
      width: width,
    );
  }

  final ExplorerLayout layout;
  final int cross;
  final double tileWidth;
  final double rowExtent;
  final double width;

  /// The Details column header's height (0 for the icon layouts).
  final double header;

  bool get details => layout == ExplorerLayout.details;

  /// Content coordinates (inside the scroll view) of item [i].
  Rect rectOf(int i) {
    if (details) {
      return Rect.fromLTWH(0, i * rowExtent, width, rowExtent);
    }
    const pad = ExplorerView.padding;
    const gap = ExplorerView.gap;
    final row = i ~/ cross;
    final col = i % cross;
    return Rect.fromLTWH(
      pad + col * (tileWidth + gap),
      pad + row * (rowExtent + gap),
      tileWidth,
      rowExtent,
    );
  }
}

class ExplorerViewState<T> extends State<ExplorerView<T>> {
  late ScrollController _scroll = widget.scrollController ?? ScrollController();
  FocusNode? _ownFocus;
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  _Geometry? _geo;
  bool _downOnItem = false;
  String? _lastClickId;
  DateTime? _lastClickAt;

  // Rubber band, in content coordinates.
  Offset? _bandStart;
  Offset? _bandEnd;
  Set<String> _bandBase = const {};

  // Drag: where the primary button went down on an item.
  Offset? _pressAt;
  String? _pressId;
  bool _dragging = false;

  /// A plain click on an item of a multi-selection: collapsed to that item
  /// on release, unless it became a drag (Explorer).
  String? _deferredClick;

  // Type-to-find.
  String _typed = '';
  Timer? _typedReset;

  /// Column widths the user dragged (unscaled; by column id), seeded from
  /// [ExplorerView.columnWidths] and reported through
  /// [ExplorerView.onColumnWidthsChanged] when a drag ends.
  late final Map<String, double> _widths = {...widget.columnWidths};
  bool _resizing = false;

  /// L5 `desktopTextScale`, set each build.
  double _scale = 1;

  static const _minColumn = 48.0;
  static const _maxColumn = 800.0;

  double _columnWidth(ExplorerColumn<T> c, double scale) =>
      (_widths[c.id] ?? c.width) * scale;

  List<String> get _order => [for (final i in widget.items) widget.idOf(i)];

  /// Item id → index for the view's items, built on first use per list.
  late Map<String, int> _indexById;
  List<T>? _indexedItems;

  /// Where the item with [key] is now, so an item keeps its element (and
  /// its loaded thumbnail) when the items before it change (Sort: the
  /// acted-on file leaves, every later tile moves up one).
  int? _indexOfKey(Key key) {
    if (key is! ValueKey<String>) return null;
    final items = widget.items;
    if (!identical(items, _indexedItems)) {
      _indexedItems = items;
      _indexById = {
        for (var i = 0; i < items.length; i++) widget.idOf(items[i]): i,
      };
    }
    var id = key.value;
    if (id.startsWith(_dropKeyPrefix)) id = id.substring(_dropKeyPrefix.length);
    return _indexById[id];
  }

  static const _dropKeyPrefix = 'drop-';

  /// Whether this view's section is the shown one (go_router keeps the
  /// other shell branches alive with tickers off).
  bool? _active;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = TickerMode.valuesOf(context).enabled;
    // Back on this section (sidebar click): the keys work at once again.
    // `autofocus` only acts on the first build, and the section left
    // behind keeps the focus otherwise.
    if (widget.autofocus && _active == false && active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_focus.hasFocus) _focus.requestFocus();
      });
    }
    _active = active;
  }

  @override
  void didUpdateWidget(ExplorerView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _latest = null;
    if (!_resizing && !mapEquals(oldWidget.columnWidths, widget.columnWidths)) {
      _widths
        ..clear()
        ..addAll(widget.columnWidths);
    }
    if (oldWidget.scrollController != widget.scrollController &&
        widget.scrollController != null) {
      _scroll = widget.scrollController!;
    }
  }

  @override
  void dispose() {
    if (_dragging) widget.dragController?.cancel();
    if (widget.scrollController == null) _scroll.dispose();
    _ownFocus?.dispose();
    _typedReset?.cancel();
    super.dispose();
  }

  /// The latest selection: a change made by an event is seen by the next
  /// event even before the parent rebuilt (fast clicks and keys).
  ExplorerSelection? _latest;
  ExplorerSelection get _s => _latest ?? widget.selection;

  void _select(ExplorerSelection s) {
    if (s == _s) return;
    _latest = s;
    widget.onSelectionChanged(s);
  }

  /// Scrolls so item [index] is fully visible.
  void revealIndex(int index) {
    final geo = _geo;
    if (geo == null || !_scroll.hasClients || index < 0) return;
    final rect = geo.rectOf(index);
    final pos = _scroll.position;
    final view = pos.viewportDimension;
    const pad = ExplorerView.padding;
    var target = pos.pixels;
    if (rect.top - pad < target) target = rect.top - pad;
    if (rect.bottom + pad > target + view) target = rect.bottom + pad - view;
    target = target.clamp(pos.minScrollExtent, pos.maxScrollExtent);
    if (target != pos.pixels) _scroll.jumpTo(target);
  }

  /// Scrolls to [id] (after an undo brought a file back).
  void reveal(String id) {
    final i = _order.indexOf(id);
    if (i < 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) revealIndex(i);
    });
  }

  void requestFocus() => _focus.requestFocus();

  // --- pointer -------------------------------------------------------------

  void _onItemDown(PointerDownEvent e, T item) {
    _downOnItem = true;
    _focus.requestFocus();
    final id = widget.idOf(item);
    if (e.buttons & kSecondaryMouseButton != 0) {
      _select(_s.secondaryClick(id));
      widget.onContextMenu?.call(item, e.position);
      return;
    }
    if (e.buttons & kPrimaryMouseButton == 0) return;
    final now = DateTime.now();
    final last = _lastClickAt;
    final isDouble =
        _lastClickId == id &&
        last != null &&
        now.difference(last) < kDoubleTapTimeout * 1.6;
    _lastClickId = isDouble ? null : id;
    _lastClickAt = isDouble ? null : now;
    final keys = HardwareKeyboard.instance;
    if (isDouble) {
      _pressAt = null;
      _select(_s.click(id, _order));
      widget.onOpen?.call(item);
      return;
    }
    _pressAt = e.position;
    _pressId = id;
    _deferredClick = null;
    final plain = !keys.isControlPressed && !keys.isShiftPressed;
    if (plain && _s.contains(id) && _s.count > 1 && _canDrag) {
      _deferredClick = id;
      return;
    }
    _select(
      _s.click(
        id,
        _order,
        ctrl: keys.isControlPressed,
        shift: keys.isShiftPressed,
      ),
    );
  }

  bool get _canDrag =>
      widget.dragController != null && widget.dragDataOf != null;

  void _onItemMove(PointerMoveEvent e) {
    final controller = widget.dragController;
    final dataOf = widget.dragDataOf;
    final at = _pressAt;
    final id = _pressId;
    if (controller == null || dataOf == null || at == null || id == null) {
      return;
    }
    final ctrl = HardwareKeyboard.instance.isControlPressed;
    if (_dragging) {
      controller.update(e.position, copy: ctrl);
      return;
    }
    if (e.buttons & kPrimaryMouseButton == 0) return;
    if ((e.position - at).distance < 6) return;
    _deferredClick = null;
    final ids = _s.contains(id) ? _s.ids : {id};
    final data = dataOf(ids);
    if (data == null || data.count == 0) {
      _pressAt = null;
      return;
    }
    _dragging = true;
    controller.begin(data, e.position, copy: ctrl);
  }

  void _onItemUp(PointerUpEvent e) {
    _pressAt = null;
    if (_dragging) {
      _dragging = false;
      unawaited(widget.dragController?.drop());
      return;
    }
    final deferred = _deferredClick;
    _deferredClick = null;
    if (deferred != null) _select(_s.click(deferred, _order));
  }

  void _onItemCancel(PointerCancelEvent e) {
    _pressAt = null;
    _deferredClick = null;
    if (_dragging) {
      _dragging = false;
      widget.dragController?.cancel();
    }
  }

  Offset _content(Offset local) {
    final header = _geo?.header ?? 0.0;
    final offset = _scroll.hasClients ? _scroll.offset : 0.0;
    return Offset(local.dx, local.dy - header + offset);
  }

  void _onBackgroundDown(PointerDownEvent e) {
    if (_downOnItem) {
      _downOnItem = false;
      return;
    }
    _focus.requestFocus();
    if (e.buttons & kSecondaryMouseButton != 0) {
      widget.onContextMenu?.call(null, e.position);
      return;
    }
    if (e.buttons & kPrimaryMouseButton == 0) return;
    final header = _geo?.header ?? 0.0;
    if (e.localPosition.dy < header) return; // column headers
    final ctrl = HardwareKeyboard.instance.isControlPressed;
    _bandBase = ctrl ? _s.ids : const {};
    if (!ctrl) _select(ExplorerSelection.empty);
    setState(() {
      _bandStart = _content(e.localPosition);
      _bandEnd = _bandStart;
    });
  }

  void _onBackgroundMove(PointerMoveEvent e, double viewHeight) {
    final start = _bandStart;
    if (start == null) return;
    // Auto-scroll near the edges.
    if (_scroll.hasClients) {
      final pos = _scroll.position;
      if (e.localPosition.dy > viewHeight - 24 &&
          pos.pixels < pos.maxScrollExtent) {
        _scroll.jumpTo(math.min(pos.maxScrollExtent, pos.pixels + 24));
      } else if (e.localPosition.dy < 24 && pos.pixels > 0) {
        _scroll.jumpTo(math.max(0, pos.pixels - 24));
      }
    }
    final end = _content(e.localPosition);
    final band = Rect.fromPoints(start, end);
    final geo = _geo;
    if (geo == null) return;
    final hit = <String>{};
    final order = _order;
    for (var i = 0; i < order.length; i++) {
      if (geo.rectOf(i).overlaps(band)) hit.add(order[i]);
    }
    setState(() => _bandEnd = end);
    _select(_s.band(hit, base: _bandBase));
  }

  void _endBand() {
    if (_bandStart == null) return;
    setState(() {
      _bandStart = null;
      _bandEnd = null;
    });
  }

  // --- keyboard ------------------------------------------------------------

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final custom = widget.onKey?.call(event);
    if (custom == KeyEventResult.handled) return custom!;
    final order = _order;
    final keys = HardwareKeyboard.instance;
    final ctrl = keys.isControlPressed;
    final shift = keys.isShiftPressed;
    final geo = _geo;
    final cross = geo?.cross ?? 1;
    final current = _s.focusIndex(order);
    int? to;
    final key = event.logicalKey;
    final grid = !(geo?.details ?? false);
    final pageRows = _scroll.hasClients && geo != null
        ? math.max(
            1,
            (_scroll.position.viewportDimension / geo.rowExtent).floor(),
          )
        : 5;
    if (key == LogicalKeyboardKey.arrowRight && grid) {
      to = current + 1;
    } else if (key == LogicalKeyboardKey.arrowLeft && grid) {
      to = current - 1;
    } else if (key == LogicalKeyboardKey.arrowDown) {
      to = current < 0 ? 0 : current + cross;
    } else if (key == LogicalKeyboardKey.arrowUp) {
      to = current < 0 ? 0 : current - cross;
    } else if (key == LogicalKeyboardKey.home) {
      to = 0;
    } else if (key == LogicalKeyboardKey.end) {
      to = order.length - 1;
    } else if (key == LogicalKeyboardKey.pageDown) {
      to = current + pageRows * cross;
    } else if (key == LogicalKeyboardKey.pageUp) {
      to = current - pageRows * cross;
    } else if (key == LogicalKeyboardKey.keyA && ctrl) {
      _select(_s.selectAll(order));
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.space && ctrl) {
      _select(_s.toggleFocus());
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.escape) {
      if (_s.isEmpty) return KeyEventResult.ignored;
      _select(ExplorerSelection(focus: _s.focus));
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (current < 0) return KeyEventResult.ignored;
      widget.onOpen?.call(widget.items[current]);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.contextMenu ||
        (key == LogicalKeyboardKey.f10 && shift)) {
      final box = context.findRenderObject() as RenderBox?;
      final at = current >= 0 && geo != null
          ? geo
                .rectOf(current)
                .center
                .translate(0, -(_scroll.hasClients ? _scroll.offset : 0.0))
          : const Offset(40, 40);
      widget.onContextMenu?.call(
        current >= 0 ? widget.items[current] : null,
        box?.localToGlobal(at) ?? at,
      );
      return KeyEventResult.handled;
    } else if (_typeToFind(event, ctrl: ctrl)) {
      return KeyEventResult.handled;
    }
    if (to == null || order.isEmpty) return KeyEventResult.ignored;
    final index = to.clamp(0, order.length - 1);
    _select(_s.moveTo(index, order, shift: shift, ctrl: ctrl));
    revealIndex(index);
    return KeyEventResult.handled;
  }

  bool _typeToFind(KeyEvent event, {required bool ctrl}) {
    final nameOf = widget.nameOf;
    final ch = event.character;
    if (nameOf == null || ctrl || ch == null || ch.trim().isEmpty) {
      return false;
    }
    _typedReset?.cancel();
    _typedReset = Timer(const Duration(milliseconds: 900), () => _typed = '');
    _typed += ch.toLowerCase();
    final order = _order;
    final start = math.max(0, _s.focusIndex(order));
    // A repeated single letter cycles; a longer prefix stays on a match.
    final cycle = _typed.length > 1 && _typed.split('').toSet().length == 1;
    final prefix = cycle ? _typed.substring(0, 1) : _typed;
    final from = _typed.length == 1 || cycle ? start + 1 : start;
    for (var k = 0; k < order.length; k++) {
      final i = (from + k) % order.length;
      if (nameOf(widget.items[i]).toLowerCase().startsWith(prefix)) {
        _select(_s.moveTo(i, order));
        revealIndex(i);
        break;
      }
    }
    return true;
  }

  // --- build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Focus(
      focusNode: _focus,
      autofocus: widget.autofocus,
      onKeyEvent: _onKey,
      child: LayoutBuilder(
        builder: (context, box) {
          final geo = _geo = _Geometry.of(
            widget.layout,
            box.maxWidth,
            scale: _scale = desktopTextScale(context),
          );
          final header = geo.header;
          final band = _bandStart != null && _bandEnd != null
              ? Rect.fromPoints(_bandStart!, _bandEnd!)
              : null;
          final offset = _scroll.hasClients ? _scroll.offset : 0.0;
          return Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: _onBackgroundDown,
            onPointerMove: (e) => _onBackgroundMove(e, box.maxHeight),
            onPointerUp: (_) => _endBand(),
            onPointerCancel: (_) => _endBand(),
            child: Stack(
              children: [
                Column(
                  children: [
                    if (geo.details) _header(context),
                    Expanded(
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (n) {
                          if (n.metrics.extentAfter < 800) {
                            widget.onNearEnd?.call();
                          }
                          if (_bandStart != null) setState(() {});
                          return false;
                        },
                        child: _scrollView(context, geo),
                      ),
                    ),
                  ],
                ),
                if (band != null)
                  Positioned(
                    left: band.left,
                    top: band.top - offset + header,
                    width: band.width,
                    height: band.height,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        key: const ValueKey('explorer-band'),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.12),
                          border: Border.all(color: colors.primary),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _scrollView(BuildContext context, _Geometry geo) {
    final items = widget.items;
    if (geo.details) {
      return CustomScrollView(
        controller: _scroll,
        slivers: [
          SliverFixedExtentList(
            itemExtent: geo.rowExtent,
            delegate: SliverChildBuilderDelegate(
              (context, i) => _item(context, items[i], geo),
              childCount: items.length,
              findChildIndexCallback: _indexOfKey,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 48)),
        ],
      );
    }
    return CustomScrollView(
      controller: _scroll,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(ExplorerView.padding),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: geo.cross,
              mainAxisExtent: geo.rowExtent,
              mainAxisSpacing: ExplorerView.gap,
              crossAxisSpacing: ExplorerView.gap,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => _item(context, items[i], geo),
              childCount: items.length,
              findChildIndexCallback: _indexOfKey,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 48)),
      ],
    );
  }

  Widget _item(BuildContext context, T item, _Geometry geo) {
    final id = widget.idOf(item);
    final view = _ExplorerItem(
      key: ValueKey(id),
      selected: _s.contains(id),
      focused: _s.focus == id,
      details: geo.details,
      onDown: (e) => _onItemDown(e, item),
      onMove: _onItemMove,
      onUp: _onItemUp,
      onCancel: _onItemCancel,
      child: geo.details
          ? _row(context, item)
          : widget.tileBuilder(context, item, extent: geo.tileWidth),
    );
    final offer = widget.itemDropOffer?.call(item);
    return offer == null
        ? view
        : DesktopDropTarget(
            key: ValueKey('$_dropKeyPrefix$id'),
            offer: offer,
            radius: geo.details ? 4 : 10,
            child: view,
          );
  }

  Widget _row(BuildContext context, T item) => Row(
    children: [
      for (final c in widget.columns)
        _cellBox(
          c,
          Align(
            alignment: c.alignEnd
                ? AlignmentDirectional.centerEnd
                : AlignmentDirectional.centerStart,
            child: c.cell(context, item),
          ),
        ),
    ],
  );

  Widget _cellBox(ExplorerColumn<T> c, Widget child) {
    final padded = Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
      child: child,
    );
    return c.expand
        ? Expanded(child: padded)
        : SizedBox(width: _columnWidth(c, _scale), child: padded);
  }

  /// The drag handle on a fixed column's end edge (Explorer's column
  /// divider): drag to resize, double-click to reset.
  Widget _resizable(ExplorerColumn<T> c, Widget cell) {
    if (c.expand) return cell;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return SizedBox(
      width: _columnWidth(c, _scale),
      child: Stack(
        children: [
          Positioned.fill(child: Row(children: [cell])),
          PositionedDirectional(
            end: 0,
            top: 0,
            bottom: 0,
            width: 8,
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeColumn,
              child: GestureDetector(
                key: ValueKey('explorer-resize-${c.id}'),
                behavior: HitTestBehavior.opaque,
                // The edge follows the pointer from the press on.
                dragStartBehavior: DragStartBehavior.down,
                onDoubleTap: () {
                  setState(() => _widths.remove(c.id));
                  _reportWidths();
                },
                onHorizontalDragStart: (_) => _resizing = true,
                onHorizontalDragEnd: (_) => _endResize(),
                onHorizontalDragCancel: _endResize,
                onHorizontalDragUpdate: (d) => setState(() {
                  final dx = (rtl ? -d.delta.dx : d.delta.dx) / _scale;
                  _widths[c.id] = ((_widths[c.id] ?? c.width) + dx).clamp(
                    _minColumn,
                    _maxColumn,
                  );
                }),
                child: Center(
                  child: Container(
                    width: 1,
                    height: double.infinity,
                    color: Theme.of(context).dividerColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _endResize() {
    if (!_resizing) return;
    _resizing = false;
    _reportWidths();
  }

  void _reportWidths() =>
      widget.onColumnWidthsChanged?.call(Map.unmodifiable(_widths));

  Widget _header(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return SizedBox(
      height: _geo?.header ?? ExplorerView.headerHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: theme.dividerColor)),
        ),
        child: Row(
          children: [
            for (final c in widget.columns)
              _resizable(
                c,
                _cellBox(
                  c,
                  InkWell(
                    key: ValueKey('explorer-column-${c.id}'),
                    onTap: c.sortable && widget.onSort != null
                        ? () => widget.onSort!(c.id)
                        : null,
                    child: Row(
                      mainAxisAlignment: c.alignEnd
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Text(
                            c.label,
                            style: style,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.sortColumn == c.id)
                          Icon(
                            widget.sortDescending
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            size: 14,
                            color: style?.color,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Hover, selection and focus around one item.
class _ExplorerItem extends StatefulWidget {
  const new({
    required this.selected,
    required this.focused,
    required this.details,
    required this.onDown,
    required this.onMove,
    required this.onUp,
    required this.onCancel,
    required this.child,
    super.key,
  });

  final bool selected;
  final bool focused;
  final bool details;
  final void Function(PointerDownEvent e) onDown;
  final void Function(PointerMoveEvent e) onMove;
  final void Function(PointerUpEvent e) onUp;
  final void Function(PointerCancelEvent e) onCancel;
  final Widget child;

  @override
  State<_ExplorerItem> createState() => _ExplorerItemState();
}

class _ExplorerItemState extends State<_ExplorerItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bg = widget.selected
        ? colors.primary.withValues(alpha: _hover ? 0.26 : 0.2)
        : _hover
        ? colors.onSurface.withValues(alpha: 0.06)
        : Colors.transparent;
    final radius = BorderRadius.circular(widget.details ? 4 : 10);
    return Semantics(
      selected: widget.selected,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: Listener(
          onPointerDown: widget.onDown,
          onPointerMove: widget.onMove,
          onPointerUp: widget.onUp,
          onPointerCancel: widget.onCancel,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            padding: widget.details ? EdgeInsets.zero : const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: radius,
              border: Border.all(
                color: widget.focused
                    ? colors.primary.withValues(alpha: 0.8)
                    : Colors.transparent,
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
