import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/platform/windows/desktop_shell.dart';
import 'package:kfm/features/connect/data/share_background.dart';
import 'package:kfm/features/connect/data/windows_close_flow.dart';

class FakeDesktopShell implements DesktopShell {
  final close = StreamController<void>.broadcast();
  final clicks = StreamController<String>.broadcast();
  final calls = <String>[];
  String? tooltip;
  List<TrayMenuEntry>? menu;

  @override
  Stream<void> get closeRequests => close.stream;
  @override
  Stream<String> get trayClicks => clicks.stream;
  @override
  Future<void> hide() async => calls.add('hide');
  @override
  Future<void> showAndFocus() async => calls.add('show');
  @override
  Future<void> quit() async => calls.add('quit');
  @override
  Future<void> showTray({
    required String tooltip,
    required List<TrayMenuEntry> menu,
  }) async {
    calls.add('tray');
    this.tooltip = tooltip;
    this.menu = menu;
  }

  @override
  Future<void> removeTray() async => calls.add('untray');
}

void main() {
  late FakeDesktopShell shell;
  late bool sharing;
  late bool stopOnClose;
  late bool noticeShown;
  late List<String> events;
  late StreamController<void> attention;

  WindowsCloseFlow flow() => WindowsCloseFlow(
    shell: shell,
    isSharing: () => sharing,
    stopSharing: () async {
      events.add('stopSharing');
      sharing = false;
    },
    stopOnClose: () async => stopOnClose,
    noticeShown: () async => noticeShown,
    markNoticeShown: () async {
      events.add('marked');
      noticeShown = true;
    },
    attentionRequests: attention.stream,
    beforeQuit: () async => events.add('flush'),
  )..start();

  setUp(() {
    shell = FakeDesktopShell();
    sharing = false;
    stopOnClose = false;
    noticeShown = true;
    events = [];
    attention = StreamController.broadcast();
  });

  test('not sharing: closing quits after flushing writes', () async {
    await flow().onCloseRequested();
    expect(events, ['flush']);
    expect(shell.calls, ['quit']);
  });

  test('sharing: closing hides; the first time after the notice', () async {
    sharing = true;
    noticeShown = false;
    final f = flow();
    var noticed = 0;
    f.firstHideNotice = () async => noticed++;
    await f.onCloseRequested();
    await f.onCloseRequested();
    expect(noticed, 1);
    expect(events, ['marked']);
    expect(shell.calls, ['hide', 'hide']);
  });

  test('sharing + stop on close: stops sharing, then quits', () async {
    sharing = true;
    stopOnClose = true;
    await flow().onCloseRequested();
    expect(events, ['stopSharing', 'flush']);
    expect(shell.calls, ['quit']);
  });

  test('tray Open shows the window, Quit stops sharing and quits', () async {
    sharing = true;
    flow();
    shell.clicks.add(trayOpenKey);
    await pumpEventQueue();
    expect(shell.calls, ['show']);
    shell.clicks.add(trayQuitKey);
    await pumpEventQueue();
    expect(events, ['stopSharing', 'flush']);
    expect(shell.calls, ['show', 'quit']);
  });

  test('a connection request brings the window to the front', () async {
    flow();
    attention.add(null);
    await pumpEventQueue();
    expect(shell.calls, ['show']);
  });

  test('the window ✕ goes through the flow', () async {
    flow();
    shell.close.add(null);
    await pumpEventQueue();
    expect(shell.calls, ['quit']);
  });

  test('TrayShareBackground: tray menu and Stop requests', () async {
    final bg = TrayShareBackground(shell);
    expect(bg.supported, isTrue);
    await bg.show(
      const ShareNotificationTexts(
        channel: 'c',
        title: 'Sharing with Phone',
        text: 't',
        stop: 'Stop sharing',
        open: 'Open KFM',
        quit: 'Quit',
      ),
    );
    expect(shell.tooltip, 'Sharing with Phone');
    expect(
      [for (final e in shell.menu!) e.key],
      [trayStopSharingKey, trayOpenKey, trayQuitKey],
    );
    final stops = <void>[];
    final sub = bg.stopRequests.listen(stops.add);
    shell.clicks
      ..add(trayOpenKey)
      ..add(trayStopSharingKey);
    await pumpEventQueue();
    expect(stops, hasLength(1));
    await sub.cancel();
    await bg.showOffer(
      const OfferNotificationTexts(channel: '', title: '', text: ''),
    );
    await bg.stop();
    expect(shell.calls, ['tray', 'show', 'untray']);
  });
}
