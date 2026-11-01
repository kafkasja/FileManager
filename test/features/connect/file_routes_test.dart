import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/background/serial_lock.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/core/thumbs/thumbnail_cache.dart';
import 'package:kfm/features/connect/data/client_session_store.dart';
import 'package:kfm/features/connect/data/middleware/allow_list.dart';
import 'package:kfm/features/connect/data/middleware/authenticate.dart';
import 'package:kfm/features/connect/data/remote_trash_service.dart';
import 'package:kfm/features/connect/data/routes/file_routes.dart';
import 'package:kfm/features/connect/data/server_pipeline.dart';
import 'package:kfm/features/connect/data/share_scope_store.dart';
import 'package:kfm/features/connect/data/share_server.dart';
import 'package:kfm/features/connect/domain/files_protocol.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:kfm/features/connect/domain/share_scope.dart';
import 'package:shelf/shelf.dart';

import '../../core/files/fake_file_source.dart';
import 'handler_remote_http.dart';
import 'path_guard_test.dart' show fakeGuard;

const _root = '/storage/emulated/0';

SharedRoot _r(String id, String rel, {bool readOnly = false}) =>
    SharedRoot(id: id, path: '$_root/$rel', label: rel, readOnly: readOnly);

/// [hold]: openRead never ends (an in-flight download).
class _Source extends FakeFileSource {
  bool hold = false;
  bool readCancelled = false;

  /// Set: requestWriteAccess waits for it (a system dialog left open).
  Completer<bool>? writeDialog;

  @override
  Future<bool> requestWriteAccess(List<FileRef> files) async {
    final d = writeDialog;
    if (d != null) return await d.future;
    return await super.requestWriteAccess(files);
  }

  @override
  Stream<List<int>> openRead(FileRef f, {int start = 0, int? end}) {
    if (!hold) return super.openRead(f, start: start, end: end);
    final c = StreamController<List<int>>()
      ..onCancel = (() => readCancelled = true)
      ..add([1]);
    return c.stream;
  }
}

class _FakeThumbs implements ThumbnailCache {
  final List<String> asked = [];

  @override
  Future<Uint8List?> get(
    FileRef f, {
    ThumbPriority priority = ThumbPriority.visible,
  }) async {
    asked.add(f.id);
    return f.kind == FileKind.image ? Uint8List.fromList([0xFF, 0xD8]) : null;
  }

  @override
  void prefetch(Iterable<FileRef> files) {}

  @override
  void cancel(String fileId) {}

  @override
  Future<void> clear() async {}

  @override
  Future<int> diskSizeBytes() async => 0;
}

