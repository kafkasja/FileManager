import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/platform/windows/windows_channel.dart';
import 'package:kfm/features/connect/data/windows_power_flow.dart';

void main() {
  late StreamController<PowerState> events;
  late List<String> log;
  var sharing = false;

  WindowsPowerFlow flow({bool failStop = false}) => WindowsPowerFlow(
    events: events.stream,
    isSharing: () => sharing,
    stopSharing: () async {
      log.add('stop');
      if (failStop) throw StateError('bind gone');
      sharing = false;
    },
    flushWrites: () async => log.add('flush'),
    onResume: () async => log.add('resume'),
    onError: (what, e, _) => log.add('error: $what'),
  )..start();

  setUp(() {
    events = StreamController<PowerState>.broadcast();
    log = [];
    sharing = false;
  });
  tearDown(() => events.close());

  test('sleep while sharing stops sharing, then flushes', () async {
    sharing = true;
    final f = flow();
    addTearDown(f.dispose);
    events.add(PowerState.suspend);
    await pumpEventQueue();
    expect(log, ['stop', 'flush']);
    expect(sharing, isFalse);
  });

  test(
    'sleep without sharing only flushes; wake-up runs the resume work',
    () async {
      final f = flow();
      addTearDown(f.dispose);
      events
        ..add(PowerState.suspend)
        ..add(PowerState.resume);
      await pumpEventQueue();
      expect(log, ['flush', 'resume']);
    },
  );

  test('a failing stop is reported and the flush still runs', () async {
    sharing = true;
    final f = flow(failStop: true);
    addTearDown(f.dispose);
    events.add(PowerState.suspend);
    await pumpEventQueue();
    expect(log, ['stop', 'error: stop sharing before sleep', 'flush']);
  });

  test('nothing happens after dispose', () async {
    final f = flow();
    await f.dispose();
    events.add(PowerState.resume);
    await pumpEventQueue();
    expect(log, isEmpty);
  });
}
