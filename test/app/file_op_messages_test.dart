import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/file_op_messages.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/folders/domain/file_operation.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

import '../core/files/fake_file_source.dart';

const _root = '/storage/emulated/0';

void main() {
  final l = lookupAppLocalizations(const Locale('en'));
  final files = FakeFileSource();
  final a = files.addFile('$_root/DCIM/Camera/a.jpg');
  final b = files.addFile('$_root/DCIM/Camera/b.jpg');
  final c = files.addFile('$_root/DCIM/Camera/c.jpg');

  FileOpException e(FileOpFailure f) => FileOpException(f, 'test');

  OpResult ok(FileRef f, [FileRef? after]) => (
    before: f,
    after: after ?? f,
    replaced: null,
    trashed: null,
    error: null,
  );
  OpResult failed(FileRef f, FileOpFailure why) =>
      (before: f, after: null, replaced: null, trashed: null, error: e(why));
  OpResult skipped(FileRef f) =>
      (before: f, after: null, replaced: null, trashed: null, error: null);

  group('fileOpFailureMessage', () {
    test('Browse: each failure has its own text', () {
      String m(FileOpFailure f, [FileOpVerb verb = FileOpVerb.other]) =>
          fileOpFailureMessage(l, e(f), a, verb: verb);
      expect(m(FileOpFailure.notFound), 'a.jpg no longer exists');
      expect(m(FileOpFailure.userCancelled), l.fileOpDeclined);
      expect(m(FileOpFailure.noSpace), l.fileOpNoSpace);
      expect(m(FileOpFailure.permissionDenied), l.fileOpPermission('a.jpg'));
      expect(m(FileOpFailure.unsupported), l.fileOpNeedsAllFiles);
      expect(m(FileOpFailure.invalidName), l.nameInvalid);
      expect(m(FileOpFailure.targetExists), l.nameExists);
      expect(m(FileOpFailure.pendingFolderUnavailable), l.pendingFallbackTitle);
      expect(m(FileOpFailure.ioError), "Couldn't finish for a.jpg");
      expect(m(FileOpFailure.ioError, FileOpVerb.move), "Couldn't move a.jpg");
      expect(m(FileOpFailure.ioError, FileOpVerb.copy), "Couldn't copy a.jpg");
      expect(
        m(FileOpFailure.ioError, FileOpVerb.rename),
        "Couldn't rename a.jpg",
      );
      expect(
        fileOpFailureMessage(l, StateError('x'), a, verb: FileOpVerb.move),
        "Couldn't move a.jpg",
      );
    });

    test('swipe target: P2 texts stay as they were', () {
      String m(Object error, FileOpVerb verb) =>
          fileOpFailureMessage(l, error, a, verb: verb, swipeTarget: true);
      expect(
        m(e(FileOpFailure.notFound), FileOpVerb.move),
        l.fileOpFolderMissing,
      );
      expect(
        m(e(FileOpFailure.userCancelled), FileOpVerb.move),
        l.fileOpDeclined,
      );
      expect(m(e(FileOpFailure.noSpace), FileOpVerb.copy), l.fileOpNoSpace);
      expect(
        m(e(FileOpFailure.permissionDenied), FileOpVerb.move),
        l.fileOpNeedsAllFiles,
      );
      expect(
        m(e(FileOpFailure.unsupported), FileOpVerb.copy),
        l.fileOpNeedsAllFiles,
      );
      expect(
        m(e(FileOpFailure.ioError), FileOpVerb.copy),
        "Couldn't copy a.jpg",
      );
      expect(m(StateError('x'), FileOpVerb.move), "Couldn't move a.jpg");
    });
  });

  test('spaceRefusedMessage formats both sizes', () {
    expect(
      spaceRefusedMessage(l, needed: 3 << 30, free: 1 << 30),
      'Not enough space (needs 3 GB, 1 GB free)',
    );
  });

  group('operationSummary', () {
    CompletedOperation done(
      FileOperation op,
      List<OpResult> results, {
      bool cancelled = false,
    }) => CompletedOperation(op: op, results: results, cancelled: cancelled);

    test('move with a failure and a skip', () {
      final op = MoveOp([a, b, c], '$_root/DCIM/Holiday');
      expect(
        operationSummary(
          l,
          done(op, [ok(a), failed(b, FileOpFailure.ioError), skipped(c)]),
        ),
        'Moved 1 file to Holiday · 1 failed · 1 skipped',
      );
    });

    test('copy into a volume root uses its friendly name', () {
      expect(
        operationSummary(l, done(CopyOp([a, b], _root), [ok(a), ok(b)])),
        'Copied 2 files to Internal storage',
      );
    });

    test('duplicate, rename, trash and permanent delete', () {
      expect(
        operationSummary(l, done(DuplicateOp([a]), [ok(a)])),
        'Duplicated 1 file',
      );
      final renamed = files.addFile('$_root/DCIM/Camera/beach.jpg');
      expect(
        operationSummary(l, done(RenameOp(a, 'beach.jpg'), [ok(a, renamed)])),
        'Renamed to beach.jpg',
      );
      final trashed = [
        (before: a, after: null, replaced: null, trashed: null, error: null),
        (before: b, after: null, replaced: null, trashed: null, error: null),
      ];
      expect(
        operationSummary(l, done(DeleteOp([a, b], permanent: false), trashed)),
        'Moved 2 files to trash',
      );
      expect(
        operationSummary(
          l,
          done(DeleteOp([a, b, c], permanent: true), [
            ...trashed,
            failed(c, FileOpFailure.permissionDenied),
          ]),
        ),
        'Deleted 2 files permanently · 1 failed',
      );
    });

    test('a single failed file gets its failure message', () {
      expect(
        operationSummary(
          l,
          done(MoveOp([a], '$_root/DCIM/Holiday'), [
            failed(a, FileOpFailure.notFound),
          ]),
        ),
        'a.jpg no longer exists',
      );
    });

    test('cancelled: "Stopped: done of total"', () {
      expect(
        operationSummary(
          l,
          done(MoveOp([a, b, c], '$_root/DCIM/Holiday'), [
            ok(a),
          ], cancelled: true),
        ),
        'Stopped: 1 of 3 done',
      );
    });

    test('stopped early by no space: counts the untouched files', () {
      final op = CopyOp([a, b, c], '$_root/DCIM/Holiday');
      final stopped = CompletedOperation(
        op: op,
        results: [ok(a), failed(b, FileOpFailure.noSpace)],
        cancelled: false,
        stoppedEarly: true,
      );
      expect(stopped.notProcessed, 1);
      expect(
        operationSummary(l, stopped),
        'Stopped: 1 of 3 done · 1 failed · ${l.fileOpNoSpace}',
      );
    });
  });
}
