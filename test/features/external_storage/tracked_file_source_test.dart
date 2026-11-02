import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/routing_file_source.dart';
import 'package:kfm/features/external_storage/data/tracked_file_source.dart';
import 'package:kfm/features/external_storage/data/volume_activity_tracker.dart';

import '../../core/files/fake_file_source.dart';

/// Holds every move/trash until [gate] completes; reads never end on
/// their own.
class _GatedSource extends FakeFileSource {
  Completer<void> gate = Completer<void>();
  final reads = <StreamController<List<int>>>[];

  @override
  Future<FileRef> move(FileRef f, String targetFolder) async {
    await gate.future;
    return await super.move(f, targetFolder);
  }

  @override
  Stream<List<int>> openRead(FileRef f, {int start = 0, int? end}) {
    final c = StreamController<List<int>>();
    reads.add(c);
    return c.stream;
  }
}

void main() {
  const sd = '/storage/1234-ABCD';
  late ProviderContainer container;
  late VolumeActivityTracker tracker;
  late _GatedSource inner;
  late TrackedFileSource fs;
  late FileRef photo;
  VolumeActivity state() => container.read(volumeActivityTrackerProvider);

  setUp(() {
    container = ProviderContainer();
    tracker = container.read(volumeActivityTrackerProvider.notifier);
    inner = _GatedSource()..addFolder('/storage/emulated/0/Pictures');
    photo = inner.addFile('$sd/DCIM/a.jpg');
    fs = TrackedFileSource(inner: inner, tracker: tracker);
  });
  tearDown(() => container.dispose());

  test('a move counts both places while it runs (primary never)', () async {
    final move = fs.move(photo, '/storage/emulated/0/Pictures');
    await pumpEventQueue();
    expect(state().open, {'1234-ABCD': 1});
    inner.gate.complete();
    await move;
    expect(state().open, isEmpty);
  });

  test('batches and single ops are counted and released', () async {
    await fs.trashBatch([photo]);
    await fs.createFolder('$sd/DCIM', 'x');
    expect(state().open, isEmpty);
    expect(inner.calls, contains('createFolder $sd/DCIM x'));
  });

  test(
    'new work is refused while ejecting, no call reaches the source',
    () async {
      tracker.beginEject('1234-ABCD');
      await expectLater(
        fs.createFolder('$sd/DCIM', 'y'),
        throwsA(
          isA<FileOpException>().having(
            (e) => e.failure,
            'failure',
            FileOpFailure.volumeEjecting,
          ),
        ),
      );
      expect(inner.calls, isNot(contains('createFolder $sd/DCIM y')));
      // Internal storage still works.
      await fs.createFolder('/storage/emulated/0/Pictures', 'ok');
    },
  );

  test('a read stream counts from listen until cancel', () async {
    final sub = fs.openRead(photo).listen((_) {});
    await pumpEventQueue();
    expect(state().activeCount('1234-ABCD'), 1);
    await sub.cancel();
    expect(state().activeCount('1234-ABCD'), 0);
  });

  test('a read stream is released when it ends', () async {
    final done = fs.openRead(photo).toList();
    await pumpEventQueue();
    expect(state().activeCount('1234-ABCD'), 1);
    inner.reads.single
      ..add([1])
      ..close().ignore();
    expect(await done, [
      [1],
    ]);
    expect(state().activeCount('1234-ABCD'), 0);
  });

  test('beginEject ends open reads with volumeEjecting', () async {
    final errors = <Object>[];
    final done = Completer<void>();
    fs
        .openRead(photo)
        .listen((_) {}, onError: errors.add, onDone: done.complete);
    await pumpEventQueue();
    tracker.beginEject('1234-ABCD');
    await done.future;
    expect(errors.single, isA<FileOpException>());
    expect(state().activeCount('1234-ABCD'), 0);
    expect(inner.reads.single.hasListener, isFalse);
  });

  test('scans with a root are tracked; full scans are not', () async {
    await fs.scan(query: const FileQuery(rootPath: sd)).toList();
    tracker.beginEject('1234-ABCD');
    await expectLater(
      fs.scan(query: const FileQuery(rootPath: sd)).toList(),
      throwsA(isA<FileOpException>()),
    );
    await fs.scan().toList(); // every volume: not refused
  });

  test('routingOf unwraps the decorator', () {
    expect(routingOf(fs), isNull); // inner is a fake, not routing
    expect(fs.inner, same(inner));
  });
}
