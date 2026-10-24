import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/platform/permissions/ensure_all_files_access.dart';
import 'package:kfm/core/platform/permissions/storage_access.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

import 'fake_permission_service.dart';

/// A button that calls [ensureAllFilesAccess] and records the result.
Future<List<bool>> _pump(
  WidgetTester tester,
  FakePermissionService service,
) async {
  final results = <bool>[];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [permissionServiceProvider.overrideWithValue(service)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Consumer(
          builder: (context, ref, _) => Scaffold(
            body: TextButton(
              onPressed: () async =>
                  results.add(await ensureAllFilesAccess(context, ref)),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return results;
}

void main() {
  final notGranted = grantedAccess.copyWith(
    allFiles: AllFilesAccess.notGranted,
  );

  testWidgets('already granted: no sheet', (tester) async {
    final results = await _pump(tester, FakePermissionService());
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(results, [true]);
    expect(find.text('Turn on'), findsNothing);
  });

  testWidgets('Turn on opens the system page and returns the new state', (
    tester,
  ) async {
    final service = FakePermissionService(notGranted);
    final results = await _pump(tester, service);
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'To show documents and downloads too, turn on All files access.',
      ),
      findsOneWidget,
    );
    service.current = grantedAccess; // user flips the switch
    await tester.tap(find.text('Turn on'));
    await tester.pumpAndSettle();
    expect(service.calls, contains('openAllFilesAccessSettings'));
    expect(results, [true]);
  });

  testWidgets('Not now is remembered for the rest of the run', (tester) async {
    final results = await _pump(tester, FakePermissionService(notGranted));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(results, [false, false]);
    expect(find.text('Turn on'), findsNothing);
  });
}
