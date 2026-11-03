import 'dart:async';

import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// One tray menu entry: [key] comes back through [DesktopShell.trayClicks].
@immutable
class TrayMenuEntry {
  const new(this.key, this.label);

  final String key;
  final String label;
}

/// The Windows window and tray icon (TASK-PL1), UI-agnostic: the close
/// flow and the sharing tray talk to this, so a desktop UI can reuse them.
/// Tests use a fake.
abstract interface class DesktopShell {
  /// The user closed the window (title bar ✕, Alt+F4). Closing is always
  /// intercepted; the listener decides between [hide] and [quit].
  Stream<void> get closeRequests;

  /// A tray menu entry's key.
  Stream<String> get trayClicks;

  Future<void> hide();

  /// Brings the window back (from the tray or behind other windows).
  Future<void> showAndFocus();

  /// Ends the app (the tray icon goes with it).
  Future<void> quit();

  /// Shows (or updates) the tray icon.
  Future<void> showTray({
    required String tooltip,
    required List<TrayMenuEntry> menu,
  });

  Future<void> removeTray();

  /// The window's bounds (logical pixels), for remembering them (PL3).
  Future<Rect> bounds();

  Future<void> setBounds(Rect bounds);

  /// The user moved or resized the window.
  Stream<void> get boundsChanges;
}

/// window_manager + tray_manager. [init] once in `main` before `runApp`.
class WindowsDesktopShell
    with WindowListener, TrayListener
    implements DesktopShell {
  new();

  /// The tray icon: KFM's icon with a green "sharing" dot (Flutter asset).
  static const trayIconAsset = 'assets/windows/tray_sharing.ico';

  final StreamController<void> _close = StreamController.broadcast();
  final StreamController<String> _clicks = StreamController.broadcast();
  final StreamController<void> _bounds = StreamController.broadcast();
  bool _trayShown = false;

  /// Intercepts closing. The native runner keeps size, title and minimum
  /// size (`flutter_window.cpp`), so window_manager only does close/hide.
  Future<void> init() async {
    await windowManager.ensureInitialized();
    windowManager.addListener(this);
    trayManager.addListener(this);
    await windowManager.setPreventClose(true);
  }

  @override
  Stream<void> get closeRequests => _close.stream;

  @override
  Stream<String> get trayClicks => _clicks.stream;

  @override
  void onWindowClose() => _close.add(null);

  @override
  void onWindowMoved() => _bounds.add(null);

  @override
  void onWindowResized() => _bounds.add(null);

  @override
  Stream<void> get boundsChanges => _bounds.stream;

  @override
  Future<Rect> bounds() => windowManager.getBounds();

  @override
  Future<void> setBounds(Rect bounds) => windowManager.setBounds(bounds);

  @override
  void onTrayIconMouseDown() => _clicks.add(trayOpenKey);

  @override
  void onTrayIconRightMouseDown() => trayManager.popUpContextMenu().ignore();

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    final key = menuItem.key;
    if (key != null) _clicks.add(key);
  }

  @override
  Future<void> hide() => windowManager.hide();

  @override
  Future<void> showAndFocus() async {
    await windowManager.show();
    if (await windowManager.isMinimized()) await windowManager.restore();
    await windowManager.focus();
  }

  @override
  Future<void> quit() async {
    await removeTray();
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }

  @override
  Future<void> showTray({
    required String tooltip,
    required List<TrayMenuEntry> menu,
  }) async {
    if (!_trayShown) {
      await trayManager.setIcon(trayIconAsset);
      _trayShown = true;
    }
    await trayManager.setToolTip(tooltip);
    await trayManager.setContextMenu(
      Menu(
        items: [for (final e in menu) MenuItem(key: e.key, label: e.label)],
      ),
    );
  }

  @override
  Future<void> removeTray() async {
    if (!_trayShown) return;
    _trayShown = false;
    await trayManager.destroy();
  }
}

/// Tray menu keys (a left click on the icon counts as [trayOpenKey]).
const trayStopSharingKey = 'stopSharing';
const trayOpenKey = 'open';
const trayQuitKey = 'quit';
