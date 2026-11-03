import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/connect/data/windows_share_check.dart';

void main() {
  late bool public;
  late bool explained;
  late int shown;

  WindowsShareCheck check({bool withUi = true}) {
    final c = WindowsShareCheck(
      isPublic: () async => public,
      firewallExplained: () async => explained,
      markFirewallExplained: () async => explained = true,
    );
    if (withUi) c.explainFirewall = () async => shown++;
    return c;
  }

  setUp(() {
    public = false;
    explained = false;
    shown = 0;
  });

  test('public network → PublicNetworkException, no explainer', () async {
    public = true;
    await expectLater(
      check().beforeBind(),
      throwsA(isA<PublicNetworkException>()),
    );
    expect(shown, 0);
  });

  test('the firewall explainer shows once', () async {
    final c = check();
    await c.beforeBind();
    await c.beforeBind();
    expect(shown, 1);
    expect(explained, isTrue);
  });

  test('without a UI the explainer is asked again next time', () async {
    await check(withUi: false).beforeBind();
    expect(explained, isFalse);
  });

  test('channel errors propagate', () async {
    final c = WindowsShareCheck(
      isPublic: () async => throw StateError('COM'),
      firewallExplained: () async => true,
      markFirewallExplained: () async {},
    );
    await expectLater(c.beforeBind(), throwsStateError);
  });
}
