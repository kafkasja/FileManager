import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/desktop/widgets/desktop_keys.dart';

/// Round 7 / TASK-E3: no keyboard-only actions. Every `DesktopKeys` key is
/// shown on a button tooltip, a command or a menu entry somewhere in the
/// desktop UI (`DesktopKeys.label(DesktopKeys.x)` or `keys(DesktopKeys.x)`),
/// except documented alternates of a shown key.
void main() {
  test('every desktop shortcut is shown on a button or menu entry', () {
    final source = File('lib/desktop/widgets/desktop_keys.dart')
        .readAsStringSync();
    final names = [
      for (final m in RegExp(
        r'static const (\w+) = SingleActivator',
      ).allMatches(source))
        m[1]!,
    ];
    expect(names, isNotEmpty);
    final ui = [
      for (final dir in ['lib/desktop', 'lib/features'])
        for (final f in Directory(dir).listSync(recursive: true))
          if (f is File &&
              f.path.endsWith('.dart') &&
              !f.path.endsWith('.g.dart') &&
              !f.path
                  .replaceAll(r'\', '/')
                  .endsWith('widgets/desktop_keys.dart'))
            f.readAsStringSync(),
    ].join('\n');
    bool shown(String name) =>
        RegExp('(label|keys)\\(\\s*DesktopKeys\\.$name\\s*\\)').hasMatch(ui);
    final missing = <String>[];
    for (final name in names) {
      if (DesktopKeys.shownDynamically.contains(name)) continue;
      final primary = DesktopKeys.alternates[name];
      if (primary != null) {
        expect(names, contains(primary), reason: '$name → $primary');
        if (!shown(primary)) missing.add('$name (via $primary)');
        continue;
      }
      if (!shown(name)) missing.add(name);
    }
    expect(missing, isEmpty, reason: 'keys without a visible button/menu');
  });
}
