import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/thumbs/thumbnail.dart';
import 'package:kfm/core/thumbs/thumbnail_cache.dart';

/// E4 (H2): a thumbnail already in the memory cache shows in the tile's
/// first frame, without the fade; others still fade in.
void main() {
  FileRef photo(int i) => FileRef(
    id: 'ms:$i',
    uri: 'content://media/$i',
    name: 'p$i.jpg',
    kind: FileKind.image,
    sizeBytes: 10,
    modifiedAt: DateTime.utc(2025),
    folderPath: '/storage/emulated/0/DCIM',
    origin: FileOrigin.local,
  );

  testWidgets('a memory hit is shown at once; a miss waits and fades in', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('kfm_peek');
    addTearDown(() => dir.deleteSync(recursive: true));
    final bytes = Uint8List.fromList(List.filled(64, 7));
    final cache = DiskThumbnailCache(
      dir: dir,
      generator: (_, _) async => bytes,
      maxDiskBytes: () async => 1 << 20,
    );
    expect(cache.peek(photo(1)), isNull);
    await tester.runAsync(() => cache.get(photo(1)));
    expect(cache.peek(photo(1)), same(bytes));
    expect(cache.peek(photo(2)), isNull);

    final container = ProviderContainer(
      overrides: [thumbnailCacheProvider.overrideWith((ref) async => cache)],
    );
    addTearDown(container.dispose);
    await container.read(thumbnailCacheProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Row(
            children: [
              SizedBox.square(
                dimension: 100,
                child: Thumbnail(key: const ValueKey(1), file: photo(1)),
              ),
              SizedBox.square(
                dimension: 100,
                child: Thumbnail(key: const ValueKey(2), file: photo(2)),
              ),
            ],
          ),
        ),
      ),
    );
    AnimatedOpacity fade(int key) => tester.widget<AnimatedOpacity>(
      find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    // First frame: the cached one is fully shown, with no fade.
    expect(fade(1).opacity, 1);
    expect(fade(1).duration, Duration.zero);
    expect(find.byType(Image), findsOneWidget);
    // The other is blank until its bytes arrive, then fades in.
    expect(fade(2).opacity, 0);
    expect(fade(2).duration, const Duration(milliseconds: 120));
  });
}
