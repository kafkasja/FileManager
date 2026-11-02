import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/background/serial_lock.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/connect/data/pinned_client.dart';
import 'package:kfm/features/connect/data/remote_errors.dart';
import 'package:kfm/features/connect/domain/files_protocol.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:kfm/features/transfers/data/verified_move_impl.dart';
import 'package:kfm/features/transfers/domain/verified_move.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';

import '../../core/files/fake_file_source.dart';

final String _sha = 'a' * 64;

VerifiedOriginal _orig(FileRef f) => VerifiedOriginal(
  original: f,
  proof: Verified(sha256: _sha, sizeBytes: f.sizeBytes),
  modifiedAtMsAtCopy: f.modifiedAt.millisecondsSinceEpoch,
);

/// Answers `POST /v1/files/trash` only.
class _TrashHttp implements RemoteHttp {
  new(this.answer);

  final Map<String, Object?> Function(Map<String, Object?> body) answer;
  final List<Map<String, Object?>> bodies = [];

  @override
  Future<T> postJson<T>(
    String path,
    Object? body, {
    required T Function(Map<String, Object?> json) decode,
    Duration? timeout,
  }) async {
    expect(path, ApiRoutes.filesTrash);
    final b = body! as Map<String, Object?>;
    bodies.add(b);
    return decode(answer(b));
  }

  @override
  Object? noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  late FakeFileSource source;
  late List<List<String>> unindexed;
  late LocalVerifiedMove mover;

  setUp(() {
    source = FakeFileSource();
    unindexed = [];
    mover = LocalVerifiedMove(
      source: source,
      lock: SerialLock(),
      removeFromIndex: (ids) async => unindexed.add(ids),
    );
  });

  tearDown(() => source.dispose());

  test('compareCopy: equal → Verified; other hash or size → Mismatch; a '
      'missing hash → unavailable', () {
    expect(
      compareCopy(
        sourceSha256: _sha,
        sourceSize: 3,
        copySha256: _sha,
        copySize: 3,
      ),
      isA<Verified>(),
    );
    expect(
      compareCopy(
        sourceSha256: _sha,
        sourceSize: 3,
        copySha256: 'b' * 64,
        copySize: 3,
      ),
      isA<Mismatch>(),
    );
    expect(
      compareCopy(
        sourceSha256: _sha,
        sourceSize: 3,
        copySha256: _sha,
        copySize: 4,
      ),
      isA<Mismatch>(),
    );
    expect(
      compareCopy(
        sourceSha256: null,
        sourceSize: 3,
        copySha256: _sha,
        copySize: 3,
      ),
      isA<VerifyUnavailable>(),
    );
  });

  test('trash mode: one trashBatch for every original; they leave the '
      'index', () async {
    final a = source.addFile('/d/a.jpg');
    final b = source.addFile('/d/b.jpg');
    final r = await mover.deleteOriginals([
      _orig(a),
      _orig(b),
    ], mode: DeleteMode.trash);
    expect(source.calls, ['trashBatch ${a.id},${b.id}']);
    expect(r.outcomes, {
      a.id: SourceOutcome.trashed,
      b.id: SourceOutcome.trashed,
    });
    expect(source.trash, hasLength(2));
    expect(unindexed, [
      [a.id, b.id],
    ]);
  });

  test('permanent mode: one deletePermanentlyBatch', () async {
    final a = source.addFile('/d/a.jpg');
    final r = await mover.deleteOriginals([
      _orig(a),
    ], mode: DeleteMode.permanent);
    expect(source.calls, ['deletePermanentlyBatch ${a.id}']);
    expect(r.outcomes[a.id], SourceOutcome.deletedPermanently);
    expect(source.trash, isEmpty);
  });

