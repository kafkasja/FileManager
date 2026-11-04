import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/background_jobs/data/job_progress_aggregator.dart';
import 'package:kfm/features/background_jobs/domain/job_progress.dart';

JobProgress _job(
  String key, {
  JobPhase phase = JobPhase.running,
  int done = 0,
  int total = 1000,
}) => JobProgress(
  key: key,
  kind: JobKind.send,
  target: const DeviceTarget('PC'),
  phase: phase,
  files: 1,
  bytesDone: done,
  bytesTotal: total,
);

void main() {
  test('progress publishes at most once a second; shape changes at once', () {
    fakeAsync((async) {
      final start = DateTime(2026);
      final agg = JobProgressAggregator(clock: () => start.add(async.elapsed));
      final out = <JobsSnapshot>[];
      agg.snapshots.listen(out.add);

      agg.update('t', [_job('t:1')]);
      async.flushMicrotasks();
      expect(out, hasLength(1)); // a new job: at once

      // Ten byte updates in 0.9 s: nothing until the second is over.
      for (var i = 1; i <= 9; i++) {
        async.elapse(const Duration(milliseconds: 100));
        agg.update('t', [_job('t:1', done: i * 10)]);
      }
      async.flushMicrotasks();
      expect(out, hasLength(1));
      async.elapse(const Duration(milliseconds: 150));
      expect(out, hasLength(2));
      expect(out.last.jobs.single.bytesDone, 90);

      // Pausing is a shape change: published at once.
      async.elapse(const Duration(milliseconds: 100));
      agg.update('t', [_job('t:1', done: 90, phase: JobPhase.paused)]);
      async.flushMicrotasks();
      expect(out, hasLength(3));
      expect(out.last.paused, hasLength(1));
      expect(out.last.anyRunning, isFalse);

      // Over 20 s of steady updates every 100 ms: ~1 per second.
      out.clear();
      for (var i = 0; i < 200; i++) {
        async.elapse(const Duration(milliseconds: 100));
        agg.update('t', [_job('t:1', done: 100 + i)]);
      }
      async.elapse(const Duration(seconds: 2));
      expect(out.length, inInclusiveRange(19, 22));
    });
  });

  test('speed over the last seconds', () {
    fakeAsync((async) {
      final start = DateTime(2026);
      final agg = JobProgressAggregator(clock: () => start.add(async.elapsed));
      for (var i = 0; i <= 10; i++) {
        agg.update('t', [_job('t:1', done: i * 500, total: 100000)]);
        async.elapse(const Duration(seconds: 1));
      }
      agg.update('t', [_job('t:1', done: 5500, total: 100000)]);
      // 500 B/s steady.
      expect(agg.current.bytesPerSecond, closeTo(500, 60));
      expect(agg.current.timeLeft!.inSeconds, closeTo(189, 25));
    });
  });

  test('ends are reported once, only for jobs seen active; cancelled too', () {
    final agg = JobProgressAggregator();
    final ends = <JobEnd>[];
    agg.ends.listen(ends.add);
    // An old finished job (history): no end.
    agg
      ..update('t', [_job('t:old', phase: JobPhase.done)])
      ..update('t', [_job('t:old', phase: JobPhase.done), _job('t:1')])
      ..update('l', [_job('l:1', phase: JobPhase.paused)])
      ..update('l', [_job('l:1')])
      ..update('l', [_job('l:1', phase: JobPhase.paused)])
      ..update('t', [
        _job('t:old', phase: JobPhase.done),
        _job('t:1', phase: JobPhase.failed),
      ])
      ..update('t', [
        _job('t:old', phase: JobPhase.done),
        _job('t:1', phase: JobPhase.failed),
      ])
      ..update('l', [_job('l:1', phase: JobPhase.cancelled)]);
    return Future<void>.delayed(Duration.zero, () {
      expect([for (final e in ends) e.job.key], ['t:1', 'l:1']);
      expect(ends.first.job.phase, JobPhase.failed);
      expect(agg.current.isEmpty, isTrue);
    });
  });

  test('a job paused before this run is not listed', () {
    final agg = JobProgressAggregator()
      ..update('t', [_job('t:old', phase: JobPhase.paused)]);
    expect(agg.current.isEmpty, isTrue);
  });

  test('sources are merged', () {
    final agg = JobProgressAggregator()
      ..update('t', [_job('t:1')])
      ..update('l', [_job('l:1')])
      ..update('l', [_job('l:1', phase: JobPhase.paused)])
      ..update('i', [_job('i:1', done: 5)]);
    expect([for (final j in agg.current.jobs) j.key], ['t:1', 'l:1', 'i:1']);
    expect(agg.current.running, hasLength(2));
    agg.update('i', const []);
    expect(agg.current.jobs, hasLength(2));
  });
}
