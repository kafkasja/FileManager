import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/desktop/browse/desktop_breadcrumb.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

Future<List<String?>> _pump(
  WidgetTester tester,
  String? folder, {
  double width = 600,
}) async {
  final opened = <String?>[];
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            key: const ValueKey('bar'),
            width: width,
            child: DesktopBreadcrumb(folder: folder, onOpen: opened.add),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return opened;
}

Rect _rect(WidgetTester tester, String key) =>
    tester.getRect(find.byKey(ValueKey(key)));

void main() {
  testWidgets('a short path starts at the left edge', (tester) async {
    await _pump(tester, 'C:/Users/me');
    final bar = tester.getRect(find.byKey(const ValueKey('bar')));
    final places = _rect(tester, 'crumb-');
    final me = _rect(tester, 'crumb-C:/Users/me');
    expect(places.left, moreOrLessEquals(bar.left, epsilon: 1));
    // Parts follow left to right, the current folder well before the end.
    expect(me.left, greaterThan(places.right));
    expect(me.right, lessThan(bar.right - 100));
  });

  testWidgets('a 200-character folder is cut; its parent stays visible '
      'and clickable', (tester) async {
    final long = 'L' * 200;
    final opened = await _pump(tester, 'C:/Users/me/$long', width: 400);
    final bar = tester.getRect(find.byKey(const ValueKey('bar')));
    final current = _rect(tester, 'crumb-C:/Users/me/$long');
    final parent = _rect(tester, 'crumb-C:/Users/me');
    // The end stays in view, at most 40 % of the bar wide.
    expect(current.right, moreOrLessEquals(bar.right, epsilon: 1));
    expect(
      current.width,
      lessThanOrEqualTo(bar.width * DesktopBreadcrumb.maxPartFraction + 0.5),
    );
    // The way back is on screen.
    expect(parent.left, greaterThanOrEqualTo(bar.left));
    expect(parent.right, lessThanOrEqualTo(current.left));
    await tester.tap(find.byKey(const ValueKey('crumb-C:/Users/me')));
    expect(opened, ['C:/Users/me']);
    // The whole name is in a tooltip.
    expect(find.byTooltip(long), findsOneWidget);
  });

  testWidgets('a deep path keeps the end in view and scrolls the start', (
    tester,
  ) async {
    final deep = [for (var i = 0; i < 30; i++) 'folder$i'].join('/');
    final opened = await _pump(tester, 'C:/$deep', width: 500);
    final bar = tester.getRect(find.byKey(const ValueKey('bar')));
    final last = _rect(tester, 'crumb-C:/$deep');
    expect(last.right, moreOrLessEquals(bar.right, epsilon: 1));
    final parentPath = 'C:/${deep.substring(0, deep.lastIndexOf('/'))}';
    await tester.tap(find.byKey(ValueKey('crumb-$parentPath')));
    expect(opened, [parentPath]);
    // Places scrolled out to the left.
    expect(_rect(tester, 'crumb-').right, lessThan(bar.left));
  });
}