  test('a changed original is kept, a gone one is reported, neither is '
      'deleted', () async {
    final a = source.addFile('/d/a.jpg');
    final copyOfA = _orig(a);
    // Edited after the copy: other size and time.
    source
      ..removeExternally(a.id)
      ..addFile(
        '/d/a.jpg',
        bytes: const [9, 9, 9, 9],
        modifiedAt: DateTime.utc(2030),
      );
    final gone = source.addFile('/d/g.jpg');
    final goneOrig = _orig(gone);
    source.removeExternally(gone.id);
    final r = await mover.deleteOriginals([
      copyOfA,
      goneOrig,
    ], mode: DeleteMode.trash);
    expect(r.outcomes, {
      a.id: SourceOutcome.keptChanged,
      gone.id: SourceOutcome.alreadyGone,
    });
    expect(source.calls.where((c) => c.startsWith('trashBatch')), isEmpty);
    expect(await source.stat(a.id), isNotNull);
  });

  test('a declined dialog keeps every original (keptDeclined)', () async {
    final a = source.addFile('/d/a.jpg');
    final b = source.addFile('/d/b.jpg');
    source.declineDeletes = true;
    final r = await mover.deleteOriginals([
      _orig(a),
      _orig(b),
    ], mode: DeleteMode.trash);
    expect(r.outcomes.values, everyElement(SourceOutcome.keptDeclined));
    expect(await source.stat(a.id), isNotNull);
    final p = await mover.deleteOriginals([
      _orig(a),
    ], mode: DeleteMode.permanent);
    expect(p.outcomes[a.id], SourceOutcome.keptDeclined);
    expect(await source.stat(a.id), isNotNull);
    expect(unindexed, isEmpty);
  });

  test('pending folder unavailable → keptFailed with the reason', () async {
    final a = source.addFile('/d/a.jpg');
    source.folderUnavailable.add(a.id);
    final r = await mover.deleteOriginals([_orig(a)], mode: DeleteMode.trash);
    expect(r.outcomes[a.id], SourceOutcome.keptFailed);
    expect(r.errors[a.id], 'pendingFolderUnavailable');
  });

  group('trashRemoteOriginals', () {
    test('one verifiedMove request with hashes and sizes; outcomes per '
        'id', () async {
      final http = _TrashHttp(
        (b) => {
          'trashed': [
            {
              'id': 'ms:1',
              'trashId': 't1',
              'location': 'systemTrash',
              'trashedAtMs': 1,
            },
          ],
          'failed': {'ms:2': 'verification_failed', 'ms:3': 'not_found'},
        },
      );
      final r = await trashRemoteOriginals(http, [
        (serverId: 'ms:1', sha256: _sha, sizeBytes: 3),
        (serverId: 'ms:2', sha256: _sha, sizeBytes: 4),
        (serverId: 'ms:3', sha256: _sha, sizeBytes: 5),
      ]);
      expect(http.bodies, hasLength(1));
      final body = TrashRequestDto.fromJson(http.bodies.single);
      expect(body.reason, TrashReason.verifiedMove);
      expect(body.sizeById, {'ms:1': 3, 'ms:2': 4, 'ms:3': 5});
      expect(body.sha256ById['ms:2'], _sha);
      expect(r.outcomes, {
        'ms:1': SourceOutcome.trashed,
        'ms:2': SourceOutcome.keptChanged,
        'ms:3': SourceOutcome.alreadyGone,
      });
    });

    test('declined on the other device → keptDeclined; a refusal → '
        'keptFailed', () async {
      final declined = await trashRemoteOriginals(
        _TrashHttp((_) => {'trashed': <Object?>[], 'userCancelled': true}),
        [(serverId: 'ms:1', sha256: _sha, sizeBytes: 3)],
      );
      expect(declined.outcomes['ms:1'], SourceOutcome.keptDeclined);
      final refused = await trashRemoteOriginals(
        _TrashHttp(
          (_) => throw RemoteApiException(
            403,
            ApiErrorDto(ApiErrorCode.forbiddenPath.wire, ''),
          ),
        ),
        [(serverId: 'ms:1', sha256: _sha, sizeBytes: 3)],
      );
      expect(refused.outcomes['ms:1'], SourceOutcome.keptFailed);
      expect(refused.errors['ms:1'], 'forbidden_path');
    });
  });
}
