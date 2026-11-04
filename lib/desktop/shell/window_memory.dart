import 'dart:async';
import 'dart:ui';

import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/db/settings/settings_repository.dart';
import 'package:kfm/core/platform/windows/desktop_shell.dart';

/// Remembers the desktop window's size and position (TASK-PL3 polish):
/// restores the last bounds at start and saves them shortly after the user
/// moves or resizes the window.
class WindowMemory {
  new(this._shell, this._settings);

  final DesktopShell _shell;
  final SettingsRepository _settings;
  StreamSubscription<void>? _sub;
  Timer? _debounce;

  /// Smallest window the runner allows (`flutter_window.cpp`).
  static const minWidth = 800.0;
  static const minHeight = 600.0;

  /// Larger saved positions or sizes are treated as garbage.
  static const maxCoordinate = 100000.0;

  Future<void> start() async {
    final raw = await _settings.read(AppSettings.desktopWindowBounds);
    final saved = parse(raw);
    if (saved != null) await _shell.setBounds(saved);
    _sub = _shell.boundsChanges.listen((_) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 600), () async {
        final b = await _shell.bounds();
        _settings
            .write(AppSettings.desktopWindowBounds, format(b))
            .fireAndForget();
      });
    });
  }

  void dispose() {
    _debounce?.cancel();
    unawaited(_sub?.cancel());
  }

  static String format(Rect b) =>
      [b.left, b.top, b.width, b.height].map((v) => v.round()).join(',');

  /// Null for nothing saved, garbage, a too-small window or one far
  /// off-screen (a monitor that is gone).
  static Rect? parse(String raw) {
    final parts = raw.split(',').map(double.tryParse).toList();
    if (parts.length != 4 || parts.any((p) => p == null)) return null;
    final [x!, y!, w!, h!] = parts;
    // Q6: NaN/Infinity or absurd sizes (a damaged or hand-edited row) never
    // reach the window manager.
    if (![x, y, w, h].every((v) => v.isFinite && v.abs() <= maxCoordinate)) {
      return null;
    }
    if (w < minWidth || h < minHeight || x < -200 || y < -50) return null;
    return Rect.fromLTWH(x, y, w, h);
  }
}
