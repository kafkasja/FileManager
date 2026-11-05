import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/db/settings/setting_key.dart';
import 'package:kfm/core/index/index_providers.dart';

import '../helpers/pump_app.dart';

/// Every `AppSettings` key name (parsed like the X6 policy test does).
Set<String> _allKeyNames() {
  final source = File('lib/core/db/settings/app_settings.dart')
      .readAsStringSync();
  return RegExp("static final SettingKey[^']*'([^']+)'")
      .allMatches(source)
      .map((m) => m.group(1)!)
      .toSet();
}

/// Q6: a damaged or hand-edited `settings` table.
const _garbage = <String>[
  'not json at all',
  '',
  'null',
  '"\u0000weird 🙂 \u202e"',
  '-9223372036854775808',
  '9223372036854775807',
  '1e999',
  '-1',
  '0',
  '{"a": [1, {"b": null}]}',
  r'"{\"broken json"',
  '"[1, 2"',
  '"9999-99-99T99:99:99Z"',
  '"-1,-1,NaN,Infinity"',
  '[]',
  'true',
];

void main() {
  final names = _allKeyNames();

  test('the key parser finds the settings', () {
    expect(names.length, greaterThan(50));
  });

  test('reading any setting with a garbage row never throws', () {
    // Every declared key decodes every garbage value to some value.
    final keys = <SettingKey<Object>>[
      AppSettings.themeMode,
      AppSettings.themeAccent,
      AppSettings.textSize,
      AppSettings.externalSafGrants,
      AppSettings.onboardingSeenHints,
      AppSettings.windowsIndexRoots,
      AppSettings.browseSortField,
      AppSettings.foldersDropAction,
      AppSettings.thumbCacheMaxMb,
      AppSettings.leftHanded,
    ];
    for (final key in keys) {
      for (final raw in _garbage) {
        expect(() => key.decodeFromDb(raw), returnsNormally, reason: raw);
      }
    }
  });

  test('thumbnail cache cap stays sane for garbage MB values', () {
    expect(thumbCacheCapBytes(300), 300 * 1024 * 1024);
    for (final mb in [-1, 0, 1 << 62, -(1 << 62), 9223372036854775807]) {
      final cap = thumbCacheCapBytes(mb);
      expect(cap, greaterThanOrEqualTo(16 * 1024 * 1024), reason: '$mb');
      expect(cap, lessThanOrEqualTo(1 << 40), reason: '$mb');
    }
  });

  for (final (i, raw) in _garbage.indexed) {
    testWidgets('app starts and every tab opens with all settings = '
        'garbage #$i', (tester) async {
      final app = await pumpApp(
        tester,
        seedDb: (db) async {
          await db.batch((b) {
            b.insertAll(db.settings, [
              for (final name in names)
                // Keep the tutorial away so the tabs are reachable.
                if (name != AppSettings.onboardingTutorialDone.name)
                  SettingRow(key: name, value: raw),
            ], mode: InsertMode.insertOrReplace);
          });
        },
      );
      for (final tab in ['Browse', 'Trash', 'Settings', 'Swipe']) {
        await tester.tap(find.text(tab).last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$tab, garbage $raw');
      }
      // The settings repository still writes over the garbage.
      await app.container
          .read(settingsRepositoryProvider)
          .write(AppSettings.themeMode, 'dark');
      expect(
        await app.container
            .read(settingsRepositoryProvider)
            .read(AppSettings.themeMode),
        'dark',
      );
    });
  }
}
