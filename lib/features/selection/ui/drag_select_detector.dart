import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/folders/ui/file_drag.dart';
import 'package:kfm/features/folders/ui/file_op_flow.dart';
import 'package:kfm/features/selection/domain/selection_state.dart';
import 'package:kfm/features/selection/ui/selection_controller.dart';

/// Marks a tile for drag selection hit tests: its place in [items].
@immutable
class DragSelectTarget {
  const new(this.index, this.items);

  final int index;
  final List<FileRef> items;
}

/// A file tile that follows the selection rules (TASK-B6): Normal = open,
/// Select = add only (tapping a selected tile pulses), Edit = remove only.
/// Long-press enters Select mode; keep holding and drag to add the whole
/// range from the first tile (add-only in both directions). B7: in Select
/// and Edit mode a ⤢ button opens [onPreview] (the tile tap selects).
/// B4: in Select mode a long-press on an already-selected tile drags the
/// whole selection onto a folder row (`FolderDropTarget`) instead.
class SelectableFile extends ConsumerStatefulWidget {
  const new({
    required this.index,
    required this.items,
    required this.onOpen,
    required this.builder,
    this.onPreview,
    this.listRow = false,
    super.key,
  });

  final int index;
  final List<FileRef> items;
  final VoidCallback onOpen;

  /// Fullscreen preview without changing the selection (B7).
  final VoidCallback? onPreview;

  /// A list row: ⤢ sits centered at the end instead of the top-start.
  final bool listRow;

  /// The tile; `onTap` is null when a tap does nothing (Edit mode,
  /// unselected).
  final Widget Function(BuildContext context, VoidCallback? onTap) builder;

  @override
  ConsumerState<SelectableFile> createState() => _SelectableFileState();
}

