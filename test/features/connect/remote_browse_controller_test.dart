// The fakeAsync tests start futures and flush them with the fake clock.
// ignore_for_file: discarded_futures

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/connect/data/remote_file_source.dart';
import 'package:kfm/features/connect/data/remote_source_provider.dart';
import 'package:kfm/features/connect/domain/files_protocol.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:kfm/features/connect/ui/remote_browse_controller.dart';
import 'package:kfm/features/connect/ui/remote_connection_controller.dart';

import 'fake_remote_http.dart';

const _fp = 'ab12';
const _pageSize = 2;

/// The other device's listing of root R1: [files] served [_pageSize] at a
/// time (cursor = start index).
class _Server {
  new(this.http) {
    http
      ..on('GET', ApiRoutes.files, (c) {
        filesCalls++;
        final fail = failNext;
        if (fail != null) {
          failNext = null;
          // ignore: only_throw_errors, the test decides what to throw
          throw fail;
        }
        final q = RemoteQueryDto.decode(c.query['q']!);
        queries.add(q);
        final start = int.parse(c.query['cursor'] ?? '0');
        final end = (start + _pageSize).clamp(0, files.length);
        return FilePageDto(
          items: files.sublist(start, end),
          nextCursor: end < files.length ? '$end' : null,
          total: c.query['cursor'] == null ? files.length : null,
        ).toJson();
      })
      ..on('GET', ApiRoutes.folders, (_) {
        foldersCalls++;
        return FoldersResponseDto(folders).toJson();
      });
  }

  final FakeRemoteHttp http;
  List<RemoteFileDto> files = [];
  List<RemoteFolderDto> folders = const [];
  final List<RemoteQueryDto> queries = [];
  int filesCalls = 0;
  int foldersCalls = 0;
  Object? failNext;
}

RemoteFileDto _f(int i, {int modified = 1000, String? name}) => RemoteFileDto(
  id: 'ms:$i',
  name: name ?? 'f$i.jpg',
  kind: FileKind.image,
  sizeBytes: 10,
  modifiedAtMs: modified,
  rootId: 'R1',
  relativeFolder: '',
);

