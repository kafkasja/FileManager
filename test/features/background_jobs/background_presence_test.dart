import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/background_jobs/data/background_presence.dart';
import 'package:kfm/features/background_jobs/data/windows_presence_port.dart';
import 'package:kfm/features/background_jobs/domain/job_notice.dart';
import 'package:kfm/features/background_jobs/domain/job_progress.dart';
import 'package:kfm/features/connect/data/share_background.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

import '../../core/platform/windows/fake_windows_channel.dart';
import '../connect/windows_close_flow_test.dart' show FakeDesktopShell;

class FakePort implements PresencePort {
  final List<String> calls = [];
  OngoingPresence? ongoing;
  final Map<NoticeSlot, NoticePresence> notices = {};
  final StreamController<String> actionsCtl = StreamController.broadcast();
  bool refuse = false;
  int asked = 0;

  @override
  Stream<String> get actions => actionsCtl.stream;

  @override
  Future<void> askNotificationsOnce() async => asked++;

  @override
  Future<void> cancelNotice(NoticeSlot slot) async {
    calls.add('cancel:${slot.name}');
    notices.remove(slot);
  }

  @override
  Future<void> showNotice(NoticeSlot slot, NoticePresence n) async {
    calls.add('notice:${slot.name}');
    notices[slot] = n;
  }

  @override
  Future<void> showOngoing(OngoingPresence p) async {
    if (refuse) throw StateError('ForegroundServiceStartNotAllowed');
    calls.add('show');
    ongoing = p;
  }

  @override
  Future<void> stopOngoing() async {
    calls.add('stop');
    ongoing = null;
  }
}

class FakeControls implements JobControls {
  final List<String> calls = [];

  @override
  Future<void> cancel(String key) async => calls.add('cancel $key');

  @override
  Future<void> pause(String key) async => calls.add('pause $key');

  @override
  Future<void> resume(String key) async => calls.add('resume $key');
}

JobProgress _job(
  String key, {
  JobPhase phase = JobPhase.running,
  int done = 0,
  int files = 2,
}) => JobProgress(
  key: key,
  kind: JobKind.send,
  target: const DeviceTarget('PC'),
  phase: phase,
  files: files,
  filesDone: done,
  bytesDone: 10,
  bytesTotal: 100,
);

const _share = ShareNotificationTexts(
  channel: 'Device sharing',
  title: 'Sharing this device',
  text: 'Tap to open KFM.',
  stop: 'Stop',
);

