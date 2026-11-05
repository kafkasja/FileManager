// Windows-only: a native error reply decodes as a WindowsChannelException
// with its code and message (it used to arrive with a dangling message and
// fail as a FormatException). Run with
//   flutter test integration_test/windows_channel_errors_test.dart -d windows
@TestOn('windows')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kfm/core/platform/windows/windows_channel.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a thrown ChannelError arrives as its code and message', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await expectLater(
        WindowsChannel().ejectDrive(''),
        throwsA(
          isA<WindowsChannelException>()
              .having((e) => e.code, 'code', 'BAD_ARGS')
              .having((e) => e.message, 'message', contains('drive like E:')),
        ),
      );
      // A second, longer one (heap-allocated strings).
      await expectLater(
        WindowsChannel().deleteFromBin(['C:/not/a/recycle/bin/item.txt']),
        throwsA(
          isA<WindowsChannelException>()
              .having((e) => e.code, 'code', 'BAD_ARGS')
              .having((e) => e.message, 'message', contains('item.txt')),
        ),
      );
    });
  });
}
