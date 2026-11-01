import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/source_rule.dart';
import 'package:kfm/features/details/domain/known_files.dart';
import 'package:kfm/features/details/domain/path_app.dart';

KnownFiles _asset() => KnownFiles.parse(
  File('assets/details/known_files_en.json').readAsStringSync(),
);

KnownApps _apps() =>
    KnownApps.parse(File('assets/details/known_apps.json').readAsStringSync());

String? _kind(KnownFiles k, String path) {
  final rel = volumeRelative(path.substring(0, path.lastIndexOf('/')));
  return k.match(rel, path.substring(path.lastIndexOf('/') + 1))?.id;
}

const _wa = '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp';

void main() {
  group('globToRegExp', () {
    test('* stays inside one segment, **/ spans segments', () {
      expect(globToRegExp('a/*').hasMatch('a/b'), isTrue);
      expect(globToRegExp('a/*').hasMatch('a/b/c'), isFalse);
      expect(globToRegExp('**/x').hasMatch('x'), isTrue);
      expect(globToRegExp('**/x').hasMatch('a/b/x'), isTrue);
      expect(globToRegExp('**/x').hasMatch('a/bx'), isFalse);
      expect(
        globToRegExp('msgstore*.db.crypt*')
            .hasMatch('msgstore-2026-10-31.1.db.crypt14'),
        isTrue,
      );
      expect(globToRegExp('a.b').hasMatch('axb'), isFalse);
      expect(globToRegExp('?.txt').hasMatch('a.txt'), isTrue);
    });
  });

  group('matcher priority', () {
    final k = KnownFiles.parse(
      jsonEncode({
        'extensions': {'tmp': 'ext', 'crypt14': 'ext'},
        'names': [
          {'glob': 'special.tmp', 'kind': 'name'},
          {'glob': '*.crypt14', 'in': '**/stickers', 'kind': 'nameIn'},
        ],
        'folders': [
          {'glob': '**/backups', 'kind': 'shallow'},
          {'glob': '**/backups/deep', 'kind': 'deep'},
        ],
        'kinds': {
          for (final id in ['ext', 'name', 'nameIn', 'shallow', 'deep'])
            id: {'title': id, 'body': id, 'deletable': 'usually'},
        },
      }),
    );

    test('names > folders > extensions', () {
      expect(k.match('backups', 'special.tmp')?.id, 'name');
      expect(k.match('backups', 'other.tmp')?.id, 'shallow');
      expect(k.match('music', 'other.tmp')?.id, 'ext');
      expect(k.match('music', 'other.txt'), isNull);
    });

    test('the deepest matching folder wins, also for files deeper down', () {
      expect(k.match('a/backups/deep/x/y', 'f.bin')?.id, 'deep');
      expect(k.match('a/backups/other', 'f.bin')?.id, 'shallow');
    });

    test('a names rule with `in` needs that folder', () {
      expect(k.match('a/stickers/x', 'q.crypt14')?.id, 'nameIn');
      expect(k.match('a/other', 'q.crypt14')?.id, 'ext');
    });

    test('case-insensitive; a dot-file has no extension', () {
      expect(k.match('A/BACKUPS', 'X.TMP')?.id, 'shallow');
      expect(k.match('music', '.tmp'), isNull);
    });
  });

  group('the shipped table', () {
    final k = _asset();

    test('every referenced kind exists with a title and body; no "safe"', () {
      for (final id in k.referencedKinds) {
        expect(k.kinds, contains(id), reason: id);
      }
      for (final kind in k.kinds.values) {
        expect(kind.title.trim(), isNotEmpty, reason: kind.id);
        expect(kind.body.trim(), isNotEmpty, reason: kind.id);
        expect(
          '${kind.title} ${kind.body}'.toLowerCase(),
          isNot(contains('safe')),
          reason: '${kind.id}: never call a file safe to delete',
        );
      }
      final raw = jsonDecode(
        File('assets/details/known_files_en.json').readAsStringSync(),
      ) as Map<String, Object?>;
      for (final kind in (raw['kinds']! as Map<String, Object?>).values) {
        expect(
          DeletableHint.values.map((h) => h.name),
          contains((kind! as Map<String, Object?>)['deletable']),
        );
      }
      final entries = k.extensions.length + k.names.length + k.folders.length;
      expect(entries, greaterThanOrEqualTo(80));
    });

    test('S22 must-haves (2026-11-01)', () {
      expect(
        _kind(k, '$_wa/Backups/Stickers/AbC/tHXZq4Vwsz+idGdjU4klUwvh.crypt14'),
        'whatsappStickerBackup',
      );
      expect(
        _kind(k, '$_wa/Backups/chatsettingsbackup.db.crypt14'),
        'whatsappSettingsBackup',
      );
      expect(
        _kind(k, '$_wa/Backups/wallpapers.backup.crypt14'),
        'whatsappSettingsBackup',
      );
      expect(
        _kind(k, '$_wa/Databases/msgstore-2026-10-30.1.db.crypt14'),
        'whatsappChats',
      );
      expect(_kind(k, '$_wa/Databases/msgstore.db.crypt14'), 'whatsappChats');
      expect(_kind(k, '$_wa/.Shared/IFY2-0MUs8Hx.tmp'), 'whatsappScratch');
      expect(_kind(k, '$_wa/Media/WhatsApp Images/Sent/.nomedia'), 'nomedia');
      expect(
        _kind(k, '$_wa/Media/WhatsApp Images/Private/.nomedia'),
        'nomedia',
      );
      expect(
        _kind(k, '$_wa/Media/WhatsApp Voice Notes/202644/.nomedia'),
        'nomedia',
      );
      expect(
        _kind(k, '$_wa/Media/WhatsApp Voice Notes/202644/PTT-1.opus'),
        'whatsappVoiceNotes',
      );
      expect(_kind(k, '$_wa/Media/.Statuses/abc.jpg'), 'whatsappStatus');
      expect(_kind(k, '$_wa/Media/WhatsApp Images/IMG-1.jpg'), 'whatsappMedia');
      expect(
        _kind(k, '/storage/emulated/0/Music/.thumbnails/123.jpg'),
        'thumbCache',
      );
      expect(
        _kind(
          k,
          '/storage/emulated/0/Android/media/org.telegram.messenger/'
          'Telegram/Telegram Images/1.jpg',
        ),
        'telegramMedia',
      );
      expect(
        _kind(
          k,
          '/storage/emulated/0/Android/data/org.telegram.messenger/cache/a.jpg',
        ),
        'telegramCache',
      );
      expect(
        _kind(
          k,
          '/storage/emulated/0/Android/data/com.game/files/.MBridge_VC/v',
        ),
        'adVideoCache',
      );
      expect(
        _kind(
          k,
          '/storage/emulated/0/Android/data/com.game/files/UnityAdsCache/1',
        ),
        'adVideoCache',
      );
      expect(
        _kind(k, '/storage/emulated/0/DCIM/Camera/.trashed-1-a.jpg'),
        'systemTrashed',
      );
      expect(
        _kind(k, '/storage/emulated/0/DCIM/Camera/.pending-1-a.jpg'),
        'systemPending',
      );
      expect(_kind(k, '/storage/emulated/0/.KFMTrash/a.pdf'), 'kfmTrash');
      expect(_kind(k, '/storage/emulated/0/Download/x.apk'), 'apk');
      expect(
        _kind(k, '/storage/emulated/0/Download/x.crypt15'),
        'whatsappBackup',
      );
    });

    test('ordinary files get no explanation (conservative)', () {
      expect(_kind(k, '/storage/emulated/0/DCIM/Camera/IMG_1.jpg'), isNull);
      expect(_kind(k, '/storage/emulated/0/Documents/a.pdf'), isNull);
      expect(_kind(k, '/storage/emulated/0/Download/x.xyz'), isNull);
    });
  });

  group('path app', () {
    final apps = _apps();
    FileRef f(String folder, String name, [FileKind kind = FileKind.other]) =>
        FileRef(
          id: 'path:$folder/$name',
          uri: '$folder/$name',
          name: name,
          kind: kind,
          sizeBytes: 1,
          modifiedAt: DateTime.utc(2026),
          folderPath: folder,
          origin: FileOrigin.local,
        );

    test('Android/{media,data,obb}/<pkg> names the package', () {
      expect(
        packageFromFolder('android/media/com.whatsapp/whatsapp/backups'),
        'com.whatsapp',
      );
      expect(packageFromFolder('android/data/com.game.x'), 'com.game.x');
      expect(packageFromFolder('android/obb/com.game.x/y'), 'com.game.x');
      expect(packageFromFolder('android/media'), isNull);
      expect(packageFromFolder('android/data/.nomedia'), isNull);
      expect(packageFromFolder('dcim/camera'), isNull);
      expect(
        pathAppFor(f('$_wa/Backups/Stickers/x', 'a.crypt14'), apps),
        const PathApp(packageName: 'com.whatsapp'),
      );
    });

    test('else the source bucket and its usual app', () {
      expect(
        pathAppFor(
          f(
            '/storage/emulated/0/WhatsApp/Media/WhatsApp Images',
            'a.jpg',
            FileKind.image,
          ),
          apps,
        ),
        const PathApp(
          packageName: 'com.whatsapp',
          bucket: SourceBucket.whatsapp,
        ),
      );
      expect(
        pathAppFor(
          f('/storage/emulated/0/DCIM/Camera', 'a.jpg', FileKind.image),
          apps,
        ),
        const PathApp(bucket: SourceBucket.camera),
      );
      expect(
        pathAppFor(f('/storage/emulated/0/Documents', 'a.pdf'), apps),
        isNull,
      );
    });

    test('known_apps.json parses, buckets are real', () {
      expect(apps.names['com.whatsapp'], 'WhatsApp');
      expect(
        apps.bucketPackages[SourceBucket.telegram],
        'org.telegram.messenger',
      );
      expect(apps.names.length, greaterThanOrEqualTo(40));
    });
  });
}
