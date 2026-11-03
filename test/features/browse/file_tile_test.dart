import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/theme/app_theme.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/browse/ui/widgets/file_actions_menu.dart';
import 'package:kfm/features/browse/ui/widgets/file_tile.dart';
import 'package:kfm/features/cloud/ui/cloud_badge_cache.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// TASK-H7: a non-media grid tile's name never runs under the ⋮.
void main() {
  test('long runs get break opportunities every 8 characters', () {
    expect(withBreakOpportunities('manual.pdf'), 'manual.pdf');
    expect(withBreakOpportunities('IMG_2025.jpg'), 'IMG_2025.jpg');
    expect(withBreakOpportunities('abcdefghijklmnopq'), 'abcdefgh​ijklmnop​q');
    // Spaces and hyphens already break: each run counts on its own.
    expect(
      withBreakOpportunities('my holiday-notes 2025.txt'),
      'my holiday-notes 2025.txt',
    );
  });

  testWidgets('a 60-character base64 name stays clear of the menu button', (
    tester,
  ) async {
    const name =
        'aGVsbG8gd29ybGQgdGhpcyBpcyBhIHZlcnkgbG9uZyBiYXNlNjQgbmFtZQ.bin';
    expect(name.length, greaterThanOrEqualTo(60));
    final file = FileRef(
      id: 'path:/s/$name',
      uri: '/s/$name',
      name: name,
      kind: FileKind.other,
      sizeBytes: 3,
      modifiedAt: DateTime.utc(2025),
      folderPath: '/s',
      origin: FileOrigin.local,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // X4: a tile on its own has no database.
          cloudHasUploadsProvider.overrideWith((ref) => Stream.value(false)),
          fileMenuItemsProvider.overrideWithValue([
            FileMenuItem(
              label: (_) => 'x',
              icon: Icons.share,
              onSelected: (_, _, _) async {},
            ),
          ]),
        ],
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox.square(
                dimension: 120,
                child: FileGridTile(
                  file: file,
                  onTap: () {},
                  menu: FileActionsMenuButton(file: file, overlay: true),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // The visible 32 px button, centred in its 48 px tap target.
    final menu = Rect.fromCenter(
      center: tester.getCenter(find.byType(IconButton)),
      width: 32,
      height: 32,
    );
    final nameText = find.descendant(
      of: find.byType(HighlightedName),
      matching: find.byType(RichText),
    );
    final nameRect = tester.getRect(nameText);
    expect(nameRect.right, lessThanOrEqualTo(menu.left));
    expect(nameRect.overlaps(menu), isFalse);
  });
}
