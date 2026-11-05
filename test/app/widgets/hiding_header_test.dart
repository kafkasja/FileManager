import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/widgets/hiding_header.dart';

/// TASK-E4 bar rule: "Hides while scrolling down, but snaps fully back on
/// any small upward scroll and always shows at the top. Never stuck
/// half-hidden."
void main() {
  const headerKey = ValueKey('header');
  const headerHeight = 120.0;

  Future<void> pump(
    WidgetTester tester, {
    int rows = 200,
    Size size = const Size(400, 800),
    double textScale = 1,
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            body: CustomScrollView(
              slivers: [
                const HidingHeaderSliver(
                  child: SizedBox(
                    key: headerKey,
                    height: headerHeight,
                    child: Text('Header'),
                  ),
                ),
                SliverList.builder(
                  itemCount: rows,
                  itemBuilder: (_, i) =>
                      SizedBox(height: 50, child: Text('row $i')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// How much of the header is on screen (0 = hidden, [headerHeight] =
  /// fully shown).
  double shown(WidgetTester tester) {
    final rect = tester.getRect(find.byKey(headerKey, skipOffstage: false));
    return (rect.bottom.clamp(0, headerHeight) -
            rect.top.clamp(0, headerHeight))
        .toDouble();
  }

  ScrollPosition position(WidgetTester tester) =>
      tester.state<ScrollableState>(find.byType(Scrollable)).position;

  Future<void> scrollDown300(WidgetTester tester) async {
    await tester.drag(find.text('row 5'), const Offset(0, -300));
    await tester.pumpAndSettle();
  }

  Future<void> checkRule(WidgetTester tester) async {
    expect(shown(tester), headerHeight, reason: 'shown at the top');

    await scrollDown300(tester);
    expect(shown(tester), 0, reason: 'hidden after scrolling down');

    // Up 10 px without lifting the finger: fully shown within 200 ms.
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(Scrollable)),
    );
    await gesture.moveBy(const Offset(0, 20)); // the touch slop
    await tester.pump();
    await gesture.moveBy(const Offset(0, 10));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(shown(tester), headerHeight, reason: 'snaps back on 10 px up');
    await gesture.up();
    await tester.pumpAndSettle();

    // Hide again, then a 2 px jitter doesn't show it.
    await scrollDown300(tester);
    expect(shown(tester), 0);
    final jitter = await tester.startGesture(
      tester.getCenter(find.byType(Scrollable)),
    );
    await jitter.moveBy(const Offset(0, -20));
    await tester.pump();
    await jitter.moveBy(const Offset(0, 2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(shown(tester), 0, reason: '2 px jitter keeps it hidden');
    await jitter.up();
    await tester.pumpAndSettle();
    expect(shown(tester), anyOf(0.0, headerHeight));

    // Back to the top: shown.
    position(tester).jumpTo(0);
    await tester.pumpAndSettle();
    expect(shown(tester), headerHeight);
  }

  testWidgets('hides on scroll down, snaps back on a small upward drag, '
      'ignores jitter, always shown at the top', (tester) async {
    await pump(tester);
    await checkRule(tester);
  });

  testWidgets('a scroll stopped halfway settles fully shown or hidden', (
    tester,
  ) async {
    await pump(tester);
    for (final dy in [-40.0, -60.0, -150.0, -500.0]) {
      position(tester).jumpTo(0);
      await tester.pumpAndSettle();
      await tester.drag(find.byType(Scrollable), Offset(0, dy));
      await tester.pumpAndSettle();
      expect(shown(tester), anyOf(0.0, headerHeight), reason: 'down $dy');
      // Then up a little and stop.
      await tester.drag(find.byType(Scrollable), const Offset(0, 30));
      await tester.pumpAndSettle();
      expect(shown(tester), anyOf(0.0, headerHeight), reason: 'up after $dy');
    }
  });

  testWidgets('a list shorter than the screen always shows it', (tester) async {
    await pump(tester, rows: 3);
    await tester.drag(find.byType(Scrollable), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(shown(tester), headerHeight);
  });

  testWidgets('the same at 360x400 (landscape) and at text 2.0', (
    tester,
  ) async {
    await pump(tester, size: const Size(360, 400), textScale: 2);
    await checkRule(tester);
  });
}
