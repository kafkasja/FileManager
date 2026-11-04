import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/form_factor.dart';
import 'package:kfm/app/layout/portrait_lock.dart';

void main() {
  late List<Object?> calls;

  setUp(() {
    PortraitLock.holders = 0;
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'SystemChrome.setPreferredOrientations') {
            calls.add(call.arguments);
          }
          return null;
        });
  });

  Widget app({FormFactor form = FormFactor.mobile, bool show = true}) =>
      ProviderScope(
        overrides: [formFactorProvider.overrideWithValue(form)],
        child: MaterialApp(
          home: show
              ? const PortraitLock(child: Text('swipe'))
              : const Text('browse'),
        ),
      );

  testWidgets('portrait while shown; released when it goes', (tester) async {
    await tester.pumpWidget(app());
    expect(calls, [
      ['DeviceOrientation.portraitUp'],
    ]);
    await tester.pumpWidget(app(show: false));
    expect(calls.last, <Object?>[]);
    expect(PortraitLock.holders, 0);
  });

  testWidgets('a page on top (the viewer) may rotate again', (tester) async {
    await tester.pumpWidget(app());
    final nav = tester.state<NavigatorState>(find.byType(Navigator))
      ..push(MaterialPageRoute<void>(builder: (_) => const Text('viewer')));
    await tester.pumpAndSettle();
    expect(calls.last, <Object?>[]);
    nav.pop();
    await tester.pumpAndSettle();
    expect(calls.last, ['DeviceOrientation.portraitUp']);
  });

  testWidgets('a hidden tab (TickerMode off) releases it', (tester) async {
    Widget tab({required bool visible}) => ProviderScope(
      overrides: [formFactorProvider.overrideWithValue(FormFactor.mobile)],
      child: MaterialApp(
        home: TickerMode(
          enabled: visible,
          child: const PortraitLock(child: Text('swipe')),
        ),
      ),
    );
    await tester.pumpWidget(tab(visible: true));
    await tester.pumpWidget(tab(visible: false));
    expect(calls.last, <Object?>[]);
  });

  testWidgets('desktop never locks', (tester) async {
    await tester.pumpWidget(app(form: FormFactor.desktop));
    expect(calls, isEmpty);
  });
}
