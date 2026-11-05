import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kfm/app/a11y/file_semantics.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/thumbs/thumbnail_cache.dart';
import 'package:kfm/features/browse/ui/widgets/file_tile.dart';
import 'package:kfm/features/cloud/ui/cloud_badge_cache.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';
import 'package:kfm/l10n/generated/app_localizations_en.dart';

FileRef _file(String name, FileKind kind, int size) => FileRef(
  id: 'path:/s/$name',
  uri: 'file:///s/$name',
  name: name,
  kind: kind,
  sizeBytes: size,
  modifiedAt: DateTime(2026, 11, 4, 12),
  folderPath: '/s',
  origin: FileOrigin.local,
);

/// TASK-E2 §7: tiles speak name, type, size and date.
void main() {
  setUpAll(() => initializeDateFormatting('en'));
  final l10n = AppLocalizationsEn();

  test('label: name, kind, size, date', () {
    expect(
      fileSemanticsLabel(l10n, _file('cat.mp4', FileKind.video, 312 << 20)),
      'cat.mp4, Video, 312 MB, Nov 4, 2026',
    );
    expect(
      fileSemanticsLabel(l10n, _file('a.pdf', FileKind.document, 2048)),
      startsWith('a.pdf, PDF document, 2 KB'),
    );
    expect(
      fileKindSpoken(l10n, _file('x.zip', FileKind.archive, 1)),
      'Archive',
    );
    expect(fileKindSpoken(l10n, _file('noext', FileKind.other, 1)), 'File');
  });

  testWidgets('grid tile and list row carry the label', (tester) async {
    final handle = tester.ensureSemantics();
    final f = _file('cat.mp4', FileKind.video, 312 << 20);
    final thumbDir = Directory.systemTemp.createTempSync('kfm_sem_thumbs');
    addTearDown(() => thumbDir.deleteSync(recursive: true));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          thumbnailCacheProvider.overrideWith(
            (ref) async => DiskThumbnailCache(
              dir: thumbDir,
              generator: (_, _) async => null,
              maxDiskBytes: () async => 1 << 20,
            ),
          ),
          cloudHasUploadsProvider.overrideWith((ref) => Stream.value(false)),
        ],
        child: MaterialApp(
          theme: ThemeData(extensions: const [AppTokens.light]),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Column(
              children: [
                SizedBox.square(
                  dimension: 120,
                  child: FileGridTile(file: f, onTap: () {}),
                ),
                FileListRow(file: f, onTap: () {}),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(
      find.bySemanticsLabel('cat.mp4, Video, 312 MB, Nov 4, 2026'),
      findsNWidgets(2),
    );
    handle.dispose();
  });
}
