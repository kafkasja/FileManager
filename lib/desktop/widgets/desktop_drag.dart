import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
  });

  final DragOrigin origin;

  /// KFM files (browse / sort).
  final List<FileRef> files;

  /// '/'-separated paths ([DragOrigin.explorer]).
  final List<String> paths;

  int get count => origin == DragOrigin.explorer ? paths.length : files.length;

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

  void _clear() {
    if (_data == null && _hover == null) return;
    _data = null;
    _position = null;
    _setHover(null, null);
    notifyListeners();
  }

  void _move(Offset position) {
    _position = position;
    final data = _data!;
    _DropTargetState? found;
    DropOffer? offer;
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
        final o = state.widget.offer(data, copy: _copy);
        if (o != null) {
          found = state;
          offer = o;
          break;
        }
      }
    }
    _setHover(found, offer);
    notifyListeners();
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
    super.key,
  });

  final DropOfferBuilder offer;
  final Widget child;
  final double radius;

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
                                  ? l10n.desktopDragCount(data.count)
                                  : l10n.desktopDragOffer(
                                      l10n.desktopDragCount(data.count),
                                      offer.label,
                                    ),
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
