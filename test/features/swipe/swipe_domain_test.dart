import 'dart:async';
import 'dart:convert';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/background/serial_lock.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/trash_types.dart';
import 'package:kfm/core/utils/debouncer.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/swipe/ui/swipe_card.dart';
import 'package:kfm/features/undo/domain/previous_state.dart';

void main() {
  group('SwipeAction / SwipeLayout JSON', () {
    test('round-trips actions', () {
      for (final a in [
        SwipeAction.trash,
        SwipeAction.keep,
        const SwipeAction(SwipeActionType.moveTo, targetFolder: '/s/A'),
        const SwipeAction(SwipeActionType.addTag, tagId: 3),
        const SwipeAction(SwipeActionType.sendToDevice, deviceId: 'pc'),
      ]) {
        expect(SwipeAction.fromJson(a.toJson()), a);
      }
    });

    test('round-trips layouts; basic = left trash, right keep', () {
      const custom = SwipeLayout(
        directions: {
          SwipeDirection.up: SwipeAction(
            SwipeActionType.copyTo,
            targetFolder: '/x',
          ),
          SwipeDirection.left: SwipeAction.trash,
        },
        actionBar: [SwipeAction(SwipeActionType.favorite)],
      );
      expect(SwipeLayout.fromJson(custom.toJson()), custom);
      expect(
        SwipeLayout.fromJson(SwipeLayout.basic.toJson()),
        SwipeLayout.basic,
      );
      expect(
        SwipeLayout.basic.actionFor(SwipeDirection.left),
        SwipeAction.trash,
      );
      expect(
        SwipeLayout.basic.actionFor(SwipeDirection.right),
        SwipeAction.keep,
      );
      expect(SwipeLayout.basic.actionFor(SwipeDirection.up), isNull);
    });
  });

  test('PreviousState round-trips every subtype', () {
    final cases = <SwipeActionType, PreviousState>{
      SwipeActionType.keep: const NoPreviousState(),
      SwipeActionType.trash: const TrashPreviousState(
        mode: 'permanent',
        trashedItem: {'trashId': 'ms:1'},
      ),
      SwipeActionType.moveTo: const MovePreviousState(
        folderPath: '/a',
        fileIdBefore: 'ms:1',
      ),
      SwipeActionType.copyTo: const CopyPreviousState(createdFileId: 'ms:2'),
      SwipeActionType.addTag: const TagPreviousState(tagId: 1, hadTag: false),
      SwipeActionType.favorite: const FavoritePreviousState(wasFavorite: true),
      SwipeActionType.renameBatch: const RenamePreviousState(
        batchId: 4,
        op: RenameOp.add,
        added: false,
      ),
    };
    for (final MapEntry(key: type, value: state) in cases.entries) {
      final back = PreviousState.fromJson(type, state.toJson());
      expect(back.runtimeType, state.runtimeType);
      expect(back.toJson(), state.toJson());
    }
  });

  test('TrashedItem round-trips with its FileRef', () {
    final item = TrashedItem(
      trashId: 'ms:9',
      original: FileRef(
        id: 'ms:9',
        uri: 'content://x/9',
        name: 'a.jpg',
        kind: FileKind.image,
        sizeBytes: 10,
        modifiedAt: DateTime.utc(2025),
        takenAt: DateTime.utc(2024),
        folderPath: '/s/DCIM',
        origin: FileOrigin.local,
      ),
      location: TrashLocation.systemTrash,
      trashedAt: DateTime.utc(2026),
      expiresAt: DateTime.utc(2026, 2),
    );
    final back = TrashedItem.fromJson(item.toJson());
    expect(back.original, item.original);
    expect(back.original.takenAt, item.original.takenAt);
    expect(back.expiresAt, item.expiresAt);
    expect(back.location, item.location);
  });

  group('swipe commit rule', () {
    const size = Size(300, 600);
    SwipeDirection? decide(Offset offset, [Offset velocity = Offset.zero]) =>
        SwipeCard.directionFor(offset: offset, velocity: velocity, size: size);

    test('past a third of the width commits', () {
      expect(decide(const Offset(-101, 10)), SwipeDirection.left);
      expect(decide(const Offset(101, -10)), SwipeDirection.right);
      expect(decide(const Offset(-99, 0)), isNull);
    });

    test('a fling commits a short drag; opposite fling does not', () {
      expect(
        decide(const Offset(20, 0), const Offset(900, 0)),
        SwipeDirection.right,
      );
      expect(decide(const Offset(20, 0), const Offset(-900, 0)), isNull);
    });

    test('vertical uses the height', () {
      expect(decide(const Offset(0, -201)), SwipeDirection.up);
      expect(decide(const Offset(0, 150)), isNull);
    });
  });

  test('Debouncer runs only the last action, flushNow runs it at once', () {
    fakeAsync((async) {
      final calls = <int>[];
      final d = Debouncer(const Duration(milliseconds: 300))
        ..run(() => calls.add(1))
        ..run(() => calls.add(2));
      async.elapse(const Duration(milliseconds: 299));
      expect(calls, isEmpty);
      async.elapse(const Duration(milliseconds: 1));
      expect(calls, [2]);
      d
        ..run(() => calls.add(3))
        ..flushNow();
      expect(calls, [2, 3]);
      async.elapse(const Duration(seconds: 1));
      expect(calls, [2, 3]);
    });
  });

  test('SerialLock runs in order and survives a failure', () async {
    final lock = SerialLock();
    final log = <String>[];
    final gate = Completer<void>();
    final a = lock.run(() async {
      await gate.future;
      log.add('a');
    });
    final b = lock.run<void>(() async => throw StateError('b'));
    final c = lock.run(() async => log.add('c'));
    gate.complete();
    await a;
    await expectLater(b, throwsStateError);
    await c;
    expect(log, ['a', 'c']);
  });

  group('SwipeLayout.decode (P1)', () {
    test("'' is basic", () {
      expect(SwipeLayout.decode(''), SwipeLayout.basic);
    });

    test('round-trips a custom layout', () {
      const custom = SwipeLayout(
        directions: {
          SwipeDirection.up: SwipeAction.keep,
          SwipeDirection.down: SwipeAction.trash,
        },
      );
      expect(SwipeLayout.decode(jsonEncode(custom.toJson())), custom);
    });

    test('corrupt data gives basic, never throws', () {
      for (final raw in [
        'not json',
        '[]',
        '{"directions": []}',
        '{"directions": {"left": {"type": "explode"}}}',
        '{"directions": {"left": {}}}',
        '{"directions": {"left": {"type": "addTag", "tagId": "x"}}}',
        '{"directions": {"left": 3}}',
        '{"actionBar": {"a": 1}}',
      ]) {
        expect(SwipeLayout.decode(raw), SwipeLayout.basic, reason: raw);
      }
    });

    test('unknown direction names are skipped', () {
      final layout = SwipeLayout.decode(
        '{"directions": {"left": {"type": "trash"}, "diagonal": '
        '{"type": "keep"}}}',
      );
      expect(layout.directions, {SwipeDirection.left: SwipeAction.trash});
    });

    test('withDirection builds a new layout; hasVertical', () {
      final up = SwipeLayout.basic.withDirection(
        SwipeDirection.up,
        SwipeAction.keep,
      );
      expect(up.hasVertical, isTrue);
      expect(SwipeLayout.basic.hasVertical, isFalse);
      expect(SwipeLayout.basic.directions, hasLength(2));
      expect(up.withDirection(SwipeDirection.up, null), SwipeLayout.basic);
    });
  });

  group('swipe commit rule with vertical actions (P1 diagonal guard)', () {
    const size = Size(300, 600);
    SwipeDirection? decide(Offset offset, [Offset velocity = Offset.zero]) =>
        SwipeCard.directionFor(
          offset: offset,
          velocity: velocity,
          size: size,
          verticalEnabled: true,
        );

    test('the dominant axis must be 1.5x the other', () {
      expect(decide(const Offset(-101, -60)), SwipeDirection.left);
      expect(decide(const Offset(-150, -120)), isNull);
      expect(decide(const Offset(-200, -200)), isNull);
      expect(decide(const Offset(40, -201)), SwipeDirection.up);
      expect(decide(const Offset(0, 201)), SwipeDirection.down);
    });

    test('a quick flick is judged by its velocity', () {
      expect(
        decide(const Offset(2, -3), const Offset(0, -900)),
        SwipeDirection.up,
      );
      expect(decide(const Offset(2, -3), const Offset(900, -900)), isNull);
    });

    test('without vertical actions a diagonal still goes sideways', () {
      expect(
        SwipeCard.directionFor(
          offset: const Offset(-200, -190),
          velocity: Offset.zero,
          size: size,
        ),
        SwipeDirection.left,
      );
    });
  });
}
