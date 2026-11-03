import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/files/windows/windows_file_source.dart';
import 'package:kfm/core/platform/windows/index_roots.dart';
import 'package:kfm/core/platform/windows/windows_channel.dart';
import 'package:kfm/features/settings/ui/windows_roots_section.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// The roots as a plain list (no database).
class _FakeRoots implements WindowsIndexRoots {
  new(this.defaultRoots) : _roots = List.of(defaultRoots);

  final List<String> defaultRoots;
  List<String> _roots;
  final _changes = StreamController<List<String>>.broadcast();

  @override
  Future<List<String>> current() async => _roots;

  @override
  Stream<List<String>> watch() async* {
    yield _roots;
    yield* _changes.stream;
  }

  void _set(List<String> next) {
    _roots = next;
    _changes.add(next);
  }

  @override
  Future<void> add(String folder) async => _set([..._roots, folder]);

  @override
  Future<void> remove(String folder) async => _set([
    for (final r in _roots)
      if (r != folder) r,
  ]);

  @override
  Future<void> resetToDefaults() async => _set(List.of(defaultRoots));

  @override
  Future<List<String>> defaults() async => defaultRoots;

  @override
  Future<List<String>> effective(List<String> stored) async => stored;

  @override
  Future<Map<KnownFolder, String>> knownFolders() async => const {};
}

void main() {
  late Directory dir;
  late String pics;
  late String docs;
  late _FakeRoots roots;
  var rescans = 0;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('kfm_roots_ui');
    pics = normalizeWindowsPath('${dir.path}/Pictures');
    docs = normalizeWindowsPath('${dir.path}/Documents');
    Directory(pics).createSync();
    roots = _FakeRoots([pics, docs]); // docs doesn't exist
    rescans = 0;
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [windowsIndexRootsProvider.overrideWithValue(roots)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: WindowsRootsSection(onRootsChanged: (_) => rescans++),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  String shown(String path) => path.replaceAll('/', r'\');

  testWidgets('lists the roots; a missing one says "Not available"', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text(shown(pics)), findsOneWidget);
    expect(find.text(shown(docs)), findsOneWidget);
    expect(find.text('Not available'), findsOneWidget);
  });

  testWidgets('remove and reset change the roots and rescan', (tester) async {
    await pump(tester);
    await tester.tap(find.byTooltip('Remove ${shown(docs)}'));
    await tester.pumpAndSettle();
    expect(find.text(shown(docs)), findsNothing);
    // The last root has no remove button.
    expect(find.byIcon(Icons.close), findsNothing);
    expect(rescans, 1);

    await tester.tap(find.text('Reset to defaults'));
    await tester.pumpAndSettle();
    expect(find.text(shown(docs)), findsOneWidget);
    expect(rescans, 2);
  });

  testWidgets('add checks that the folder exists', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Add folder'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '${dir.path}/nope');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text('There is no folder at this path'), findsOneWidget);

    final extra = Directory('${dir.path}/Extra')..createSync();
    await tester.enterText(find.byType(TextField), extra.path);
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text(shown(normalizeWindowsPath(extra.path))), findsOneWidget);
    expect(rescans, 1);
  });
}
