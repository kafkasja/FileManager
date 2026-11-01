import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/background/in_app_jobs.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/index/media_indexer.dart';

/// Records runs; [gate] (if set) holds each run until completed. Loops
/// until stopped while [loopUntilStopped].
class FakeJob implements BackgroundJob {
  new(this.name, this.log, {this.loopUntilStopped = false, this.fail = false});

  @override
  final String name;
  final List<String> log;
  final bool loopUntilStopped;
  final bool fail;
  Completer<void>? gate;

  @override
  Future<void> run(JobContext ctx) async {
    log.add('$name:start');
    final g = gate;
    if (g != null) await g.future;
    while (loopUntilStopped && !ctx.shouldStop) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    if (fail) throw StateError('boom');
    log.add('$name:${ctx.shouldStop ? 'stopped' : 'done'}');
  }
}

void main() {
  late InAppJobRunner runner;
  late List<String> log;

  setUp(() {
    runner = InAppJobRunner();
    log = [];
  });
  tearDown(() => runner.dispose());

  void ready() {
    runner
      ..setIndexIdle(idle: true)
      ..start();
  }

  test('runs registered jobs one at a time, in order', () async {
    final a = FakeJob('a', log)..gate = Completer();
    final b = FakeJob('b', log);
    runner
      ..register(a)
      ..register(b);
    ready();
    await Future<void>.delayed(Duration.zero);
    expect(log, ['a:start']);
    a.gate!.complete();
    await runner.idle();
    expect(log, ['a:start', 'a:done', 'b:start', 'b:done']);
  });

  test('nothing runs before start, while scanning or while paused', () async {
    runner.register(FakeJob('a', log));
    await runner.idle();
    expect(log, isEmpty);
    runner.start();
    await runner.idle();
    expect(log, isEmpty, reason: 'index not idle yet');
    runner
      ..setResumed(resumed: false)
      ..setIndexIdle(idle: true);
    await runner.idle();
    expect(log, isEmpty, reason: 'app paused');
    runner.setResumed(resumed: true);
    await runner.idle();
    expect(log, ['a:start', 'a:done']);
  });

  test('pausing or a new scan sets shouldStop; resuming runs again', () async {
    final a = FakeJob('a', log, loopUntilStopped: true);
    runner.register(a);
    ready();
    await Future<void>.delayed(const Duration(milliseconds: 5));
    runner.setResumed(resumed: false);
    await runner.idle();
    expect(log, ['a:start', 'a:stopped']);

    runner.setResumed(resumed: true);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    runner.setIndexIdle(idle: false);
    await runner.idle();
    expect(log, ['a:start', 'a:stopped', 'a:start', 'a:stopped']);
  });

  test('kick while running runs the queue once more afterwards', () async {
    final a = FakeJob('a', log)..gate = Completer();
    runner.register(a);
    ready();
    await Future<void>.delayed(Duration.zero);
    runner
      ..kick()
      ..kick();
    a.gate!.complete();
    a.gate = null;
    await runner.idle();
    expect(log, ['a:start', 'a:done', 'a:start', 'a:done']);
  });

  test('a failing job does not stop the next one', () async {
    runner
      ..register(FakeJob('bad', log, fail: true))
      ..register(FakeJob('good', log));
    ready();
    await runner.idle();
    expect(log, ['bad:start', 'good:start', 'good:done']);
  });

  test('dispose stops the running job', () async {
    runner.register(FakeJob('a', log, loopUntilStopped: true));
    ready();
    await Future<void>.delayed(const Duration(milliseconds: 5));
    runner.dispose();
    await runner.idle();
    expect(log, ['a:start', 'a:stopped']);
  });

  test('provider follows indexStatusProvider', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final status = StreamController<IndexStatus>.broadcast();
    final container = ProviderContainer(
      overrides: [indexStatusProvider.overrideWith((ref) => status.stream)],
    );
    addTearDown(container.dispose);
    // App watches it (Riverpod 3 pauses unlistened providers).
    final provided = container.listen(inAppJobRunnerProvider, (_, _) {}).read()
      ..register(FakeJob('a', log));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await provided.idle();
    expect(log, isEmpty);
    status.add(const IndexIdle(null));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await provided.idle();
    expect(log, ['a:start', 'a:done']);
  });
}
