import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/db_write_queue.dart';

void main() {
  late DbWriteQueue queue;

  setUp(() => queue = DbWriteQueue());

  test('runs jobs in enqueue order', () async {
    final log = <int>[];
    for (var i = 0; i < 20; i++) {
      queue.enqueue(null, () async => log.add(i)).fireAndForget();
    }
    await queue.flush();
    expect(log, List<int>.generate(20, (i) => i));
  });

  test('enqueue returns before the job runs', () async {
    var ran = false;
    final done = queue.enqueue(null, () async => ran = true);
    expect(ran, isFalse);
    await done;
    expect(ran, isTrue);
  });

  test(
    'coalescing keeps only the last waiting job; all futures complete',
    () async {
      final blocker = Completer<void>();
      final log = <String>[];
      // First job is running, so the next ones wait in the queue.
      final running = queue.enqueue('k', () => blocker.future);
      final a = queue.enqueue('k', () async => log.add('a'));
      final other = queue.enqueue('other', () async => log.add('other'));
      final b = queue.enqueue('k', () async => log.add('b'));
      blocker.complete();
      await Future.wait([running, a, other, b]);
      expect(log, ['other', 'b']);
    },
  );

  test('a replaced job fails when its replacement fails', () async {
    final blocker = Completer<void>();
    queue.enqueue(null, () => blocker.future).fireAndForget();
    final a = queue.enqueue('k', () async {});
    queue.enqueue('k', () async => throw StateError('boom')).fireAndForget();
    blocker.complete();
    await expectLater(a, throwsStateError);
  });

  test('a throwing job publishes one error and later jobs still run', () async {
    final errors = <DbWriteError>[];
    final sub = queue.errors.listen(errors.add);
    addTearDown(sub.cancel);

    var laterRan = false;
    final failing = queue.enqueue('bad', () async => throw StateError('boom'));
    final later = queue.enqueue(null, () async => laterRan = true);

    await expectLater(failing, throwsStateError);
    await later;
    await Future<void>.delayed(Duration.zero);
    expect(laterRan, isTrue);
    expect(errors, hasLength(1));
    expect(errors.single.coalesceKey, 'bad');
    expect(errors.single.error, isStateError);
  });

  test('enqueue after close errors with StateError and runs nothing', () async {
    await queue.close();
    var ran = false;
    await expectLater(
      queue.enqueue(null, () async => ran = true),
      throwsStateError,
    );
    expect(ran, isFalse);
  });

  test('close waits for queued writes', () async {
    var ran = false;
    queue.enqueue(null, () async => ran = true).fireAndForget();
    await queue.close();
    expect(ran, isTrue);
  });
}
