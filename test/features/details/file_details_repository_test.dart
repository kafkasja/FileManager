import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/files/android/files_channel.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/details/data/file_details_repository.dart';
import 'package:kfm/features/details/domain/file_details.dart';
import 'package:kfm/features/details/domain/known_files.dart';
import 'package:kfm/features/details/domain/path_app.dart';

/// Scriptable [DetailsPlatform] for B10 tests.
class FakeDetailsPlatform implements DetailsPlatform {
  MediaRow row = {'exists': true};
  Map<String, MediaRow> apps = {};
  MediaRow? exifRow;
  Exception? exifError;
  Exception? detailsError;
  bool hangDetails = false;
  List<MediaRow> volumes = [
    {'path': '/storage/emulated/0', 'primary': true, 'removable': false},
    {
      'path': '/storage/1A2B-3C4D',
      'label': 'SanDisk SD card',
      'primary': false,
      'removable': true,
    },
  ];
  final List<String> openedAppInfo = [];
  final List<({String path, int? id})> detailCalls = [];
  final List<({int? mediaId, String? path})> exifCalls = [];

  @override
  Future<MediaRow> fileDetails(String path, {int? id}) async {
    detailCalls.add((path: path, id: id));
    if (hangDetails) return await Completer<MediaRow>().future;
    if (detailsError case final e?) throw e;
    return row;
  }

  @override
  Future<MediaRow?> appInfo(String packageName) async => apps[packageName];

  @override
  Future<bool> openAppDetails(String packageName) async {
    openedAppInfo.add(packageName);
    return true;
  }

  @override
  Future<MediaRow?> exif({int? mediaId, String? path}) async {
    exifCalls.add((mediaId: mediaId, path: path));
    if (exifError case final e?) throw e;
    return exifRow;
  }

  @override
  Future<List<MediaRow>> storageVolumes() async => volumes;
}

FileRef fileAt(
  String path, {
  String? id,
  FileKind kind = FileKind.other,
  String? mime,
}) {
  final slash = path.lastIndexOf('/');
  return FileRef(
    id: id ?? 'path:$path',
    uri: path,
    name: path.substring(slash + 1),
    mimeType: mime,
    kind: kind,
    sizeBytes: 1234,
    modifiedAt: DateTime.utc(2026, 10, 30, 12),
    folderPath: path.substring(0, slash),
    origin: FileOrigin.local,
  );
}

FileDetailsRepository repoWith(
  FakeDetailsPlatform platform, {
  Duration timeout = const Duration(seconds: 5),
  Future<String?> Function(String id)? placeName,
}) => FileDetailsRepository(
  platform: platform,
  knownFiles: () async => KnownFiles.parse(
    File('assets/details/known_files_en.json').readAsStringSync(),
  ),
  knownApps: () async => KnownApps.parse(
    File('assets/details/known_apps.json').readAsStringSync(),
  ),
  placeName: placeName,
  timeout: timeout,
);

const _sticker =
    '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Backups/'
    'Stickers/x/tHXZq4Vwsz+idGdjU4klUwvh.crypt14';

