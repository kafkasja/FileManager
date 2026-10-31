import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'file_drag.g.dart';

/// A drag of the selection towards a folder (TASK-B4 §11).
@immutable
class FileDragState {
  const new({required this.count, this.hover});

  /// Files being dragged (the whole selection).
  final int count;

  /// The folder under the finger, if any.
  final String? hover;
}

/// The running drag (null = none). B6's `SelectableFile` starts it with a
/// long-press on an already-selected tile in Select mode; folder rows
/// ([FolderDropTarget]) highlight while hovered.
@Riverpod(keepAlive: true)
class FileDrag extends _$FileDrag {
  @override
  FileDragState? build() => null;

  void start(int count) => state = FileDragState(count: count);

  void hover(String? folder) {
    final s = state;
    if (s == null || s.hover == folder) return;
    state = FileDragState(count: s.count, hover: folder);
  }

  /// Ends the drag; returns the folder it was released on (null = cancel).
  String? end() {
    final folder = state?.hover;
    state = null;
    return folder;
  }
}

/// Marks a folder row for [folderAt] hit tests.
@immutable
class FolderDropData {
  const new(this.folder);

  final String folder;
}

/// A folder row that takes dropped files; highlighted while hovered.
class FolderDropTarget extends ConsumerWidget {
  const new({required this.folder, required this.child, super.key});

  final String folder;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hovered = ref.watch(
      fileDragProvider.select((s) => s?.hover == folder),
    );
    return MetaData(
      metaData: FolderDropData(folder),
      behavior: HitTestBehavior.translucent,
      // A Material, so the ListTile's ink still shows.
      child: Material(
        color: hovered
            ? Theme.of(context).colorScheme.primaryContainer
            : Colors.transparent,
        child: child,
      ),
    );
  }
}

/// The drop folder under the global position [global], if any.
String? folderAt(BuildContext context, Offset global) {
  final result = HitTestResult();
  WidgetsBinding.instance.hitTestInView(
    result,
    global,
    View.of(context).viewId,
  );
  for (final entry in result.path) {
    if (entry.target case RenderMetaData(metaData: final FolderDropData d)) {
      return d.folder;
    }
  }
  return null;
}

/// The "12 files" badge that follows the finger during a drag.
class FileDragFeedback {
  new(BuildContext context, this._position, int count)
    : _overlay = Overlay.of(context, rootOverlay: true) {
    _entry = OverlayEntry(
      builder: (context) {
        final box = _overlay.context.findRenderObject();
        final local = box is RenderBox
            ? box.globalToLocal(_position)
            : _position;
        return Positioned(
          left: local.dx - 28,
          top: local.dy - 72,
          child: IgnorePointer(child: _Badge(count: count)),
        );
      },
    );
    _overlay.insert(_entry);
  }

  final OverlayState _overlay;
  late final OverlayEntry _entry;
  Offset _position;

  void moveTo(Offset global) {
    _position = global;
    _entry.markNeedsBuild();
  }

  void remove() {
    if (_entry.mounted) _entry.remove();
    _entry.dispose();
  }
}

class _Badge extends StatelessWidget {
  const new({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 6,
      color: scheme.primaryContainer,
      shape: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(14),
        child: Badge.count(
          count: count,
          child: Icon(
            Icons.drive_file_move_outlined,
            color: scheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}
