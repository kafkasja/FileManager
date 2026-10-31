import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/features/folders/domain/file_operation.dart';
import 'package:kfm/features/folders/ui/collision_dialog.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

import '../../../core/files/fake_file_source.dart';

const _root = '/storage/emulated/0';

/// A button that opens the collision dialog and records its answers.
Future<List<CollisionAnswer>> _pump(
  WidgetTester tester, {
  bool showApplyToAll = true,
}) async {
  final files = FakeFileSource();
  final incoming = files.addFile('$_root/DCIM/Camera/photo.jpg');
  final existing = files.addFile('$_root/DCIM/Holiday/photo.jpg');
  final answers = <CollisionAnswer>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(extensions: const [AppTokens.light]),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async => answers.add(
              await showCollisionDialog(
                context,
                incoming: incoming,
                existing: existing,
                showApplyToAll: showApplyToAll,
              ),
            ),
            child: const Text('go'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('go'));
  await tester.pumpAndSettle();
  return answers;
}

void main() {
  testWidgets('names the file and the folder; each button answers', (
    tester,
  ) async {
    final answers = await _pump(tester);
    expect(find.text('Name already used'), findsOneWidget);
    expect(find.text('photo.jpg already exists in Holiday'), findsOneWidget);

    await tester.tap(find.text('Replace'));
    await tester.pumpAndSettle();
    expect(answers, [(CollisionChoice.replace, false)]);

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep both'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(answers.skip(1), [
      (CollisionChoice.keepBoth, false),
      (CollisionChoice.skip, false),
    ]);
  });

  testWidgets('"Do this for all remaining" is returned with the choice', (
    tester,
  ) async {
    final answers = await _pump(tester);
    await tester.tap(find.text('Do this for all remaining'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep both'));
    await tester.pumpAndSettle();
    expect(answers, [(CollisionChoice.keepBoth, true)]);
  });

  testWidgets('dismissing it skips this file only', (tester) async {
    final answers = await _pump(tester);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('Name already used'), findsNothing);
    expect(answers, [(CollisionChoice.skip, false)]);
  });

  testWidgets('single file: no apply-to-all checkbox', (tester) async {
    await _pump(tester, showApplyToAll: false);
    expect(find.text('Do this for all remaining'), findsNothing);
    expect(find.byType(Checkbox), findsNothing);
  });
}
