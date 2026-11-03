import 'dart:async';

import 'package:flutter/services.dart';
import 'package:kfm/core/platform/windows/windows_channel.dart';

/// What the native drop target reports (TASK-PL3 step 4). Each callback
/// that returns a bool answers "does the target under the pointer take
/// these files?" (Windows shows the copy cursor or the no-drop cursor).
abstract interface class ExplorerDropListener {
  bool onDragEnter(Offset position, List<String> paths);
  bool onDragOver(Offset position);
  void onDragLeave();
  Future<void> onDrop(Offset position, List<String> paths);
}

/// Dart side of the method channel `com.kaf.kfm/dragdrop`
/// (`windows/runner/drag_drop.cpp`, registered in `flutter_window.cpp`).
///
/// Native → Dart (OLE `IDropTarget` on the Flutter view; only CF_HDROP
/// file drags; positions are logical client coordinates):
/// - `dragEnter {x, y, paths: [String]}` → bool
/// - `dragOver {x, y}` → bool
/// - `dragLeave` → null
/// - `drop {x, y, paths}` → null (the effect is always copy)
///
/// Dart → native:
/// - `startDrag {paths: [String]}` → bool started: `SHCreateDataObject`
///   over the files' absolute PIDLs + `SHDoDragDrop` with
///   `DROPEFFECT_COPY` only, posted to the window procedure (the mouse
///   button is still down). Completes when the drag is over; afterwards the
///   view gets a synthetic `WM_LBUTTONUP` (OLE swallowed the real one).
///   Drops on KFM's own window are ignored while it runs.
///
/// Paths are '/'-separated on the Dart side.
class WindowsDragDrop {
  new({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(name);

  static const name = 'com.kaf.kfm/dragdrop';

  final MethodChannel _channel;

  /// Starts a drag of [paths] out of KFM. False when nothing was dragged.
  Future<bool> startDrag(List<String> paths) async {
    try {
      return await _channel.invokeMethod<bool>('startDrag', {
            'paths': [for (final p in paths) WindowsChannel.toNative(p)],
          }) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Routes the native drop target's events to [listener] (null = stop).
  void listen(ExplorerDropListener? listener) {
    if (listener == null) {
      _channel.setMethodCallHandler(null);
      return;
    }
    _channel.setMethodCallHandler((call) async {
      final args = call.arguments is Map<Object?, Object?>
          ? call.arguments as Map<Object?, Object?>
          : const <Object?, Object?>{};
      final at = Offset(
        (args['x'] as num?)?.toDouble() ?? 0,
        (args['y'] as num?)?.toDouble() ?? 0,
      );
      final paths = [
        for (final p in (args['paths'] as List<Object?>?) ?? const [])
          if (p is String) WindowsChannel.fromNative(p),
      ];
      switch (call.method) {
        case 'dragEnter':
          return listener.onDragEnter(at, paths);
        case 'dragOver':
          return listener.onDragOver(at);
        case 'dragLeave':
          listener.onDragLeave();
          return null;
        case 'drop':
          unawaited(listener.onDrop(at, paths));
          return null;
      }
      return null;
    });
  }
}
