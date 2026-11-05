import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/files/file_ref.dart';

/// Where dragged files come from (TASK-PL3 step 4).
enum DragOrigin {
  /// Desktop Browse: KFM files; a drop moves (Ctrl = copy).
  browse,

  /// The Sort grid: deck files; a drop is a one-off Sort action.
  sort,

  /// Windows Explorer (or any app): file system paths; a drop copies.
  explorer,
}

/// The files of one drag.
@immutable
class DesktopDragData {
  const new({
    required this.origin,
    this.files = const [],
    this.paths = const [],
    this.folders = const [],
  });

  final DragOrigin origin;

  /// KFM files (browse / sort).
  final List<FileRef> files;

  /// '/'-separated paths ([DragOrigin.explorer]).
  final List<String> paths;

  /// Whole folders dragged in desktop Browse ('/'-separated paths).
  final List<String> folders;

  int get count => origin == DragOrigin.explorer
      ? paths.length
      : files.length + folders.length;

  /// Files only (targets that act on files: tags, Trash, Devices…).
  bool get filesOnly => folders.isEmpty;

  /// Every path of a KFM drag (files and folders), for a drag out.
  List<String> get allPaths => [for (final f in files) f.path, ...folders];

  bool get fromKfm => origin != DragOrigin.explorer;
}

/// What a drop target does with a drag (null = it doesn't take it).
@immutable
class DropOffer {
  const new({
    required this.label,
    required this.onDrop,
    this.ctrlCopies = false,
  });

  /// "Move to Pictures", "Add tag Holiday"…
  final String label;

  /// A move that Ctrl turns into a copy (the hint says so).
  final bool ctrlCopies;
  final Future<void> Function() onDrop;
}

/// A [DesktopDropTarget]'s decision for [data]; [copy] = Ctrl is held.
typedef DropOfferBuilder = DropOffer? Function(
  DesktopDragData data, {
  required bool copy,
});

/// One drag at a time, inside KFM (a pointer drag from a file view) or
/// from outside (Windows' OLE drop target, see `drag_drop_channel.dart`).
/// The target under the pointer is found with a real hit test, so targets
/// on hidden shell branches never take a drop.
class DesktopDragController extends ChangeNotifier {
  new({this.windowSize, this.onLeaveWindow});

  /// The window's logical size; a KFM drag that leaves it is handed to
  /// [onLeaveWindow] (Windows: a native drag of the file paths).
  Size? Function()? windowSize;

  /// Starts the drag out of the window. Returns when it is over.
  Future<void> Function(DesktopDragData data)? onLeaveWindow;

  DesktopDragData? _data;
  Offset? _position;
  bool _copy = false;
  _DropTargetState? _hover;
  DropOffer? _offer;
  bool _handingOff = false;

  DesktopDragData? get data => _data;
  Offset? get position => _position;
  DropOffer? get offer => _offer;
  bool get copy => _copy;
  bool get active => _data != null;

  /// A drag inside KFM from [data] at [position] (global, logical).
  void begin(DesktopDragData data, Offset position, {bool copy = false}) {
    _data = data;
    _copy = copy;
    _move(position);
  }

  /// The pointer moved. A KFM drag that leaves the window becomes a native
  /// drag (when [onLeaveWindow] is set and the files have paths).
  void update(Offset position, {bool? copy}) {
    final data = _data;
    if (data == null || _handingOff) return;
    if (copy != null) _copy = copy;
    final size = windowSize?.call();
    final leave = onLeaveWindow;
    if (data.fromKfm &&
        leave != null &&
        size != null &&
        !(Offset.zero & size).contains(position)) {
      _handingOff = true;
      _setHover(null, null);
      _setHold(null);
      _position = null;
      notifyListeners();
      unawaited(
        leave(data).whenComplete(() {
          _handingOff = false;
          cancel();
        }),
      );
      return;
    }
    _move(position);
  }

  /// Drops at the last position. True when a target took it.
  Future<bool> drop() async {
    final offer = _offer;
    _clear();
    if (offer == null) return false;
    await offer.onDrop();
    return true;
  }

  void cancel() => _clear();

  // --- E3: the pointer of a drag started in a KFM list ----------------------
  int? _pointer;

  /// Follows [pointer] (moves update, up drops, cancel cancels) through the
  /// global pointer router, independent of the widget that started it.
  void trackPointer(int pointer) {
    _untrack();
    _pointer = pointer;
    GestureBinding.instance.pointerRouter.addRoute(pointer, _route);
  }

  void _route(PointerEvent e) {
    if (e is PointerMoveEvent) {
      update(e.position, copy: HardwareKeyboard.instance.isControlPressed);
    } else if (e is PointerUpEvent) {
      _untrack();
      unawaited(drop());
    } else if (e is PointerCancelEvent) {
      _untrack();
      cancel();
    }
  }