void main() {
  late FakePort port;
  late FakeControls controls;
  late StreamController<JobsSnapshot> snaps;
  late StreamController<JobEnd> ends;
  late BackgroundPresence presence;
  var lang = 'en';

  NoticeFormat format() => NoticeFormat(
    l10n: lookupAppLocalizations(Locale(lang)),
    locale: lang,
    placeName: (t) => t.folder,
  );

  Future<void> settle() async {
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  setUp(() {
    lang = 'en';
    port = FakePort();
    controls = FakeControls();
    snaps = StreamController.broadcast();
    ends = StreamController.broadcast();
    presence = BackgroundPresence(
      port: port,
      controls: controls,
      format: format,
      snapshots: snaps.stream,
      ends: ends.stream,
      endBatch: const Duration(milliseconds: 20),
    );
  });

  tearDown(() => presence.dispose());

  test('the service starts with the first running job and stops with the '
      'last', () async {
    snaps.add(JobsSnapshot(jobs: [_job('t:1')]));
    await settle();
    expect(port.ongoing!.jobs, isTrue);
    expect(port.ongoing!.sharing, isFalse);
    expect(port.ongoing!.title, 'Sending 2 files to PC');
    expect(port.ongoing!.actions.map((a) => a.$1), ['pause', 'cancel']);
    expect(port.ongoing!.actions.map((a) => a.$2), ['Pause', 'Cancel']);
    expect(port.asked, 1);

    // Same content again: no new platform call.
    snaps.add(JobsSnapshot(jobs: [_job('t:1')]));
    await settle();
    expect(port.calls.where((c) => c == 'show'), hasLength(1));

    snaps.add(JobsSnapshot.empty);
    ends.add(JobEnd(_job('t:1', phase: JobPhase.done, done: 2)));
    await settle();
    expect(port.ongoing, isNull);
    await Future<void>.delayed(const Duration(milliseconds: 40));
    await settle();
    expect(port.notices[NoticeSlot.ended]!.title, 'Sent 2 files to PC');
    expect(
      port.notices[NoticeSlot.ended]!.channel.channel,
      PresenceChannel.results,
    );
  });

  test('sharing and jobs share one notification; sharing stays after the '
      'jobs', () async {
    await presence.setSharing(_share);
    expect(port.ongoing!.sharing, isTrue);
    expect(port.ongoing!.jobs, isFalse);
    expect(port.ongoing!.title, 'Sharing this device');
    expect(port.ongoing!.actions, [('stopSharing', 'Stop')]);

    snaps.add(JobsSnapshot(jobs: [_job('t:1')]));
    await settle();
    expect(port.ongoing!.sharing, isTrue);
    expect(port.ongoing!.jobs, isTrue);
    expect(port.ongoing!.actions.map((a) => a.$1), [
      'pause',
      'cancel',
      'stopSharing',
    ]);

    snaps.add(JobsSnapshot.empty);
    await settle();
    expect(port.ongoing!.jobs, isFalse);
    expect(port.ongoing!.title, 'Sharing this device');

    final stops = <void>[];
    presence.stopSharingRequests.listen(stops.add);
    port.actionsCtl.add('stopSharing');
    await settle();
    expect(stops, hasLength(1));
    await presence.setSharing(null);
    expect(port.ongoing, isNull);
    expect(port.calls.last, 'stop');
  });

  test('a refused start throws for sharing; jobs keep going', () async {
    port.refuse = true;
    await expectLater(presence.setSharing(_share), throwsStateError);
    snaps.add(JobsSnapshot(jobs: [_job('t:1')]));
    await settle();
    expect(port.ongoing, isNull);
  });

  test('Pause from the notification pauses running jobs; paused-only shows '
      'a dismissible notice with Resume; Resume and Cancel', () async {
    snaps.add(JobsSnapshot(jobs: [_job('t:1'), _job('l:2')]));
    await settle();
    port.actionsCtl.add('pause');
    await settle();
    expect(controls.calls, ['pause t:1', 'pause l:2']);

    snaps.add(
      JobsSnapshot(
        jobs: [
          _job('t:1', phase: JobPhase.paused),
          _job('l:2', phase: JobPhase.paused),
        ],
      ),
    );
    await settle();
    expect(port.ongoing, isNull);
    final n = port.notices[NoticeSlot.paused]!;
    expect(n.title, '2 transfers paused');
    expect(n.actions.map((a) => a.$1), ['resume', 'cancel']);

    port.actionsCtl.add('resume');
    await settle();
    expect(controls.calls.sublist(2), ['resume t:1', 'resume l:2']);
    snaps.add(JobsSnapshot(jobs: [_job('t:1'), _job('l:2')]));
    await settle();
    expect(port.ongoing, isNotNull);
    expect(port.notices[NoticeSlot.paused], isNull);

    port.actionsCtl.add('cancel');
    await settle();
    expect(controls.calls.sublist(4), ['cancel t:1', 'cancel l:2']);
  });

  test('Android 15 time limit: jobs pause as "open KFM to continue" and '
      'continue in the foreground', () async {
    snaps.add(JobsSnapshot(jobs: [_job('t:1')]));
    await settle();
    port.actionsCtl.add(PresenceKeys.timeout);
    await settle();
    expect(controls.calls, ['pause t:1']);
    snaps.add(JobsSnapshot(jobs: [_job('t:1', phase: JobPhase.paused)]));
    await settle();
    expect(port.ongoing, isNull);
    expect(
      port.notices[NoticeSlot.paused]!.text,
      'Paused, open KFM to continue',
    );
    expect(port.notices[NoticeSlot.paused]!.actions, isEmpty);
    await presence.onForeground();
    expect(controls.calls.last, 'resume t:1');
    expect(presence.timedOut, isEmpty);
  });

  test(
    'a refresh while paused still removes the paused notice later',
    () async {
      snaps.add(JobsSnapshot(jobs: [_job('t:1')]));
      await settle();
      snaps.add(JobsSnapshot(jobs: [_job('t:1', phase: JobPhase.paused)]));
      await settle();
      expect(port.notices[NoticeSlot.paused], isNotNull);
      presence.refresh();
      await settle();
      expect(port.notices[NoticeSlot.paused], isNotNull);
      snaps.add(JobsSnapshot(jobs: [_job('t:1')]));
      await settle();
      expect(port.notices[NoticeSlot.paused], isNull);
      expect(port.ongoing, isNotNull);
    },
  );

  test(
    'a language switch renders everything again in the new language',
    () async {
      await presence.setSharing(_share);
      snaps.add(JobsSnapshot(jobs: [_job('t:1')]));
      await settle();
      expect(port.ongoing!.channel.name, 'Transfers in progress');
      lang = 'nl';
      presence.refresh();
      await settle();
      final nl = lookupAppLocalizations(const Locale('nl'));
      expect(port.ongoing!.title, nl.transferUploadQueued(2, 'PC'));
      expect(port.ongoing!.channel.name, nl.jobsChannelProgress);
      expect(port.ongoing!.actions.first.$2, nl.transferPause);
      lang = 'tr';
      presence.refresh();
      await settle();
      final tr = lookupAppLocalizations(const Locale('tr'));
      expect(port.ongoing!.actions.first.$2, tr.transferPause);
      expect(port.ongoing!.channel.name, tr.jobsChannelProgress);
    },
  );

  test('Windows: tray tooltip with the progress, taskbar progress', () async {
    final shell = FakeDesktopShell();
    final channel = FakeWindowsChannel();
    final win = WindowsPresencePort(
      shell: shell,
      taskbar: channel.setTaskbarProgress,
      l10n: () => lookupAppLocalizations(const Locale('en')),
    );
    await win.showOngoing(
      const OngoingPresence(
        sharing: false,
        jobs: true,
        title: 'Sending 2 files to PC',
        text: '10 B of 100 B',
        percent: 10,
        channel: PresenceChannelTexts(PresenceChannel.progress, 'x'),
        actions: [('pause', 'Pause'), ('cancel', 'Cancel')],
      ),
    );
    expect(shell.tooltip, 'Sending 2 files to PC\n10 B of 100 B');
    expect(shell.menu!.map((e) => e.key), ['pause', 'cancel', 'open', 'quit']);
    expect(channel.taskbar.last.$1.name, 'normal');
    expect(channel.taskbar.last.$2, 10);
    await win.stopOngoing();
    await win.showNotice(
      NoticeSlot.paused,
      const NoticePresence(
        title: 't',
        text: 'x',
        percent: 40,
        channel: PresenceChannelTexts(PresenceChannel.progress, 'x'),
      ),
    );
    expect(channel.taskbar.last.$1.name, 'paused');
    await win.cancelNotice(NoticeSlot.paused);
    expect(channel.taskbar.last.$1.name, 'none');
    expect(
      WindowsPresencePort.tooltip('a' * 100, 'b' * 100).length,
      kTrayTooltipMax,
    );
    final keys = <String>[];
    win.actions.listen(keys.add);
    shell.clicks
      ..add('pause')
      ..add('open');
    await settle();
    expect(keys, ['pause']);
  });
}
