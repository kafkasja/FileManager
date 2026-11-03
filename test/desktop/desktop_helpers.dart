import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/form_factor.dart';
import 'package:kfm/features/folders/data/folder_tree_transfer.dart';

import '../core/files/fake_file_source.dart';
import '../helpers/pump_app.dart';

/// The desktop window size the PL3 tests use.
const desktopWindow = Size(1280, 800);

/// A library of [n] photos `p0.jpg` … (newest last) in [folder].
FakeFileSource desktopLibrary(int n, {String folder = '/s/DCIM'}) {
  final files = FakeFileSource();
  for (var i = 0; i < n; i++) {
    files.addFile(
      '$folder/p$i.jpg',
      modifiedAt: DateTime.utc(2025, 1, 1, 0, i),
      bytes: List.filled(10 + i, 1),
    );
  }
  return files;
}

/// The whole app in the desktop form factor at [desktopWindow].
Future<TestApp> pumpDesktopApp(
  WidgetTester tester, {
  FakeFileSource? files,
  List<Override> overrides = const [],
}) async {
  tester.view
    ..physicalSize = desktopWindow
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final app = await pumpApp(
    tester,
    files: files,
    overrides: [
      formFactorProvider.overrideWithValue(FormFactor.desktop),
      // The fake file source has no disk folders to remove.
      emptyDirRemoverProvider.overrideWithValue((_) async => false),
      subfolderListerProvider.overrideWithValue((_) async => const []),
      ...overrides,
    ],
  );
  // Indexer scan → index change (debounced) → deck reload.
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
  return app;
}
