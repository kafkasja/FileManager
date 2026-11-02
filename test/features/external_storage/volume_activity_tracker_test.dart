import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/features/external_storage/data/volume_activity_tracker.dart';

void main() {
  late ProviderContainer container;
  late VolumeActivityTracker tracker;
  VolumeActivity state() => container.read(volumeActivityTrackerProvider);

  setUp(() {
    container = ProviderContainer();
    tracker = container.read(volumeActivityTrackerProvider.notifier);
  });
  tearDown(() => container.dispose());

  test('counts running ops and removes the entry at 0', () async {
    final a = Completer<void>();
    final b = Completer<void>();
    final r1 = tracker.run('SD', () => a.future);
    final r2 = tracker.run('SD', () => b.future);
    await pumpEventQueue();
    expect(state().activeCount('SD'), 2);
    a.complete();
    await r1;
    expect(state().activeCount('SD'), 1);
    b.complete();
    await r2;
    expect(state().open, isEmpty);
  });

  test('internal storage is never tracked', () async {
    final gate = Completer<void>();
    final run = tracker.run('primary', () => gate.future);
    expect(state().open, isEmpty);
    tracker.beginEject('primary');
    expect(state().ejecting, isEmpty);
    gate.complete();
    await run;
  });

  test('releases in finally when the op throws', () async {
    await expectLater(
      tracker.run<void>('SD', () async => throw StateError('boom')),
      throwsStateError,
    );
    expect(state().activeCount('SD'), 0);
  });

  test('refuses new work while ejecting; nested work is allowed', () async {
    final gate = Completer<void>();
    var nestedRan = false;
    final outer = tracker.run('SD', () async {
      await gate.future;
      // Inside a running op: a nested call on the same place still runs.
      await tracker.run('SD', () async => nestedRan = true);
    });
    await pumpEventQueue();
    tracker.beginEject('SD');
    await expectLater(
      tracker.run('SD', () async => 1),
      throwsA(
        isA<FileOpException>().having(
          (e) => e.failure,
          'failure',
          FileOpFailure.volumeEjecting,
        ),
      ),
    );
    // Other places are unaffected.
    expect(await tracker.run('USB', () async => 2), 2);
    gate.complete();
    await outer;
    expect(nestedRan, isTrue);
    expect(state().activeCount('SD'), 0);
  });

  test('whenIdle completes when the last op ends', () async {
    final gate = Completer<void>();
    final run = tracker.run('SD', () => gate.future);
    await pumpEventQueue();
    var idle = false;
    unawaited(tracker.whenIdle('SD').then((_) => idle = true));
    await pumpEventQueue();
    expect(idle, isFalse);
    gate.complete();
    await run;
    await pumpEventQueue();
    expect(idle, isTrue);
    await tracker.whenIdle('SD'); // already idle: completes at once
  });

  test('cancelEject makes the place usable; completeEject forgets it', () {
    tracker.beginEject('SD');
    expect(state().isEjecting('SD'), isTrue);
    tracker.cancelEject('SD');
    expect(state().isEjecting('SD'), isFalse);
    tracker
      ..acquire('SD')
      ..beginEject('SD')
      ..completeEject('SD');
    expect(state(), const VolumeActivity());
  });

  test('beginEject calls onEject of top-level leases only', () async {
    var ejected = 0;
    final lease = tracker.acquire('SD', onEject: () => ejected++);
    final gate = Completer<void>();
    final outer = tracker.run('SD', () async {
      final inner = tracker.acquire('SD', onEject: () => ejected += 10);
      await gate.future;
      inner.release();
    });
    await pumpEventQueue();
    tracker.beginEject('SD');
    expect(ejected, 1);
    lease
      ..release()
      ..release(); // idempotent
    gate.complete();
    await outer;
    expect(state().activeCount('SD'), 0);
  });
}