  void _untrack() {
    if (_pointer case final p?) {
      GestureBinding.instance.pointerRouter.removeRoute(p, _route);
    }
    _pointer = null;
  }

  void _clear() {
    _untrack();
    if (_data == null && _hover == null) return;
    _data = null;
    _position = null;
    _setHover(null, null);
    _setHold(null);
    notifyListeners();
  }

  void _move(Offset position) {
    _position = position;
    final data = _data!;
    _DropTargetState? found;
    DropOffer? offer;
    _DropTargetState? hold;
    final result = HitTestResult();
    final binding = WidgetsBinding.instance;
    final views = binding.renderViews;
    if (views.isNotEmpty) {
      binding.hitTestInView(result, position, views.first.flutterView.viewId);
    }
    for (final entry in result.path) {
      final target = entry.target;
      if (target is RenderMetaData && target.metaData is _DropTargetState) {
        final state = target.metaData as _DropTargetState;
        if (!state.mounted) continue;
        hold ??= state.widget.onHoverHold == null ? null : state;
        final o = state.widget.offer(data, copy: _copy);
        if (o != null) {
          found = state;
          offer = o;
          break;
        }
      }
    }
    _setHover(found, offer);
    _setHold(hold);
    notifyListeners();
  }

  // E3: the target the pointer rests on, for [DesktopDropTarget.onHoverHold].
  _DropTargetState? _holdTarget;
  Timer? _holdTimer;

  void _setHold(_DropTargetState? target) {
    if (target == _holdTarget) return;
    _holdTimer?.cancel();
    _holdTimer = null;
    _holdTarget = target;
    final hold = target?.widget.onHoverHold;
    if (target == null || hold == null) return;
    _holdTimer = Timer(target.widget.holdDelay, () {
      _holdTimer = null;
      if (_data != null && _holdTarget == target && target.mounted) hold();
    });
  }

  void _setHover(_DropTargetState? target, DropOffer? offer) {
    final old = _hover;
    _hover = target;
    _offer = offer;
    if (old != target) {
      old?._setHovered(false);
      target?._setHovered(true);
    }
  }
}

/// A place files can be dropped on: highlights while a drag that it takes
/// is over it.
class DesktopDropTarget extends StatefulWidget {
  const new({
    required this.offer,
    required this.child,
    this.radius = 8,
    this.onHoverHold,
    this.holdDelay = const Duration(milliseconds: 600),
    super.key,
  });

  final DropOfferBuilder offer;
  final Widget child;
  final double radius;

  /// E3: a drag rested on this target for [holdDelay] (a tab switches to
  /// itself, a folder opens: spring-loaded folders). Also for targets that
  /// don't take the drag themselves.
  final VoidCallback? onHoverHold;
  final Duration holdDelay;

  @override
  State<DesktopDropTarget> createState() => _DropTargetState();
}

class _DropTargetState extends State<DesktopDropTarget> {
  bool _hovered = false;

  void _setHovered(bool v) {
    if (mounted && v != _hovered) setState(() => _hovered = v);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return MetaData(
      metaData: this,
      behavior: HitTestBehavior.translucent,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          color: _hovered ? colors.primary.withValues(alpha: 0.12) : null,
          borderRadius: BorderRadius.circular(widget.radius),
          border: Border.all(
            color: _hovered ? colors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

/// The label next to the pointer while dragging ("3 files", then what a
/// drop here does). Put it above everything (it ignores the pointer).
class DesktopDragOverlay extends StatelessWidget {
  const new({required this.controller, super.key});

  final DesktopDragController controller;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final data = controller.data;
        final at = controller.position;
        if (data == null || at == null) return const SizedBox.shrink();
        final box = context.findRenderObject() as RenderBox?;
        final local = box == null || !box.hasSize ? at : box.globalToLocal(at);
        final l10n = context.l10n;
        final theme = Theme.of(context);
        final offer = controller.offer;
        final what = data.filesOnly
            ? l10n.desktopDragCount(data.count)
            : l10n.desktopDragItems(data.count);
        return Stack(
          children: [
            Positioned(
              left: local.dx + 16,
              top: local.dy + 16,
              child: Material(
                key: const ValueKey('desktop-drag-label'),
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                color: theme.colorScheme.inverseSurface,
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: DefaultTextStyle(
                    style: theme.textTheme.labelMedium!.copyWith(
                      color: theme.colorScheme.onInverseSurface,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.file_copy_outlined,
                              size: 16,
                              color: theme.colorScheme.onInverseSurface,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              offer == null
                                  ? what
                                  : l10n.desktopDragOffer(what, offer.label),
                            ),
                          ],
                        ),
                        if (offer != null &&
                            offer.ctrlCopies &&
                            !controller.copy)
                          Text(
                            l10n.desktopDropCtrlHint,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onInverseSurface
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
