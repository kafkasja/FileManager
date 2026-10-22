import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/app.dart';

void main() {
  testWidgets('App boots and shows the placeholder screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));

    expect(find.text('KFM'), findsOneWidget);
  });
}
