import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/screenshot_rule.dart';
import 'package:kfm/core/index/source_rule.dart';

const _root = '/storage/emulated/0';

void main() {
  // (folder below the volume, name, kind, expected)
  final cases = <(String, String, FileKind, SourceBucket)>[
    // The user's S22 Ultra, /sdcard/DCIM.
    ('DCIM/Camera', '20241001_101010.jpg', FileKind.image, SourceBucket.camera),
    ('DCIM/Camera', '20241001_101010.mp4', FileKind.video, SourceBucket.camera),
    ('DCIM/Expert RAW', 'x.dng', FileKind.image, SourceBucket.expertRaw),
    ('DCIM/Screenshots', 'x.png', FileKind.image, SourceBucket.screenshots),
    (
      'DCIM/Screen recordings',
      'x.mp4',
      FileKind.video,
      SourceBucket.screenRecordings,
    ),
    ('DCIM/Snapchat', 'x.jpg', FileKind.image, SourceBucket.snapchat),
    ('DCIM/GIF', 'x.gif', FileKind.image, SourceBucket.gifs),
    ('DCIM/Collage', 'x.jpg', FileKind.image, SourceBucket.collages),
    (
      'DCIM/Clipped images',
      'x.png',
      FileKind.image,
      SourceBucket.clippedImages,
    ),
    ('DCIM/Live message', 'x.gif', FileKind.image, SourceBucket.liveMessages),
    ('DCIM/Videocaptures', 'x.jpg', FileKind.image, SourceBucket.videoCaptures),
    ('DCIM/Tapo', 'x.jpg', FileKind.image, SourceBucket.none),
    ('DCIM/iCSee', 'x.mp4', FileKind.video, SourceBucket.none),
    ('DCIM', 'x.jpg', FileKind.image, SourceBucket.none),
    // Other phones and apps.
    ('Download/Telegram', 'x.jpg', FileKind.image, SourceBucket.telegram),
    ('Pictures/Telegram', 'x.jpg', FileKind.image, SourceBucket.telegram),
    ('Pictures/Screenshots', 'x.png', FileKind.image, SourceBucket.screenshots),
    ('Pictures', 'x.jpg', FileKind.image, SourceBucket.none),
    ('Pictures/Instagram', 'x.jpg', FileKind.image, SourceBucket.instagram),
    (
      'Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Images',
      'IMG-1.jpg',
      FileKind.image,
      SourceBucket.whatsapp,
    ),
    (
      'Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Documents',
      'a.pdf',
      FileKind.document,
      SourceBucket.whatsapp,
    ),
    (
      'WhatsApp/Media/WhatsApp Images/Sent',
      'x.jpg',
      FileKind.image,
      SourceBucket.whatsapp,
    ),
    (
      'Android/media/com.whatsapp.w4b/WhatsApp Business/Media',
      'x.jpg',
      FileKind.image,
      SourceBucket.whatsapp,
    ),
    ('Download', 'a.pdf', FileKind.document, SourceBucket.downloads),
    ('Downloads/sub', 'a.zip', FileKind.archive, SourceBucket.downloads),
    ('DCIM/100ANDRO', 'x.jpg', FileKind.image, SourceBucket.camera),
    (
      'DCIM/ScreenRecorder',
      'x.mp4',
      FileKind.video,
      SourceBucket.screenRecordings,
    ),
    (
      'Movies',
      'Screen_recording_2024.mp4',
      FileKind.video,
      SourceBucket.screenRecordings,
    ),
    // Documents in DCIM/Camera are not camera shots.
    ('DCIM/Camera', 'notes.txt', FileKind.document, SourceBucket.none),
  ];

  for (final (folder, name, kind, expected) in cases) {
    test('$folder/$name → ${expected.name}', () {
      expect(sourceFor(kind, '$_root/$folder', name), expected);
    });
  }

  test('SD card, /sdcard and Windows user folders are stripped', () {
    expect(
      sourceFor(FileKind.image, '/storage/1A2B-3C4D/DCIM/Camera', 'x.jpg'),
      SourceBucket.camera,
    );
    expect(volumeRelative('/sdcard/DCIM/Camera'), 'dcim/camera');
    expect(
      volumeRelative('C:/Users/kaf/Pictures/Screenshots'),
      'pictures/screenshots',
    );
  });

  test('source = screenshots exactly when isScreenshot', () {
    for (final (folder, name, kind, _) in cases) {
      final path = '$_root/$folder';
      expect(
        sourceFor(kind, path, name) == SourceBucket.screenshots,
        isScreenshot(kind, path, name),
        reason: '$folder/$name',
      );
    }
  });

  test('volumeRootOf', () {
    expect(
      volumeRootOf('/storage/emulated/0/DCIM/Camera'),
      '/storage/emulated/0',
    );
    expect(volumeRootOf('/storage/1A2B-3C4D/x'), '/storage/1A2B-3C4D');
    expect(volumeRootOf('/s/DCIM'), '/s');
  });
}