void main() {
  late AppDatabase db;
  late MediaIndexDao dao;
  late ClientSessionStore sessions;
  late ShareScopeStore scopes;
  late _Source files;
  late Handler handler;
  late IssuedSession issued;
  late bool canSeeAll;
  late List<List<FileRef>> indexed;
  late List<RemoteRequestNotice?> notices;
  late List<RemoteRequestOutcome> outcomes;
  late RemoteTrashService trash;
  late Map<String, int> diskLengths;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dao = MediaIndexDao(db);
    sessions = ClientSessionStore();
    scopes = ShareScopeStore(sessions: sessions);
    files = _Source();
    canSeeAll = true;
    diskLengths = {};
    indexed = [];
    notices = [];
    outcomes = [];
    for (var i = 0; i < 5; i++) {
      files.addFile(
        '$_root/DCIM/p$i.jpg',
        bytes: List.generate(10 + i, (b) => b),
        modifiedAt: DateTime.utc(2026, 1, 1 + i),
      );
    }
    files
      ..addFile('$_root/DCIM/doc.pdf', modifiedAt: DateTime.utc(2025))
      ..addFile('$_root/DCIM/sub/s.jpg', modifiedAt: DateTime.utc(2024))
      ..addFile(
        '$_root/DCIM/Android/data/x.jpg',
        modifiedAt: DateTime.utc(2023),
      )
      ..addFile('$_root/DCIM/Android/y.jpg', modifiedAt: DateTime.utc(2022))
      ..addFile('$_root/Download/x.pdf')
      ..addFolder('$_root/Pictures');
    await dao.upsertBatch(files.files, 1);
    final existing = {
      _root,
      '$_root/DCIM',
      '$_root/DCIM/sub',
      '$_root/Download',
      '$_root/Pictures',
      for (final f in files.files) ...[f.folderPath, f.path],
    };
    final guard = AllowListGuard(
      scopeOf: scopes.scopeOf,
      source: () => files,
      paths: fakeGuard(existing: existing),
    );
    trash = RemoteTrashService(
      source: () => files,
      lock: SerialLock(),
      onNotice: notices.add,
      onOutcome: outcomes.add,
      removeFromIndex: dao.deleteIds,
      sessionAlive: (id) => sessions.sessions.any((s) => s.sessionId == id),
    );
    final thumbs = _FakeThumbs();
    handler = buildSharePipeline(
      served: [LocalAddress(InternetAddress('192.168.1.23'), 24, 'wlan0')],
      authenticate: authenticate(sessions),
      routes: fileRoutes(
        FileRoutesEnv(
          guard: guard,
          scopeOf: scopes.scopeOf,
          sessions: sessions,
          source: () => files,
          dao: () => dao,
          addToIndex: (f) async => indexed.add(f),
          canSeeAllFiles: () => canSeeAll,
          thumbnails: () async => thumbs,
          trash: () => trash,
          preview: (f, max) async => Uint8List.fromList([max ~/ 256]),
          diskLength: (f) async => diskLengths[f.id],
        ),
      ),
    );
    issued = sessions.issue(
      clientFingerprint: 'fp',
      clientDeviceId: 'd',
      clientName: 'Pixel',
    );
    scopes.set(
      'fp',
      ShareScope([_r('cam', 'DCIM'), _r('dl', 'Download', readOnly: true)]),
    );
  });

  tearDown(() async {
    sessions.clear();
    await files.dispose();
    await db.close();
  });

  Future<Response> call(
    String method,
    String pathAndQuery, {
    Object? body,
    Map<String, String> headers = const {},
  }) async => await handler(
    Request(
      method,
      Uri.parse('https://192.168.1.23:4433$pathAndQuery'),
      headers: {'authorization': 'Bearer ${issued.token}', ...headers},
      body: body == null ? null : jsonEncode(body),
      context: {'shelf.io.connection_info': FakeConnectionInfo('192.168.1.40')},
    ),
  );

  Future<Map<String, Object?>> json(Response r) async =>
      jsonDecode(await r.readAsString()) as Map<String, Object?>;

  Future<String> code(Response r) async => (await json(r))['code']! as String;

  Future<List<int>> bytes(Response r) async => [
    for (final c in await r.read().toList()) ...c,
  ];

  String listUrl(RemoteQueryDto q, {String? cursor, int? limit}) =>
      '${ApiRoutes.files}?q=${Uri.encodeQueryComponent(q.encode())}'
      '${cursor == null ? '' : '&cursor=$cursor'}'
      '${limit == null ? '' : '&limit=$limit'}';

  group('GET /v1/files', () {
    test('same order as the local index query, keyset cursor, total only '
        'on the first page', () async {
      const q = RemoteQueryDto(
        rootId: 'cam',
        includeSubfolders: true,
        sort: FileSort(FileSortField.size),
      );
      final local = await dao.page(
        const IndexQuery(
          folderPath: '$_root/DCIM',
          includeSubfolders: true,
          sort: FileSort(FileSortField.size),
        ),
        limit: 100,
      );
      final seen = <String>[];
      String? cursor;
      var pages = 0;
      do {
        final r = await call('GET', listUrl(q, cursor: cursor, limit: 2));
        expect(r.statusCode, 200);
        final page = FilePageDto.fromJson(await json(r));
        expect(page.total, pages == 0 ? isNotNull : isNull);
        seen.addAll(page.items.map((i) => i.id));
        cursor = page.nextCursor;
        pages++;
      } while (cursor != null && pages < 20);
      expect(seen, [
        for (final f in local.items)
          if (!f.path.contains('/Android/data/')) f.id,
      ]);
      expect(seen, isNot(contains('path:$_root/DCIM/Android/data/x.jpg')));
      expect(seen, contains('path:$_root/DCIM/sub/s.jpg'));
    });

    test('items carry root id + relative folder, never absolute paths '
        'outside ids; no subfolders unless asked', () async {
      final r = await call('GET', listUrl(const RemoteQueryDto(rootId: 'cam')));
      final page = FilePageDto.fromJson(await json(r));
      expect(page.items.map((i) => i.name), [
        'p4.jpg',
        'p3.jpg',
        'p2.jpg',
        'p1.jpg',
        'p0.jpg',
        'doc.pdf',
      ]);
      expect(page.total, 6);
      expect(page.items.every((i) => i.rootId == 'cam'), isTrue);
      expect(page.items.every((i) => i.relativeFolder == ''), isTrue);
      final sub = await call(
        'GET',
        listUrl(const RemoteQueryDto(rootId: 'cam', path: 'sub')),
      );
      final item = FilePageDto.fromJson(await json(sub)).items.single;
      expect(item.relativeFolder, 'sub');
    });

    test('without All files access only media is listed (visible())', () async {
      canSeeAll = false;
      final r = await call('GET', listUrl(const RemoteQueryDto(rootId: 'cam')));
      final page = FilePageDto.fromJson(await json(r));
      expect(page.items.map((i) => i.name), isNot(contains('doc.pdf')));
      expect(page.total, 5);
      final docs = await call(
        'GET',
        listUrl(
          const RemoteQueryDto(rootId: 'cam', kinds: {FileKind.document}),
        ),
      );
      expect(FilePageDto.fromJson(await json(docs)).items, isEmpty);
    });

    test(
      'out-of-scope root, ../ escapes and bad q/cursor are refused',
      () async {
        var r = await call(
          'GET',
          listUrl(const RemoteQueryDto(rootId: 'nope')),
        );
        expect(r.statusCode, 403);
        r = await call(
          'GET',
          listUrl(const RemoteQueryDto(rootId: 'cam', path: '../Download')),
        );
        expect(r.statusCode, 403);
        r = await call('GET', '${ApiRoutes.files}?q=%7Bnope');
        expect(r.statusCode, 403);
        r = await call(
          'GET',
          listUrl(const RemoteQueryDto(rootId: 'cam'), cursor: 'zz!'),
        );
        expect(r.statusCode, 403);
        // A name cursor on a date sort.
        r = await call(
          'GET',
          listUrl(
            const RemoteQueryDto(rootId: 'cam'),
            cursor: encodeCursor('a', 'x'),
          ),
        );
        expect(r.statusCode, 403);
      },
    );

    test('a spent time budget answers truncated with a cursor', () async {
      final quick = buildSharePipeline(
        served: [LocalAddress(InternetAddress('192.168.1.23'), 24, 'wlan0')],
        authenticate: authenticate(sessions),
        routes: fileRoutes(
          FileRoutesEnv(
            guard: AllowListGuard(
              scopeOf: scopes.scopeOf,
              source: () => files,
              paths: fakeGuard(existing: {_root, '$_root/DCIM'}),
            ),
            scopeOf: scopes.scopeOf,
            sessions: sessions,
            source: () => files,
            dao: () => dao,
            addToIndex: (_) async {},
            canSeeAllFiles: () => true,
            thumbnails: () async => _FakeThumbs(),
            trash: () => trash,
            listBudget: Duration.zero,
          ),
        ),
      );
      // Oldest first, the excluded Android/data row comes first, so the
      // page needs a second query, which the zero budget stops.
      final r = await quick(
        Request(
          'GET',
          Uri.parse(
            'https://192.168.1.23:4433${listUrl(const RemoteQueryDto(rootId: 'cam', includeSubfolders: true, sort: FileSort(FileSortField.date, descending: false)), limit: 2)}',
          ),
          headers: {'authorization': 'Bearer ${issued.token}'},
          context: {
            'shelf.io.connection_info': FakeConnectionInfo('192.168.1.40'),
          },
        ),
      );
      final page = FilePageDto.fromJson(await json(r));
      expect(page.truncated, isTrue);
      expect(page.items, hasLength(1));
      expect(page.nextCursor, isNotNull);
    });
  });

  test('GET /v1/folders lists child folders relative to the root', () async {
    final r = await call('GET', '${ApiRoutes.folders}?rootId=cam&path=');
    expect(r.statusCode, 200);
    final folders = FoldersResponseDto.fromJson(await json(r)).folders;
    expect(folders.map((f) => f.relativePath), contains('sub'));
    expect(folders.firstWhere((f) => f.name == 'sub').fileCount, 1);
    expect(
      (await call('GET', '${ApiRoutes.folders}?rootId=x&path=')).statusCode,
      403,
    );
  });

  group('one file', () {
    const id = 'path:$_root/DCIM/p2.jpg';

    test('stat: dto, 404 for unknown inside the scope, 403 outside', () async {
      var r = await call('GET', ApiRoutes.fileStat(id));
      expect(r.statusCode, 200);
      final dto = RemoteFileDto.fromJson(await json(r));
      expect(dto.name, 'p2.jpg');
      expect(dto.sizeBytes, 12);
      expect(dto.rootId, 'cam');
      r = await call('GET', ApiRoutes.fileStat('path:$_root/DCIM/zz.jpg'));
      expect(r.statusCode, 404);
      expect(await code(r), 'not_found');
      r = await call('GET', ApiRoutes.fileStat('path:$_root/Music/a.mp3'));
      expect(r.statusCode, 403);
      expect(await code(r), 'forbidden_path');
    });

    test('thumb and preview', () async {
      var r = await call('GET', ApiRoutes.fileThumb(id));
      expect(r.statusCode, 200);
      expect(r.headers['content-type'], 'image/jpeg');
      r = await call('GET', ApiRoutes.fileThumb('path:$_root/DCIM/doc.pdf'));
      expect(r.statusCode, 404);
      // Previews are for MediaStore images only (fake ids are path:).
      r = await call('GET', '${ApiRoutes.filePreview(id)}?max=4000');
      expect(r.statusCode, 404);
    });

    test('content: full 200 with ETag and Accept-Ranges', () async {
      final r = await call('GET', ApiRoutes.fileContent(id));
      expect(r.statusCode, 200);
      expect(r.headers['accept-ranges'], 'bytes');
      expect(r.headers['etag'], startsWith('"'));
      expect(r.headers['content-length'], '12');
      expect(await bytes(r), List.generate(12, (b) => b));
      // The stream was registered and is gone once done.
      expect(sessions.streamsOf(issued.session.sessionId), isEmpty);
    });

    test('content: Range 206, suffix range, 416, If-Range', () async {
      var r = await call(
        'GET',
        ApiRoutes.fileContent(id),
        headers: {'range': 'bytes=2-5'},
      );
      expect(r.statusCode, 206);
      expect(r.headers['content-range'], 'bytes 2-5/12');
      expect(await bytes(r), [2, 3, 4, 5]);
      final etag = r.headers['etag']!;

      r = await call(
        'GET',
        ApiRoutes.fileContent(id),
        headers: {'range': 'bytes=-3'},
      );
      expect(r.statusCode, 206);
      expect(await bytes(r), [9, 10, 11]);

      r = await call(
        'GET',
        ApiRoutes.fileContent(id),
        headers: {'range': 'bytes=12-'},
      );
      expect(r.statusCode, 416);
      expect(r.headers['content-range'], 'bytes */12');

      r = await call(
        'GET',
        ApiRoutes.fileContent(id),
        headers: {'range': 'bytes=10-', 'if-range': etag},
      );
      expect(r.statusCode, 206);
      expect(await bytes(r), [10, 11]);

      r = await call(
        'GET',
        ApiRoutes.fileContent(id),
        headers: {'range': 'bytes=10-', 'if-range': '"stale"'},
      );
      expect(r.statusCode, 200);
      expect(await bytes(r), hasLength(12));
    });

    test('content: Disconnect ends an open stream', () async {
      files.hold = true;
      final r = await call('GET', ApiRoutes.fileContent(id));
      final done = Completer<void>();
      r.read().listen(null, onDone: done.complete);
      await pumpEventQueue();
      expect(sessions.streamsOf(issued.session.sessionId), hasLength(1));
      sessions.revoke(issued.session.sessionId);
      await done.future.timeout(const Duration(seconds: 2));
      expect(files.readCancelled, isTrue);
    });
  });

  test('content uses the length on disk, not a stale index size', () async {
    const id = 'path:$_root/DCIM/p2.jpg';
    diskLengths[id] = 8;
    var r = await call('GET', ApiRoutes.fileContent(id));
    expect(r.headers['content-length'], '8');
    expect(await bytes(r), hasLength(8));
    r = await call(
      'GET',
      ApiRoutes.fileContent(id),
      headers: {'range': 'bytes=4-'},
    );
    expect(r.headers['content-range'], 'bytes 4-7/8');
    expect(await bytes(r), [4, 5, 6, 7]);
  });

  test('listing matches folders case-insensitively', () async {
    final r = await call(
      'GET',
      listUrl(const RemoteQueryDto(rootId: 'cam', path: 'SUB')),
    );
    expect(r.statusCode, 200);
    expect(FilePageDto.fromJson(await json(r)).items.map((i) => i.name), [
      's.jpg',
    ]);
  });

  test('parseByteRange edge cases', () {
    expect(parseByteRange(null, 10), isNull);
    expect(parseByteRange('bytes=0-0', 10), (0, 1));
    expect(parseByteRange('bytes=5-100', 10), (5, 10));
    expect(parseByteRange('bytes=0-1,4-5', 10), isNull);
    expect(parseByteRange('items=0-1', 10), isNull);
    expect(parseByteRange('bytes=10-', 10), (-1, -1));
    expect(parseByteRange('bytes=-0', 10), (-1, -1));
    expect(parseByteRange('bytes=-20', 10), (0, 10));
    expect(parseByteRange('bytes=5-9223372036854775807', 10), (5, 10));
    expect(parseByteRange('bytes=5-99999999999999999999', 10), (5, 10));
    expect(parseByteRange('bytes=99999999999999999999-', 10), (-1, -1));
    expect(parseByteRange('bytes=5-2', 10), isNull);
  });

  group('edits', () {
    test('rename: ../evil.jpg and a/b.jpg → 400 invalid_name, A unchanged; '
        'a good name renames and updates the index', () async {
      const id = 'path:$_root/DCIM/p1.jpg';
      for (final bad in ['../evil.jpg', 'a/b.jpg']) {
        final r = await call(
          'POST',
          ApiRoutes.fileRename(id),
          body: {'newName': bad},
        );
        expect(r.statusCode, 400, reason: bad);
        expect(await code(r), 'invalid_name');
      }
      expect(await files.stat(id), isNotNull);
      expect(files.calls.where((c) => c.startsWith('rename')), isEmpty);

      final r = await call(
        'POST',
        ApiRoutes.fileRename(id),
        body: const RenameRequestDto('beach.jpg').toJson(),
      );
      expect(r.statusCode, 200);
      final dto = RemoteFileDto.fromJson(await json(r));
      expect(dto.id, 'path:$_root/DCIM/beach.jpg');
      expect(dto.rootId, 'cam');
      expect(indexed.single.single.id, dto.id);
    });

    test(
      'rename refuses dot names and excluded results (no .nomedia)',
      () async {
        for (final (id, name) in [
          ('path:$_root/DCIM/p1.jpg', '.nomedia'),
          ('path:$_root/DCIM/p1.jpg', '.hidden.jpg'),
          ('path:$_root/DCIM/Android/y.jpg', 'data'),
        ]) {
          final r = await call(
            'POST',
            ApiRoutes.fileRename(id),
            body: {'newName': name},
          );
          expect(r.statusCode, 400, reason: name);
          expect(await code(r), 'invalid_name');
        }
        expect(files.calls.where((c) => c.startsWith('rename')), isEmpty);
      },
    );

    test('move and rename run under the notice (consent dialogs)', () async {
      final r = await call(
        'POST',
        ApiRoutes.fileRename('path:$_root/DCIM/p1.jpg'),
        body: const RenameRequestDto('q.jpg').toJson(),
      );
      expect(r.statusCode, 200);
      expect(notices.first?.kind, RemoteRequestKind.writeAccess);
      expect(notices.last, isNull);
    });

    test('a second write-access request while one waits is 409 busy', () async {
      files.writeDialog = Completer<bool>();
      final body = {
        'ids': ['path:$_root/DCIM/p0.jpg'],
      };
      final first = call('POST', ApiRoutes.filesWriteAccess, body: body);
      await pumpEventQueue();
      final second = await call('POST', ApiRoutes.filesWriteAccess, body: body);
      expect(second.statusCode, 409);
      expect(await code(second), 'busy');
      files.writeDialog!.complete(true);
      expect((await first).statusCode, 200);
    });

    test('rename in a read-only root is 403', () async {
      final r = await call(
        'POST',
        ApiRoutes.fileRename('path:$_root/Download/x.pdf'),
        body: const RenameRequestDto('y.pdf').toJson(),
      );
      expect(r.statusCode, 403);
    });

    test(
      'move and copy between shared folders; read-only target 403',
      () async {
        scopes.set(
          'fp',
          ShareScope([
            _r('cam', 'DCIM'),
            _r('pics', 'Pictures'),
            _r('dl', 'Download', readOnly: true),
          ]),
        );
        var r = await call(
          'POST',
          ApiRoutes.fileMove('path:$_root/DCIM/p0.jpg'),
          body: const MoveRequestDto(targetRootId: 'pics').toJson(),
        );
        expect(r.statusCode, 200);
        var dto = RemoteFileDto.fromJson(await json(r));
        expect(dto.id, 'path:$_root/Pictures/p0.jpg');
        expect(dto.rootId, 'pics');
        expect(dto.relativeFolder, '');

        r = await call(
          'POST',
          ApiRoutes.fileCopy('path:$_root/Download/x.pdf'),
          body: const MoveRequestDto(
            targetRootId: 'cam',
            targetPath: 'sub',
          ).toJson(),
        );
        expect(r.statusCode, 200, reason: 'copy out of a read-only root');
        dto = RemoteFileDto.fromJson(await json(r));
        expect(dto.relativeFolder, 'sub');
        expect(indexed, hasLength(2));

        r = await call(
          'POST',
          ApiRoutes.fileMove('path:$_root/DCIM/p1.jpg'),
          body: const MoveRequestDto(targetRootId: 'dl').toJson(),
        );
        expect(r.statusCode, 403);
        r = await call(
          'POST',
          ApiRoutes.fileMove('path:$_root/Download/x.pdf'),
          body: const MoveRequestDto(targetRootId: 'cam').toJson(),
        );
        expect(r.statusCode, 403, reason: 'a move source is written');
      },
    );

    test('write-access asks once under the notice', () async {
      final r = await call(
        'POST',
        ApiRoutes.filesWriteAccess,
        body: {
          'ids': ['path:$_root/DCIM/p0.jpg', 'path:$_root/DCIM/p1.jpg'],
        },
      );
      expect(r.statusCode, 200);
      expect(await json(r), {'granted': true});
      expect(files.calls, contains('requestWriteAccess 2'));
      expect(notices.first?.kind, RemoteRequestKind.writeAccess);
      expect(notices.last, isNull);
    });
  });

  group('trash', () {
    test('trashes (never permanently), removes index rows, shows the notice '
        'and reports the outcome', () async {
      final ids = ['path:$_root/DCIM/p0.jpg', 'path:$_root/DCIM/p1.jpg'];
      final r = await call(
        'POST',
        ApiRoutes.filesTrash,
        body: TrashRequestDto(ids: ids).toJson(),
      );
      expect(r.statusCode, 200);
      final res = TrashResponseDto.fromJson(await json(r));
      expect(res.trashed.map((t) => t.id), ids);
      expect(res.userCancelled, isFalse);
      expect(
        files.calls.any((c) => c.startsWith('deletePermanently')),
        isFalse,
      );
      await trash.indexSettled;
      expect(await dao.byIds(ids), isEmpty);
      expect(notices.first?.count, 2);
      expect(notices.first?.deviceName, 'Pixel');
      expect(notices.last, isNull);
      expect(outcomes.single.declined, isFalse);
      expect(outcomes.single.count, 2);
    });

    test('a read-only root or an unknown id refuses the batch', () async {
      var r = await call(
        'POST',
        ApiRoutes.filesTrash,
        body: const TrashRequestDto(ids: ['path:$_root/Download/x.pdf'])
            .toJson(),
      );
      expect(r.statusCode, 403);
      r = await call(
        'POST',
        ApiRoutes.filesTrash,
        body: const TrashRequestDto(ids: ['path:$_root/DCIM/zz.jpg']).toJson(),
      );
      expect(r.statusCode, 404);
      expect(files.calls.where((c) => c.startsWith('trash')), isEmpty);
    });
  });

  test('every file route is guarded', () {
    final routes = fileRoutes(
      FileRoutesEnv(
        guard: AllowListGuard(
          scopeOf: scopes.scopeOf,
          source: () => files,
          paths: fakeGuard(),
        ),
        scopeOf: scopes.scopeOf,
        sessions: sessions,
        source: () => files,
        dao: () => dao,
        addToIndex: (_) async {},
        canSeeAllFiles: () => true,
        thumbnails: () async => _FakeThumbs(),
        trash: () => trash,
      ),
    );
    expect(unguardedRoutes(routes), isEmpty);
  });
}
