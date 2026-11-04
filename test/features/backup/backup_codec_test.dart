import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/backup/domain/backup_codec.dart';
import 'package:kfm/features/backup/domain/backup_settings_policy.dart';

final _data = BackupData(
  createdAt: DateTime.utc(2026, 10, 29, 10),
  appVersion: '0.1.0',
  dbSchema: 23,
  settings: const {'swipe.buttonsMode': true, 'delete.mode': 'trash'},
  tags: const [BackupTag(key: 4, name: 'Holiday', color: 4283215696)],
  presets: const [
    BackupPreset(
      key: 2,
      name: 'Screenshots',
      layout: {'directions': <String, Object?>{}, 'actionBar': <Object?>[]},
      filter: null,
      includeReviewed: false,
      sortOrder: 0,
    ),
  ],
  files: [
    BackupFile(
      vol: 'int',
      rel: 'DCIM/Camera',
      name: 'IMG_1234.jpg',
      size: 3145728,
      takenAtMs: 1761730000000,
      tags: const [4],
      favorite: true,
      reviewed: [
        BackupReview(
          preset: 0,
          action: 'keep',
          detail: null,
          at: DateTime.utc(2026, 10, 20, 8),
        ),
      ],
    ),
    const BackupFile(
      vol: 'sd',
      rel: '',
      name: 'x.png',
      size: 1,
      takenAtMs: null,
    ),
  ],
);

Matcher _rejected(BackupProblem p) => throwsA(
  isA<BackupFormatException>().having((e) => e.problem, 'problem', p),
);

String _withSchema(Object? schema) {
  final j = jsonDecode(BackupCodec.encode(_data)) as Map<String, Object?>;
  return jsonEncode({...j, 'schema': schema});
}

void main() {
  test('round trip: encode then decode gives the same data', () {
    final back = BackupCodec.decode(BackupCodec.encode(_data));
    expect(BackupCodec.encode(back), BackupCodec.encode(_data));
    expect(back.files.first.reviewed.single.at, DateTime.utc(2026, 10, 20, 8));
    expect(back.files.last.takenAtMs, isNull);
    expect(back.tags.single.name, 'Holiday');
  });

  test('a newer schema is refused', () {
    expect(
      () => BackupCodec.decode(_withSchema(99)),
      _rejected(BackupProblem.tooNew),
    );
  });

  test('random or foreign JSON is refused', () {
    for (final text in [
      'not json at all',
      '[1, 2, 3]',
      '{"hello": "world"}',
      '{"format": "other-app", "schema": 1}',
      '',
    ]) {
      expect(
        () => BackupCodec.decode(text),
        _rejected(BackupProblem.notBackup),
        reason: text,
      );
    }
    expect(
      () => BackupCodec.decode(_withSchema('1')),
      _rejected(BackupProblem.notBackup),
    );
  });

  test('wrong field types are refused, not guessed', () {
    final j = jsonDecode(BackupCodec.encode(_data)) as Map<String, Object?>;
    final files = (j['files']! as List<Object?>).cast<Map<String, Object?>>();
    final bad = {
      ...j,
      'files': [
        {...files.first, 'size': '3145728'},
      ],
    };
    expect(
      () => BackupCodec.decode(jsonEncode(bad)),
      _rejected(BackupProblem.notBackup),
    );
    final badTag = {
      ...j,
      'tags': [
        {'key': 'x', 'name': 'A', 'color': 1},
      ],
    };
    expect(
      () => BackupCodec.decode(jsonEncode(badTag)),
      _rejected(BackupProblem.notBackup),
    );
  });

  test('settings policy covers every AppSettings key', () {
    final source = File('lib/core/db/settings/app_settings.dart')
        .readAsStringSync();
    final names = RegExp("static final SettingKey[^']*'([^']+)'")
        .allMatches(source)
        .map((m) => m.group(1)!)
        .toSet();
    expect(names.length, greaterThan(40), reason: 'parser found the keys');
    final exported = backupSettings.map((s) => s.name).toSet();
    expect(exported.intersection(excludedBackupSettings), isEmpty);
    final missing = names.difference({...exported, ...excludedBackupSettings});
    expect(
      missing,
      isEmpty,
      reason:
          'add each new setting to backupSettings or excludedBackupSettings',
    );
    expect(
      {...exported, ...excludedBackupSettings}.difference(names),
      isEmpty,
      reason: 'stale names',
    );
  });

  test('policy rejects values of the wrong type', () {
    final buttons = backupSettingsByName['swipe.buttonsMode']!;
    expect(buttons.canonical(true), 'true');
    expect(buttons.canonical('yes'), isNull);
    expect(
      backupSettingsByName['theme.accent']!.canonical('no-such-colour'),
      isNull,
    );
  });

  test('Q6: every truncation and many byte flips are refused cleanly', () {
    final text = BackupCodec.encode(_data);
    var accepted = 0;
    void check(String input) {
      try {
        BackupCodec.decode(input);
        accepted++;
      } on BackupFormatException {
        // Clean refusal.
      }
      // Anything else (TypeError, RangeError...) fails the test.
    }

    for (var cut = 0; cut < text.length; cut++) {
      check(text.substring(0, cut));
    }
    // Truncations are never accepted (the closing brace is missing).
    expect(accepted, 0);
    final rnd = Random(42);
    const junk = ['"', '{', '}', '[', ']', ',', ':', '0', '-', 'e', 'x', ' '];
    for (var i = 0; i < 3000; i++) {
      final at = rnd.nextInt(text.length);
      check(text.replaceRange(at, at + 1, junk[rnd.nextInt(junk.length)]));
    }
  });

  test('Q6: hand-edited values are refused, never thrown', () {
    final j = jsonDecode(BackupCodec.encode(_data)) as Map<String, Object?>;
    final files = (j['files']! as List<Object?>).cast<Map<String, Object?>>();
    for (final edit in <Map<String, Object?>>[
      {'size': -1},
      {'size': 1.5},
      {'size': null},
      {'name': ''},
      {'name': 12},
      {'tags': 'Holiday'},
      {'tags': <Object?>[null]},
      {'reviewed': <Object?>[<String, Object?>{}]},
      {'takenAt': 'yesterday'},
    ]) {
      final bad = {
        ...j,
        'files': [
          {...files.first, ...edit},
        ],
      };
      try {
        BackupCodec.decode(jsonEncode(bad));
      } on BackupFormatException {
        // Refused.
      }
    }
    // Deep nesting doesn't overflow the stack.
    final deep = '${'[' * 100000}${']' * 100000}';
    expect(() => BackupCodec.decode(deep), _rejected(BackupProblem.notBackup));
  });
}