void main() {
  test('crypt14 sticker backup: explanation + WhatsApp from the path, even '
      'with an invisible package and all columns null', () async {
    final p = FakeDetailsPlatform()..row = {'exists': true};
    final d = await repoWith(p).load(fileAt(_sticker));
    expect(d.explanation?.id, 'whatsappStickerBackup');
    expect(d.explanation?.deletable, DeletableHint.careful);
    expect(d.pathApp?.packageName, 'com.whatsapp');
    expect(d.owner?.packageName, 'com.whatsapp');
    expect(d.owner?.label, 'WhatsApp'); // known-apps table
    expect(d.owner?.installed, isFalse);
    expect(d.ownerFromMediaStore, isFalse);
    expect(d.addedAt, isNull);
    expect(d.mimeType, isNull);
    expect(d.exists, isTrue);
    expect(d.partial, isFalse);
    expect(d.volumeKind, VolumeKind.internal);
    expect(p.detailCalls.single, (path: _sticker, id: null));
    expect(p.exifCalls, isEmpty, reason: 'not an image');
  });

  test('MediaStore owner, visible app, download columns, ms: id', () async {
    final icon = Uint8List.fromList([1, 2, 3]);
    final p = FakeDetailsPlatform()
      ..row = {
        'exists': true,
        'mediaId': 42,
        'dateAdded': 1761998400,
        'mime': 'application/pdf',
        'owner': 'com.android.chrome',
        'downloadUri': 'https://files.example.com/a/b.pdf?token=secret',
        'refererUri': 'https://www.example.org/page',
      }
      ..apps = {
        'com.android.chrome': {'label': 'Chrome', 'icon': icon},
      };
    final d = await repoWith(p)
        .load(fileAt('/storage/emulated/0/Download/b.pdf', id: 'ms:42'));
    expect(p.detailCalls.single.id, 42);
    expect(d.owner?.label, 'Chrome');
    expect(d.owner?.installed, isTrue);
    expect(d.owner?.icon, icon);
    expect(d.ownerFromMediaStore, isTrue);
    expect(
      d.addedAt,
      DateTime.fromMillisecondsSinceEpoch(1761998400000, isUtc: true),
    );
    expect(d.mimeType, 'application/pdf');
    expect(hostOf(d.downloadUri), 'files.example.com');
    expect(hostOf(d.refererUri), 'www.example.org');
  });

  test(
    'a package that is neither visible nor known keeps its raw name',
    () async {
      final p = FakeDetailsPlatform()..row = {'exists': true, 'owner': 'x.y.z'};
      final d = await repoWith(p)
          .load(fileAt('/storage/emulated/0/Documents/a.txt'));
      expect(d.owner?.packageName, 'x.y.z');
      expect(d.owner?.label, isNull);
      expect(d.owner?.installed, isFalse);
    },
  );

  test(
    'EXIF: camera, editor, settings; firmware-like Software hidden',
    () async {
      final p = FakeDetailsPlatform()
        ..exifRow = {
          'id': 7,
          'make': 'samsung',
          'model': 'SM-S908B',
          'software': 'S908BXXU2AVF1',
          'iso': 50,
          'exposure': 0.008,
          'fNumber': 1.8,
          'focalLength': 6.3,
          'lat': 52.37,
          'lng': 4.89,
          'frontCamera': false,
          'locationReadable': true,
        };
      final d = await repoWith(p, placeName: (_) async => 'Amsterdam').load(
        fileAt(
          '/storage/emulated/0/DCIM/Camera/a.jpg',
          id: 'ms:7',
          kind: FileKind.image,
        ),
      );
      expect(p.exifCalls.single, (mediaId: 7, path: null));
      expect(d.exif?.camera, 'samsung SM-S908B');
      expect(d.exif?.editor, isNull);
      expect(d.exif?.hasSettings, isTrue);
      expect(d.exif?.hasLocation, isTrue);
      expect(d.placeName, 'Amsterdam');
      expect(d.explanation, isNull);
      expect(
        const ExifDetails(make: 'Canon', model: 'Canon EOS R6').camera,
        'Canon EOS R6',
      );
      expect(
        const ExifDetails(software: 'Snapseed 2.0').editor,
        'Snapseed 2.0',
      );
    },
  );

  test('path: images read EXIF by path', () async {
    final p = FakeDetailsPlatform();
    await repoWith(
      p,
    ).load(fileAt('/storage/emulated/0/.hidden/a.jpg', kind: FileKind.image));
    expect(p.exifCalls.single, (
      mediaId: null,
      path: '/storage/emulated/0/.hidden/a.jpg',
    ));
  });

  test('EXIF failure → partial, the rest still loads', () async {
    final p = FakeDetailsPlatform()
      ..row = {'exists': true, 'mime': 'image/jpeg'}
      ..exifError = const FilesChannelException('IO', 'boom');
    final d = await repoWith(p)
        .load(fileAt('/storage/emulated/0/DCIM/a.jpg', kind: FileKind.image));
    expect(d.partial, isTrue);
    expect(d.exif, isNull);
    expect(d.mimeType, 'image/jpeg');
  });

  test('an EXIF error row → partial, no EXIF', () async {
    final p = FakeDetailsPlatform()..exifRow = {'id': 'x', 'error': 'bad'};
    final d = await repoWith(p)
        .load(fileAt('/storage/emulated/0/DCIM/a.jpg', kind: FileKind.image));
    expect(d.partial, isTrue);
    expect(d.exif, isNull);
  });

  test('slow native call → partial result after the timeout', () async {
    final p = FakeDetailsPlatform()..hangDetails = true;
    final d = await repoWith(
      p,
      timeout: const Duration(milliseconds: 50),
    ).load(fileAt(_sticker));
    expect(d.partial, isTrue);
    expect(d.exists, isNull);
    expect(d.explanation?.id, 'whatsappStickerBackup');
  });

  test('gone file, SD card volume label', () async {
    final p = FakeDetailsPlatform()..row = {'exists': false};
    final d = await repoWith(p)
        .load(fileAt('/storage/1A2B-3C4D/DCIM/a.mp4', kind: FileKind.video));
    expect(d.exists, isFalse);
    expect(d.volumeKind, VolumeKind.removable);
    expect(d.volumeLabel, 'SanDisk SD card');
  });

  test('hostOf: host only, null for junk', () {
    expect(hostOf('https://a.b.c/x?y=1'), 'a.b.c');
    expect(hostOf('not a url'), isNull);
    expect(hostOf(null), isNull);
  });
}
