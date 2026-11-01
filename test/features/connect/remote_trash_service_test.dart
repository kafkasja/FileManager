import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/background/serial_lock.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/trash_types.dart';
import 'package:kfm/features/connect/data/remote_trash_service.dart';

import '../../core/files/fake_file_source.dart';

const RemoteCaller _pixel = (
  sessionId: 's1',
  clientFingerprint: 'fp',
  clientName: 'Pixel',
);

/// A source whose trash dialog the test answers.
class _DialogSource extends FakeFileSource {
  Completer<bool>? dialog;
  bool autoAnswer = false;

  /// Ids whose chunk throws (not a per-file failure).
  Set<String> throwFor = {};

  @override
  Future<TrashResult> trashBatch(List<FileRef> files) async {
    if (files.any((f) => throwFor.contains(f.id))) {
      throw const FileOpException(FileOpFailure.ioError, 'boom');
    }
    if (autoAnswer) return await super.trashBatch(files);
    final d = dialog = Completer<bool>();
    if (!await d.future) {
      throw const FileOpException(FileOpFailure.userCancelled, 'declined');
    }
    return await super.trashBatch(files);
  }
}

void main() {
  late _DialogSource source;
  late SerialLock lock;
  late List<RemoteRequestNotice?> notices;
  late List<RemoteRequestOutcome> outcomes;
  late List<List<String>> removed;
  late RemoteTrashService service;
  late Set<String> alive;

  setUp(() {
    source = _DialogSource();
    lock = SerialLock();
    notices = [];
    outcomes = [];
    removed = [];
    alive = {'s1'};
    service = RemoteTrashService(
      sessionAlive: alive.contains,
      source: () => source,
      lock: lock,
      onNotice: notices.add,
      onOutcome: outcomes.add,
      removeFromIndex: (ids) async => removed.add(ids),
    );
  });
  tearDown(() => source.dispose());

  test('waits for the history lock; the banner shows while the dialog is '
      'open; never deletes permanently', () async {
    final f = source.addFile('/s/DCIM/a.jpg');
    final own = Completer<void>();
    unawaited(lock.run(() => own.future));
    final done = service.trash([f], caller: _pixel);
    await pumpEventQueue();
    expect(source.dialog, isNull, reason: 'own delete commit still running');
    own.complete();
    await pumpEventQueue();
    expect(notices.single?.deviceName, 'Pixel');
    expect(notices.single?.count, 1);
    source.dialog!.complete(true);
    final result = await done;
    expect(result.trashed.single.original.id, f.id);
    expect(notices.last, isNull);
    expect(removed.single, [f.id]);
    expect(outcomes.single.declined, isFalse);
    expect(
      source.calls.where((c) => c.startsWith('deletePermanently')),
      isEmpty,
    );
  });

  test(
    'a declined dialog is userCancelled; files stay; index untouched',
    () async {
      final f = source.addFile('/s/DCIM/a.jpg');
      final done = service.trash([f], caller: _pixel);
      await pumpEventQueue();
      source.dialog!.complete(false);
      final result = await done;
      expect(result.userCancelled, isTrue);
      expect(await source.stat(f.id), isNotNull);
      expect(removed, isEmpty);
      expect(outcomes.single.declined, isTrue);
      expect(notices.last, isNull);
    },
  );

  test('a request whose session ended while waiting is dropped', () async {
    final f = source.addFile('/s/DCIM/a.jpg');
    final own = Completer<void>();
    unawaited(lock.run(() => own.future));
    final done = service.trash([f], caller: _pixel);
    alive.clear();
    own.complete();
    await expectLater(done, throwsA(isA<RemoteRequestDropped>()));
    expect(source.dialog, isNull);
    expect(notices, isEmpty);
  });

  test('one waiting trash/write-access request per client', () async {
    final f = source.addFile('/s/DCIM/a.jpg');
    final first = service.trash([f], caller: _pixel);
    await expectLater(
      service.requestWriteAccess([f], caller: _pixel),
      throwsA(isA<RemoteBusyException>()),
    );
    await pumpEventQueue();
    source.dialog!.complete(true);
    await first;
    // Free again afterwards.
    expect(await service.requestWriteAccess([f], caller: _pixel), isTrue);
  });

  test(
    'a failing chunk is reported per id; trashed ones still count',
    () async {
      source.autoAnswer = true;
      final files = [
        for (var i = 0; i < RemoteTrashService.chunk + 1; i++)
          source.addFile('/s/DCIM/f$i.jpg'),
      ];
      source.throwFor = {files.last.id};
      final result = await service.trash(files, caller: _pixel);
      expect(result.trashed, hasLength(RemoteTrashService.chunk));
      expect(result.failed.keys, [files.last.id]);
      expect(removed.single, hasLength(RemoteTrashService.chunk));
      expect(outcomes.single.count, RemoteTrashService.chunk);
      expect(notices.last, isNull);
    },
  );
}
