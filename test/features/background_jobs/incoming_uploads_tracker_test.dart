import 'dart:async';
import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/background_jobs/data/incoming_uploads_tracker.dart';
import 'package:kfm/features/background_jobs/domain/job_progress.dart';
import 'package:kfm/features/connect/data/upload_store.dart';

UploadActivity _a(
  String id,
  UploadPhase phase, {
  String owner = 'fpA',
  int size = 100,
  int received = 0,
}) => UploadActivity(
  uploadId: id,
  ownerFingerprint: owner,
  name: '$id.jpg',
  size: size,
  received: received,
  phase: phase,
);

void main() {
  test('groups uploads per sender; ends after the idle time', () {
    fakeAsync((async) {
      final start = DateTime(2026);
      final activity = StreamController<UploadActivity>.broadcast(sync: true);
      final tracker = IncomingUploadsTracker(
        activity: activity.stream,
        nameOf: (fp) => fp == 'fpA' ? 'Pixel' : 'PC',
        clock: () => start.add(async.elapsed),
      );
      final out = <List<JobProgress>>[];
      tracker.jobs.listen(out.add);

      activity
        ..add(_a('u1', UploadPhase.progressed, received: 40))
        ..add(_a('u2', UploadPhase.progressed, size: 50, received: 10))
        ..add(_a('v1', UploadPhase.progressed, owner: 'fpB', received: 5));
      async.flushMicrotasks();
      final now = out.last;
      expect(now, hasLength(2));
      final a = now.firstWhere((j) => j.target == const DeviceTarget('Pixel'));
      expect(a.kind, JobKind.incoming);
      expect(a.files, 2);
      expect(a.bytesDone, 50);
      expect(a.bytesTotal, 150);
      expect(a.controllable, isFalse);

      activity
        ..add(_a('u1', UploadPhase.completed, received: 100))
        ..add(_a('u2', UploadPhase.completed, size: 50, received: 50));
      async.elapse(const Duration(seconds: 10));
      // Pixel's group ended (done, 2 files); PC's is still open.
      final ended = out
          .expand((l) => l)
          .where((j) => j.phase == JobPhase.done)
          .toList();
      expect(ended, hasLength(1));
      expect(ended.single.filesDone, 2);
      expect(tracker.current, hasLength(1));

      // PC stalls (no chunk for 45 s): its group ends without a file.
      async.elapse(const Duration(seconds: 50));
      final cancelled = out
          .expand((l) => l)
          .where((j) => j.phase == JobPhase.cancelled);
      expect(cancelled, hasLength(1));
      expect(tracker.current, isEmpty);
      unawaited(tracker.dispose());
    });
  });

  test('UploadStore publishes progress, completion and removal', () async {
    final dir = await Directory.systemTemp.createTemp('kfm_up_');
    addTearDown(() => dir.delete(recursive: true));
    final store = UploadStore(staging: () async => dir);
    final seen = <(String, UploadPhase, int)>[];
    store.activity.listen((a) => seen.add((a.uploadId, a.phase, a.received)));
    final u = await store.create(
      uploadId: 'a',
      ownerFingerprint: 'fp',
      rootId: 'r',
      path: '',
      name: 'x.bin',
      size: 10,
    );
    u.received = 4;
    await store.saveMeta(u);
    await store.completed(u, finalId: 'f');
    final v = await store.create(
      uploadId: 'b',
      ownerFingerprint: 'fp',
      rootId: 'r',
      path: '',
      name: 'y.bin',
      size: 10,
    );
    await store.remove(v.uploadId);
    expect(seen, [
      ('a', UploadPhase.progressed, 0),
      ('a', UploadPhase.progressed, 4),
      ('a', UploadPhase.completed, 10),
      ('b', UploadPhase.progressed, 0),
      ('b', UploadPhase.removed, 0),
    ]);
  });
}