void main() {
  late FakeRemoteHttp http;
  late _Server server;
  late ProviderContainer container;
  late List<AsyncValue<RemoteBrowseState>> states;
  var connected = true;

  RemoteBrowseController ctl() =>
      container.read(remoteBrowseControllerProvider(_fp).notifier);
  RemoteBrowseState state() =>
      container.read(remoteBrowseControllerProvider(_fp)).requireValue;
  void token(String? t) =>
      container.read(remoteChangeTokenProvider.notifier).publish(t);

  void start(FakeAsync async) {
    connected = true;
    http = FakeRemoteHttp();
    server = _Server(http)
      ..files = [for (var i = 0; i < 5; i++) _f(i)]
      ..folders = const [
        RemoteFolderDto(name: 'sub', relativePath: 'sub', fileCount: 2),
      ];
    final source = RemoteFileSource(peerFingerprint: _fp, http: () => http);
    container = ProviderContainer(
      overrides: [
        remoteSourceProvider(_fp).overrideWithValue(source),
        remotePeerConnectedProvider(_fp).overrideWith((ref) => connected),
      ],
    );
    states = [];
    // Riverpod 3 pauses unlistened providers: the screen listens.
    container.listen(
      remoteBrowseControllerProvider(_fp),
      (_, next) => states.add(next),
    );
    async.flushMicrotasks();
    ctl().openRoot('R1');
    async.flushMicrotasks();
  }

  void end() => container.dispose();

  test('roots first; opening a root lists folders and the first page', () {
    fakeAsync((async) {
      start(async);
      final s = state();
      expect(s.view.rootId, 'R1');
      expect(s.items.map((f) => f.id), [
        'remote:$_fp:ms:0',
        'remote:$_fp:ms:1',
      ]);
      expect(s.folders.single.name, 'sub');
      expect(s.total, 5);
      expect(s.hasMore, isTrue);
      ctl().loadMore();
      async.flushMicrotasks();
      expect(state().items, hasLength(4));
      end();
    });
  });

  test('sort, kinds and folders go into the query; up() walks back', () {
    fakeAsync((async) {
      start(async);
      ctl()
        ..setSort(const FileSort(FileSortField.size))
        ..setKind(FileKind.video);
      async.flushMicrotasks();
      final q = server.queries.last;
      expect(q.sort.field, FileSortField.size);
      expect(q.kinds, {FileKind.video});
      ctl().openFolder('sub/deeper');
      async.flushMicrotasks();
      expect(server.queries.last.path, 'sub/deeper');
      expect(ctl().up(), isTrue);
      async.flushMicrotasks();
      expect(state().view.path, 'sub');
      ctl().up();
      async.flushMicrotasks();
      expect(state().view.path, '');
      ctl().up();
      async.flushMicrotasks();
      expect(state().view.atRoots, isTrue);
      expect(ctl().up(), isFalse);
      end();
    });
  });

  test(
    'a token change → one refetch after 500 ms keeping the loaded count',
    () {
      fakeAsync((async) {
        start(async);
        ctl().loadMore();
        async.flushMicrotasks();
        expect(state().items, hasLength(4));
        // First token: nothing to compare with.
        token('t1');
        async.elapse(const Duration(seconds: 1));
        expect(server.filesCalls, 2);

        // Something new on the other device, at the top.
        server.files = [_f(9), ...server.files];
        token('t2');
        async.elapse(const Duration(milliseconds: 499));
        expect(server.filesCalls, 2);
        async
          ..elapse(const Duration(milliseconds: 1))
          ..flushMicrotasks();
        // Re-paged from the start until ≥ 4 items: 2 pages.
        expect(server.filesCalls, 4);
        expect(server.foldersCalls, 2);
        final s = state();
        expect(s.items, hasLength(4));
        expect(s.items.first.id, 'remote:$_fp:ms:9');
        expect(s.total, 6);
        expect(s.hasMore, isTrue);
        end();
      });
    },
  );

  test('an identical page changes no state', () {
    fakeAsync((async) {
      start(async);
      token('t1');
      async.flushMicrotasks();
      final before = states.length;
      final items = state().items;
      token('t2');
      async.elapse(const Duration(seconds: 1));
      expect(server.filesCalls, 2);
      expect(states.length, before);
      expect(identical(state().items, items), isTrue);
      end();
    });
  });

  test('a changed file (modified time) replaces the items', () {
    fakeAsync((async) {
      start(async);
      token('t1');
      server.files = [_f(0, modified: 2000), ...server.files.skip(1)];
      token('t2');
      async.elapse(const Duration(seconds: 1));
      expect(state().items.first.modifiedAt.millisecondsSinceEpoch, 2000);
      end();
    });
  });

  test('a failed refresh keeps the old items', () {
    fakeAsync((async) {
      start(async);
      final items = state().items;
      token('t1');
      server
        ..files = [_f(7)]
        ..failNext = const FileOpException(FileOpFailure.ioError, 'x');
      token('t2');
      async.elapse(const Duration(seconds: 1));
      expect(identical(state().items, items), isTrue);
      expect(
        container.read(remoteBrowseControllerProvider(_fp)).hasError,
        isFalse,
      );
      end();
    });
  });

  test('not connected → AsyncError(unavailable)', () {
    fakeAsync((async) {
      start(async);
      connected = false;
      container.invalidate(remotePeerConnectedProvider(_fp));
      async.elapse(const Duration(milliseconds: 10));
      final v = container.read(remoteBrowseControllerProvider(_fp));
      expect(v.isLoading, isFalse);
      expect(
        v.error,
        isA<FileOpException>().having(
          (e) => e.failure,
          'failure',
          FileOpFailure.unavailable,
        ),
      );
      end();
    });
  });

  test('rename / move / trash update the list at once', () {
    fakeAsync((async) {
      start(async);
      http
        ..on(
          'POST',
          ApiRoutes.fileRename('ms:0'),
          (_) => _f(0, name: 'new.jpg').toJson(),
        )
        ..on(
          'POST',
          ApiRoutes.fileMove('ms:1'),
          (_) => const RemoteFileDto(
            id: 'ms:1',
            name: 'f1.jpg',
            kind: FileKind.image,
            sizeBytes: 10,
            modifiedAtMs: 1000,
            rootId: 'R1',
            relativeFolder: 'sub',
          ).toJson(),
        )
        ..on(
          'POST',
          ApiRoutes.filesTrash,
          (_) => const TrashResponseDto(
            trashed: [
              RemoteTrashedDto(
                id: 'ms:0',
                trashId: 'ms:0',
                location: 'systemTrash',
                trashedAtMs: 1,
              ),
            ],
          ).toJson(),
        );
      final items = state().items;
      ctl().rename(items[0], 'new.jpg');
      async.flushMicrotasks();
      expect(state().items.first.name, 'new.jpg');
      ctl().move([items[1]], 'R1/sub');
      async.flushMicrotasks();
      expect(state().items.map((f) => f.id), ['remote:$_fp:ms:0']);
      ctl().trash([state().items.first]);
      async.flushMicrotasks();
      expect(state().items, isEmpty);
      end();
    });
  });
}