class _SelectableFileState extends ConsumerState<SelectableFile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  int? _anchor;

  /// B4: a selection drag is running.
  FileDragFeedback? _feedback;
  FileDrag? _drag;

  FileRef get _file => widget.items[widget.index];

  SelectionController get _controller =>
      ref.read(selectionControllerProvider.notifier);

  @override
  void dispose() {
    if (_feedback != null) {
      _feedback?.remove();
      final drag = _drag;
      // Not while the tree is being torn down.
      if (drag != null) scheduleMicrotask(drag.end);
    }
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final file = _file;
    final (mode, selected) = ref.watch(
      selectionControllerProvider.select(
        (s) => (
          s.value?.mode ?? SelectionMode.normal,
          s.value?.contains(file.id) ?? false,
        ),
      ),
    );
    final scheme = Theme.of(context).colorScheme;
    final spacing = context.tokens.spacing;
    final editing = mode == SelectionMode.edit;
    final onTap = switch (mode) {
      SelectionMode.normal => widget.onOpen,
      SelectionMode.select => _addOrPulse,
      SelectionMode.edit => selected ? _remove : null,
    };

    return MetaData(
      metaData: DragSelectTarget(widget.index, widget.items),
      behavior: HitTestBehavior.translucent,
      child: GestureDetector(
        onLongPressStart: editing ? null : _longPressStart,
        onLongPressMoveUpdate: editing ? null : _longPressMove,
        onLongPressEnd: editing ? null : (_) => _longPressEnd(drop: true),
        onLongPressCancel: editing ? null : () => _longPressEnd(drop: false),
        child: Semantics(
          selected: selected,
          child: ScaleTransition(
            scale: TweenSequence<double>([
              TweenSequenceItem(
                tween: Tween<double>(begin: 1, end: 0.9),
                weight: 1,
              ),
              TweenSequenceItem(
                tween: Tween<double>(begin: 0.9, end: 1),
                weight: 1,
              ),
            ]).animate(_pulse),
            child: Stack(
              children: [
                widget.builder(context, onTap),
                if (selected || editing)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ColoredBox(
                        color: selected
                            ? scheme.primary.withValues(alpha: 0.3)
                            : scheme.surface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                if (selected)
                  PositionedDirectional(
                    top: spacing / 2,
                    end: spacing / 2,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: editing ? scheme.error : scheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          editing ? Icons.remove : Icons.check,
                          size: 20,
                          color: editing ? scheme.onError : scheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                if (mode != SelectionMode.normal && widget.onPreview != null)
                  PositionedDirectional(
                    top: 0,
                    bottom: widget.listRow ? 0 : null,
                    start: widget.listRow ? null : 0,
                    end: widget.listRow ? spacing * 4 : null,
                    child: _PreviewButton(onPressed: widget.onPreview!),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addOrPulse() {
    if (_controller.add(_file)) return;
    unawaited(HapticFeedback.lightImpact());
    _pulse.forward(from: 0);
    unawaited(_maybeTip());
  }

  Future<void> _maybeTip() async {
    final messenger = ScaffoldMessenger.of(context);
    final tip = context.l10n.selectionTip;
    if (!await _controller.takeTip()) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(tip)));
  }

  void _remove() {
    final controller = _controller..remove(_file);
    final l10n = context.l10n;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.selectionRemoved),
          persist: false,
          action: SnackBarAction(
            label: l10n.undoAction,
            onPressed: controller.undoRemove,
          ),
        ),
      );
  }

  void _longPressStart(LongPressStartDetails details) {
    final s = ref.read(selectionControllerProvider).value;
    if (s != null &&
        s.mode == SelectionMode.select &&
        s.contains(_file.id) &&
        s.count > 0) {
      _startFileDrag(details.globalPosition, s.count);
    } else {
      _startDrag();
    }
  }

  void _longPressMove(LongPressMoveUpdateDetails details) {
    final feedback = _feedback;
    if (feedback == null) {
      _dragTo(details);
      return;
    }
    feedback.moveTo(details.globalPosition);
    _drag?.hover(folderAt(context, details.globalPosition));
  }

  void _longPressEnd({required bool drop}) {
    _anchor = null;
    final feedback = _feedback;
    if (feedback == null) return;
    feedback.remove();
    _feedback = null;
    final folder = _drag?.end();
    _drag = null;
    // Released outside a folder = cancel; the selection stays.
    if (drop && folder != null) {
      unawaited(dropSelectionOnFolder(context, ref, folder));
    }
  }

  void _startFileDrag(Offset position, int count) {
    unawaited(HapticFeedback.mediumImpact());
    final drag = ref.read(fileDragProvider.notifier)..start(count);
    _drag = drag;
    _feedback = FileDragFeedback(context, position, count);
  }

  void _startDrag() {
    unawaited(HapticFeedback.selectionClick());
    _anchor = widget.index;
    _controller
      ..enterSelect()
      ..add(_file);
  }

  /// Adds every tile between the anchor and the one under the finger.
  void _dragTo(LongPressMoveUpdateDetails details) {
    final anchor = _anchor;
    if (anchor == null) return;
    final result = HitTestResult();
    WidgetsBinding.instance.hitTestInView(
      result,
      details.globalPosition,
      View.of(context).viewId,
    );
    for (final entry in result.path) {
      if (entry.target case RenderMetaData(
        metaData: final DragSelectTarget t,
      )) {
        final from = math.min(anchor, t.index);
        final to = math.min(math.max(anchor, t.index), t.items.length - 1);
        _controller.addAll(t.items.sublist(from, to + 1));
        return;
      }
    }
  }
}

/// ⤢ with a 44×44 dp hit area on a small dark circle.
class _PreviewButton extends StatelessWidget {
  const new({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: context.l10n.previewOpen,
    constraints: const BoxConstraints.tightFor(width: 44, height: 44),
    padding: EdgeInsets.zero,
    onPressed: onPressed,
    icon: const DecoratedBox(
      decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
      child: Padding(
        padding: EdgeInsets.all(4),
        child: Icon(Icons.open_in_full, size: 16, color: Colors.white),
      ),
    ),
  );
}
