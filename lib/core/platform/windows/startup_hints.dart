import 'dart:io';
import 'dart:ui';

import 'package:path/path.dart' as p;

/// What the next start needs before the Flutter engine runs (Windows speed
/// fix): the window's bounds and the app's background colour. The native
/// runner reads this file and shows the window at once, in place and in
/// colour, while the engine starts (`windows/runner/startup_hints.cpp`).
///
/// One small text file in the app support folder:
/// `bounds=<x>,<y>,<w>,<h>` (logical pixels) and `background=<RRGGBB>`.
class StartupHintsFile {
  new(this._folder);

  /// The app support folder (the runner derives the same one).
  final Future<String> Function() _folder;

  static const fileName = 'window_state.txt';

  Rect? _bounds;
  Color? _background;
  bool _loaded = false;
  Future<void> _last = Future.value();

  Future<File> _file() async => File(p.join(await _folder(), fileName));

  /// Merges [bounds] / [background] into the file (rewritten only when
  /// something changed). Never throws: a missing hint only costs speed.
  /// Calls run one after another.
  Future<void> update({Rect? bounds, Color? background}) =>
      _last = _last.then((_) => _update(bounds, background));

  Future<void> _update(Rect? bounds, Color? background) async {
    try {
      final file = await _file();
      if (!_loaded) {
        _loaded = true;
        final known = parse(file.existsSync() ? await file.readAsString() : '');
        _bounds = known.bounds;
        _background = known.background;
      }
      final nextBounds = bounds ?? _bounds;
      final nextBackground = background ?? _background;
      if (nextBounds == _bounds &&
          nextBackground?.toARGB32() == _background?.toARGB32() &&
          file.existsSync()) {
        return;
      }
      _bounds = nextBounds;
      _background = nextBackground;
      await file.writeAsString(
        format(bounds: nextBounds, background: nextBackground),
        flush: true,
      );
    } on Object {
      // Read-only or missing folder: the window just shows later.
    }
  }

  static String format({Rect? bounds, Color? background}) {
    final b = StringBuffer();
    if (bounds != null) {
      b.writeln(
        'bounds=${[bounds.left, bounds.top, bounds.width, bounds.height].map((v) => v.round()).join(',')}',
      );
    }
    if (background != null) {
      final rgb = background.toARGB32() & 0xFFFFFF;
      b.writeln(
        'background=${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}',
      );
    }
    return b.toString();
  }

  static ({Rect? bounds, Color? background}) parse(String text) {
    Rect? bounds;
    Color? background;
    for (final line in text.split('\n').map((l) => l.trim())) {
      if (line.startsWith('bounds=')) {
        final v = line.substring(7).split(',').map(int.tryParse).toList();
        if (v.length == 4 && v.every((x) => x != null)) {
          bounds = Rect.fromLTWH(
            v[0]!.toDouble(),
            v[1]!.toDouble(),
            v[2]!.toDouble(),
            v[3]!.toDouble(),
          );
        }
      } else if (line.startsWith('background=') && line.length == 17) {
        final rgb = int.tryParse(line.substring(11), radix: 16);
        if (rgb != null) background = Color(0xFF000000 | rgb);
      }
    }
    return (bounds: bounds, background: background);
  }
}
