import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/form_factor.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/background/cancel_token.dart';
import 'package:kfm/features/folders/domain/file_operation.dart';
import 'package:kfm/features/folders/ui/operation_progress_sheet.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

class _Boom implements Exception;

/// The indeterminate bar animates forever, so pumpAndSettle never ends.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Opens the sheet on "go"; the test drives the task through the returned
/// handles.
class _Run {
  final cancel = CancelToken();
  final done = Completer<String>();
  void Function(OperationProgress)? report;
  final results = <String>[];
  final errors = <Object>[];
}

Future<_Run> _pump(
  WidgetTester tester,
  ProgressLabel label, {
  bool desktop = false,
}) async {
  final run = _Run();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        formFactorProvider.overrideWithValue(
          desktop ? FormFactor.desktop : FormFactor.mobile,
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(extensions: const [AppTokens.light]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                try {
                  run.results.add(
                    await showOperationProgress(
                      context,
                      label: label,
                      cancel: run.cancel,
                      task: (onProgress) {
                        run.report = onProgress;
                        return run.done.future;
                      },
                    ),
                  );
                } on _Boom catch (e) {
                  run.errors.add(e);
                }
              },
              child: const Text('go'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('go'));
  await _settle(tester);
  return run;
}

OperationProgress _p(int done, int total, {String? current}) =>
    OperationProgress(
      done: done,
      total: total,
      bytesDone: done * 1024,
      bytesTotal: total * 1024,
      current: current,
    );

void main() {
  testWidgets('shows "Working…" until the first event, then the count, '
      'file name; closes and returns when the task ends', (tester) async {
    final run = await _pump(tester, ProgressLabel.moving);
    expect(find.text('Working…'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    run.report!(_p(2, 10, current: 'c3.jpg'));
    await tester.pump();
    expect(find.text('Moving 3 of 10'), findsOneWidget);
    expect(find.text('c3.jpg'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, closeTo(0.2, 1e-9));

    run.done.complete('ok');
    await _settle(tester);
    expect(find.text('Moving 3 of 10'), findsNothing);
    expect(run.results, ['ok']);
  });

  testWidgets('B5 byte labels show bytes done of total and a byte bar', (
    tester,
  ) async {
    final run = await _pump(tester, ProgressLabel.compressing);
    run.report!(
      const OperationProgress(
        done: 0,
        total: 1,
        bytesDone: 1024,
        bytesTotal: 4096,
        current: 'a.jpg',
      ),
    );
    await tester.pump();
    expect(find.text('Zipping 1 KB of 4 KB'), findsOneWidget);
    expect(find.text('a.jpg'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, closeTo(0.25, 1e-9));
    run.done.complete('ok');
    await _settle(tester);
    expect(run.results, ['ok']);
  });

  testWidgets('Cancel sets the token once; the sheet stays until the task '
      'stops', (tester) async {
    final run = await _pump(tester, ProgressLabel.copying);
    run.report!(_p(0, 4));
    await tester.pump();
    expect(find.text('Copying 1 of 4'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pump();
    expect(run.cancel.isCancelled, isTrue);
    final button = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Cancel'),
    );
    expect(button.onPressed, isNull);
    expect(find.text('Copying 1 of 4'), findsOneWidget);

    run.done.complete('stopped');
    await _settle(tester);
    expect(find.text('Cancel'), findsNothing);
    expect(run.results, ['stopped']);
  });

  testWidgets('back button cancels instead of closing the sheet', (
    tester,
  ) async {
    final run = await _pump(tester, ProgressLabel.deleting);
    run.report!(_p(1, 3));
    await tester.pump();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    await navigator.maybePop();
    await _settle(tester);
    expect(run.cancel.isCancelled, isTrue);
    expect(find.text('Deleting 2 of 3'), findsOneWidget);
    run.done.complete('x');
    await _settle(tester);
  });

  testWidgets('an error closes the sheet and reaches the caller', (
    tester,
  ) async {
    final run = await _pump(tester, ProgressLabel.undoing);
    run.done.completeError(_Boom());
    await _settle(tester);
    expect(find.text('Working…'), findsNothing);
    expect(run.errors, hasLength(1));
  });

  testWidgets('a dialog the task opens shows above the sheet; the sheet '
      'still closes at the end', (tester) async {
    final run = await _pump(tester, ProgressLabel.copying);
    run.report!(_p(0, 2));
    await tester.pump();
    final context = tester.element(find.text('Copying 1 of 2'));
    unawaited(
      showDialog<void>(
        context: context,
        builder: (_) => const AlertDialog(content: Text('collision')),
      ),
    );
    await _settle(tester);
    run.done.complete('ok');
    await _settle(tester);
    expect(find.text('Copying 1 of 2'), findsNothing);
    expect(find.text('collision'), findsOneWidget);
    expect(run.results, ['ok']);
  });

  testWidgets('desktop: a dialog instead of a bottom sheet; Esc cancels, the '
      'end closes it; collisions show above', (tester) async {
    final run = await _pump(tester, ProgressLabel.copying, desktop: true);
    expect(find.byKey(const ValueKey('operation-progress-dialog')), findsOne);
    expect(find.byType(BottomSheet), findsNothing);
    run.report!(_p(0, 2));
    await tester.pump();
    expect(find.text('Copying 1 of 2'), findsOneWidget);

    // A barrier click doesn't close it; Esc asks to cancel.
    await tester.tapAt(const Offset(5, 5));
    await _settle(tester);
    expect(find.text('Copying 1 of 2'), findsOneWidget);
    expect(run.cancel.isCancelled, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await _settle(tester);
    expect(run.cancel.isCancelled, isTrue);
    expect(find.text('Copying 1 of 2'), findsOneWidget);

    final context = tester.element(find.text('Copying 1 of 2'));
    unawaited(
      showDialog<void>(
        context: context,
        builder: (_) => const AlertDialog(content: Text('collision')),
      ),
    );
    await _settle(tester);
    run.done.complete('ok');
    await _settle(tester);
    expect(
      find.byKey(const ValueKey('operation-progress-dialog')),
      findsNothing,
    );
    expect(find.text('collision'), findsOneWidget);
    expect(run.results, ['ok']);
  });
}
