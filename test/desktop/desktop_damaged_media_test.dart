import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/media_damage.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/thumbs/thumbnail.dart';
import 'package:kfm/core/thumbs/thumbnail_cache.dart';
import 'package:kfm/desktop/widgets/quick_look.dart';
import 'package:kfm/features/swipe/ui/video_controller_pool.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

import '../core/files/fake_file_source.dart';
import '../features/swipe/fake_video.dart';
import 'desktop_helpers.dart';

/// Opening throws like MediaKitHandle on a stick's zero-filled video.
class _DamagedVideos extends FakeVideoFactory {
  Completer<void>? gate;

  @override
  VideoHandle call(FileRef f) => _Damaged(f, gate);
}

class _Damaged extends FakeVideoHandle {
  new(super.file, this.gate);

  final Completer<void>? gate;

  @override
  Future<void> initialize() async {
    await gate?.future;
    throw DamagedFileException(file.path, 'only zero bytes');
  }
}

FileRef _file(String path, FileKind kind) => FileRef(
  id: 'path:$path',
  uri: path,
  name: path.split('/').last,
  kind: kind,
  sizeBytes: 10,
  modifiedAt: DateTime.utc(2026),
  folderPath: path.substring(0, path.lastIndexOf('/')),
  origin: FileOrigin.local,
);

void main() {
  group('looksDamaged', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('kfm-damage-'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('zero bytes or empty: damaged; a real header or a missing file: '
        'not', () async {
      final zeros = File('${dir.path}/zeros.mp4')
        ..writeAsBytesSync(Uint8List(200000));
      final empty = File('${dir.path}/empty.mp4')..writeAsBytesSync([]);
      final mp4 = File('${dir.path}/ok.mp4')
        ..writeAsBytesSync([0, 0, 0, 0x18, ...'ftypmp42'.codeUnits]);
      // Data only after the probed start: still looks damaged.
      final late = File('${dir.path}/late.mp4')
        ..writeAsBytesSync([...Uint8List(kDamageProbeBytes), 1, 2, 3]);
      expect(await looksDamaged(zeros.path), isTrue);
      expect(await looksDamaged(empty.path), isTrue);
      expect(await looksDamaged(mp4.path), isFalse);
      expect(await looksDamaged(late.path), isTrue);
      expect(await looksDamaged('${dir.path}/missing.mp4'), isFalse);
    });
  });

  testWidgets('Quick look: a damaged video says so, after a spinner', (
    tester,
  ) async {
    final files = FakeFileSource();
    final clip = files.addFile('/E/Videos/broken.mp4');
    final videos = _DamagedVideos()..gate = Completer<void>();
    await pumpDesktopApp(tester, files: files, videos: videos);
    final context = tester.element(find.byType(Scaffold).first);
    showQuickLook(
      context,
      watchFiles: (ref) => [clip],
      startId: clip.id,
    ).ignore();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    // Opening is slow: a spinner, not a silent black picture.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    videos.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      find.text("This file can't be played — it may be damaged"),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.broken_image_outlined), findsWidgets);
  });

  testWidgets('a thumbnail that cannot be made shows the broken icon', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('kfm-thumbs-');
    addTearDown(() => dir.deleteSync(recursive: true));
    final cache = DiskThumbnailCache(
      dir: dir,
      generator: (_, _) async => null,
      maxDiskBytes: () async => 1 << 20,
    );
    final video = _file('/E/Videos/broken.mp4', FileKind.video);
    final doc = _file('/E/notes.txt', FileKind.document);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [thumbnailCacheProvider.overrideWith((ref) async => cache)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Row(
            children: [
              SizedBox.square(dimension: 100, child: Thumbnail(file: video)),
              SizedBox.square(dimension: 100, child: Thumbnail(file: doc)),
            ],
          ),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('thumbnail-failed')), findsOneWidget);
    // A kind without thumbnails keeps its type icon.
    expect(find.byIcon(Icons.description_outlined), findsOneWidget);
  });
}
