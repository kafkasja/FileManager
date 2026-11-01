import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/files/trash_types.dart';
import 'package:kfm/features/connect/data/remote_errors.dart';
import 'package:kfm/features/connect/data/remote_file_source.dart';
import 'package:kfm/features/connect/domain/files_protocol.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:kfm/features/connect/domain/remote_file_id.dart';

import 'fake_http_response.dart';
import 'fake_remote_http.dart';

const _fp = 'ab12';

Map<String, Object?> _dto(
  String id, {
  String name = 'a.jpg',
  String root = 'R1',
  String folder = '',
  int modified = 1700000000000,
  String kind = 'image',
}) => RemoteFileDto(
  id: id,
  name: name,
  kind: FileKind.values.byName(kind),
  sizeBytes: 10,
  modifiedAtMs: modified,
  takenAtMs: 1600000000000,
  rootId: root,
  relativeFolder: folder,
  mimeType: 'image/jpeg',
  width: 4,
  height: 3,
).toJson();

FileRef _ref(String serverId, {String folder = 'R1'}) => FileRef(
  id: remoteFileId(_fp, serverId),
  uri: 'remote://x',
  name: 'a.jpg',
  kind: FileKind.image,
  sizeBytes: 10,
  modifiedAt: DateTime.utc(2026),
  folderPath: folder,
  origin: FileOrigin.remote,
);

Matcher _fails(FileOpFailure f) =>
    throwsA(isA<FileOpException>().having((e) => e.failure, 'failure', f));

void main() {
  late FakeRemoteHttp http;
  late RemoteFileSource source;
  late bool connected;
  late int unauthorized;

  setUp(() {
    http = FakeRemoteHttp();
    connected = true;
    unauthorized = 0;
    source = RemoteFileSource(
      peerFingerprint: _fp,
      http: () => connected ? http : null,
      onUnauthorized: () => unauthorized++,
    );
  });
  tearDown(() => source.dispose());

  group('page', () {
    test('sends q/cursor/limit and maps items to remote refs', () async {
      http.on(
        'GET',
        ApiRoutes.files,
        (_) => FilePageDto(
          items: [RemoteFileDto.fromJson(_dto('ms:1', folder: 'DCIM/x'))],
          nextCursor: 'c2',
          total: 7,
        ).toJson(),
      );
      const q = RemoteQueryDto(
        rootId: 'R1',
        path: 'DCIM',
        kinds: {FileKind.video},
        sort: FileSort(FileSortField.size),
      );
      final page = await source.page(q, cursor: 'c1', limit: 50);
      final call = http.calls.single;
      expect(call.query['cursor'], 'c1');
      expect(call.query['limit'], '50');
      final sent = RemoteQueryDto.decode(call.query['q']!);
      expect(sent.rootId, 'R1');
      expect(sent.path, 'DCIM');
      expect(sent.kinds, {FileKind.video});
      expect(sent.sort.field, FileSortField.size);
      expect(page.nextCursor, 'c2');
      expect(page.total, 7);
      final f = page.items.single;
      expect(f.id, 'remote:$_fp:ms:1');
      expect(f.origin, FileOrigin.remote);
      expect(f.folderPath, 'R1/DCIM/x');
      expect(f.uri, startsWith('remote://$_fp/'));
      expect(
        f.modifiedAt,
        DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true),
      );
      expect(f.takenAt!.isUtc, isTrue);
      expect((f.width, f.height, f.mimeType), (4, 3, 'image/jpeg'));
    });

    test(
      'no cursor on the first page; root files have folderPath = rootId',
      () async {
        http.on(
          'GET',
          ApiRoutes.files,
          (_) =>
              FilePageDto(items: [RemoteFileDto.fromJson(_dto('ms:1'))])
                  .toJson(),
        );
        final page = await source.page(const RemoteQueryDto(rootId: 'R1'));
        expect(http.calls.single.query.containsKey('cursor'), isFalse);
        expect(http.calls.single.query['limit'], '200');
        expect(page.items.single.folderPath, 'R1');
        expect(page.nextCursor, isNull);
      },
    );
  });

  test('folders and roots', () async {
    http
      ..on(
        'GET',
        ApiRoutes.folders,
        (c) => FoldersResponseDto([
          RemoteFolderDto(
            name: 'x',
            relativePath: '${c.query['path']}/x',
            fileCount: 3,
          ),
        ]).toJson(),
      )
      ..on(
        'GET',
        ApiRoutes.roots,
        (_) => const RootsResponseDto([
          RootDto(id: 'R1', label: 'Camera', readOnly: false),
        ]).toJson(),
      );
    final folders = await source.folders('R1', path: 'DCIM');
    expect(http.calls.single.query, {'rootId': 'R1', 'path': 'DCIM'});
    expect(folders.single.relativePath, 'DCIM/x');
    expect((await source.roots()).single.label, 'Camera');
  });

  test('scan pages every shared root', () async {
    http
      ..on(
        'GET',
        ApiRoutes.roots,
        (_) => const RootsResponseDto([
          RootDto(id: 'R1', label: 'A', readOnly: false),
          RootDto(id: 'R2', label: 'B', readOnly: true),
        ]).toJson(),
      )
      ..on('GET', ApiRoutes.files, (c) {
        final q = RemoteQueryDto.decode(c.query['q']!);
        expect(q.includeSubfolders, isTrue);
        expect(q.kinds, {FileKind.image});
        final first = c.query['cursor'] == null;
        return FilePageDto(
          items: [
            RemoteFileDto.fromJson(
              _dto('${q.rootId}-${first ? 1 : 2}', root: q.rootId),
            ),
          ],
          nextCursor: first && q.rootId == 'R1' ? 'next' : null,
        ).toJson();
      });
    final pages = await source
        .scan(query: const FileQuery(kinds: {FileKind.image}))
        .toList();
    expect(
      [for (final p in pages) p.single.id],
      ['remote:$_fp:R1-1', 'remote:$_fp:R1-2', 'remote:$_fp:R2-1'],
    );
  });

  group('stat', () {
    test('found, 404 → null, another device → null', () async {
      http.on('GET', ApiRoutes.fileStat('ms:1'), (_) => _dto('ms:1'));
      expect((await source.stat('remote:$_fp:ms:1'))!.id, 'remote:$_fp:ms:1');
      expect(await source.stat('remote:$_fp:ms:2'), isNull);
      expect(await source.stat('remote:other:ms:1'), isNull);
      expect(await source.stat('ms:1'), isNull);
    });

    test('other errors propagate', () async {
      http.fail('GET', ApiRoutes.fileStat('ms:1'), ApiErrorCode.forbiddenPath);
      await expectLater(
        source.stat('remote:$_fp:ms:1'),
        _fails(FileOpFailure.permissionDenied),
      );
    });
  });

  group('openRead', () {
    final data = List.generate(20, (i) => i);

    test('whole file: no Range header', () async {
      http.streams[routeKey('GET', ApiRoutes.fileContent('ms:1'))] = (
        c,
      ) async => FakeHttpResponse(data);
      final bytes = await source
          .openRead(_ref('ms:1'))
          .expand((c) => c)
          .toList();
      expect(bytes, data);
      final headers = http.calls.single;
      expect(headers.path, ApiRoutes.fileContent('ms:1'));
    });

    test('a range asks for bytes=a-(b-1) and reads the 206 body', () async {
      Map<String, String>? sent;
      http.streams[routeKey('GET', ApiRoutes.fileContent('ms:1'))] = (
        c,
      ) async => FakeHttpResponse(data.sublist(2, 6), statusCode: 206);
      final recorder = _HeaderRecorder(http, (h) => sent = h);
      final s = RemoteFileSource(peerFingerprint: _fp, http: () => recorder);
      final bytes = await s
          .openRead(_ref('ms:1'), start: 2, end: 6)
          .expand((c) => c)
          .toList();
      expect(sent, {HttpHeaders.rangeHeader: 'bytes=2-5'});
      expect(bytes, [2, 3, 4, 5]);
      Map<String, String>? open;
      final r2 = _HeaderRecorder(http, (h) => open = h);
      await RemoteFileSource(
        peerFingerprint: _fp,
        http: () => r2,
      ).openRead(_ref('ms:1'), start: 3).drain<void>();
      expect(open, {HttpHeaders.rangeHeader: 'bytes=3-'});
    });

    test('a server ignoring the range (200) is trimmed', () async {
      http.streams[routeKey('GET', ApiRoutes.fileContent('ms:1'))] = (
        c,
      ) async => FakeHttpResponse(data, chunkSize: 3);
      final bytes = await source
          .openRead(_ref('ms:1'), start: 4, end: 11)
          .expand((c) => c)
          .toList();
      expect(bytes, data.sublist(4, 11));
    });

    test('empty range sends nothing', () async {
      expect(
        await source.openRead(_ref('ms:1'), start: 5, end: 5).toList(),
        isEmpty,
      );
      expect(http.calls, isEmpty);
    });
  });

  group('move / copy / rename', () {
    test('move posts the split target and emits the new id', () async {
      final changes = <FileIdChange>[];
      source.idChanges.listen(changes.add);
      http.on('POST', ApiRoutes.fileMove('path:/a.jpg'), (c) {
        expect(c.body, {'targetRootId': 'R2', 'targetPath': 'sub/dir'});
        return _dto('path:/b/a.jpg', root: 'R2', folder: 'sub/dir');
      });
      final moved = await source.move(_ref('path:/a.jpg'), 'R2/sub/dir');
      expect(moved.id, 'remote:$_fp:path:/b/a.jpg');
      expect(moved.folderPath, 'R2/sub/dir');
      await pumpEventQueue();
      expect(changes.single.oldId, 'remote:$_fp:path:/a.jpg');
      expect(changes.single.newRef.id, moved.id);
    });

    test(
      'a root target sends an empty path; a local path is notFound',
      () async {
        http.on('POST', ApiRoutes.fileMove('ms:1'), (c) {
          expect(c.body, {'targetRootId': 'R2', 'targetPath': ''});
          return _dto('ms:1', root: 'R2');
        });
        await source.move(_ref('ms:1'), 'R2');
        await expectLater(
          source.move(_ref('ms:1'), '/storage/emulated/0/DCIM'),
          _fails(FileOpFailure.notFound),
        );
      },
    );

    test('copy returns the copy and emits no id change', () async {
      final changes = <FileIdChange>[];
      source.idChanges.listen(changes.add);
      http.on('POST', ApiRoutes.fileCopy('ms:1'), (_) => _dto('ms:9'));
      expect((await source.copy(_ref('ms:1'), 'R1')).id, 'remote:$_fp:ms:9');
      await pumpEventQueue();
      expect(changes, isEmpty);
    });

    test('rename posts newName and emits the new id', () async {
      final changes = <FileIdChange>[];
      source.idChanges.listen(changes.add);
      http.on('POST', ApiRoutes.fileRename('path:/a.jpg'), (c) {
        expect(c.body, {'newName': 'b.jpg'});
        return _dto('path:/b.jpg', name: 'b.jpg');
      });
      final r = await source.rename(_ref('path:/a.jpg'), 'b.jpg');
      expect(r.name, 'b.jpg');
      await pumpEventQueue();
      expect(changes.single.newRef.id, 'remote:$_fp:path:/b.jpg');
    });

    test('invalid names: locally and from the server', () async {
      await expectLater(
        source.rename(_ref('ms:1'), 'a/b.jpg'),
        _fails(FileOpFailure.invalidName),
      );
      expect(http.calls, isEmpty);
      http.fail('POST', ApiRoutes.fileRename('ms:1'), ApiErrorCode.invalidName);
      await expectLater(
        source.rename(_ref('ms:1'), 'x:y.jpg'),
        _fails(FileOpFailure.invalidName),
      );
    });

    test(
      'declined → userCancelled; a file of another device → notFound',
      () async {
        http.fail('POST', ApiRoutes.fileMove('ms:1'), ApiErrorCode.declined);
        await expectLater(
          source.move(_ref('ms:1'), 'R1'),
          _fails(FileOpFailure.userCancelled),
        );
        final other = _ref('ms:1').copyWith(id: remoteFileId('zz', 'ms:1'));
        await expectLater(
          source.rename(other, 'b.jpg'),
          _fails(FileOpFailure.notFound),
        );
      },
    );
  });

  group('trashBatch', () {
    test('maps trashed / failed and sends reason user', () async {
      http.on('POST', ApiRoutes.filesTrash, (c) {
        final req = TrashRequestDto.fromJson(c.body! as Map<String, Object?>);
        expect(req.reason, TrashReason.user);
        expect(req.ids, ['ms:1', 'ms:2', 'ms:3']);
        return const TrashResponseDto(
          trashed: [
            RemoteTrashedDto(
              id: 'ms:1',
              trashId: 'ms:1',
              location: 'systemTrash',
              trashedAtMs: 1000,
              expiresAtMs: 2000,
            ),
          ],
          failed: {'ms:2': 'not_found', 'ms:3': 'pending_folder_unavailable'},
        ).toJson();
      });
      final r = await source.trashBatch([
        _ref('ms:1'),
        _ref('ms:2'),
        _ref('ms:3'),
      ]);
      final t = r.trashed.single;
      expect(t.original.id, 'remote:$_fp:ms:1');
      expect(t.location, TrashLocation.systemTrash);
      expect(
        t.trashedAt,
        DateTime.fromMillisecondsSinceEpoch(1000, isUtc: true),
      );
      expect(r.failed['remote:$_fp:ms:2']!.failure, FileOpFailure.notFound);
      expect(
        r.failed['remote:$_fp:ms:3']!.failure,
        FileOpFailure.pendingFolderUnavailable,
      );
      expect(r.userCancelled, isFalse);
    });

    test('chunks of 500; a declined dialog stops the rest', () async {
      final sizes = <int>[];
      http.on('POST', ApiRoutes.filesTrash, (c) {
        final req = TrashRequestDto.fromJson(c.body! as Map<String, Object?>);
        sizes.add(req.ids.length);
        return const TrashResponseDto(trashed: []).toJson();
      });
      final files = [for (var i = 0; i < 1001; i++) _ref('ms:$i')];
      await source.trashBatch(files);
      expect(sizes, [500, 500, 1]);

      sizes.clear();
      http.on('POST', ApiRoutes.filesTrash, (c) {
        sizes.add(1);
        return const TrashResponseDto(
          trashed: [],
          userCancelled: true,
        ).toJson();
      });
      final r = await source.trashBatch(files);
      expect(sizes, [1]);
      expect(r.userCancelled, isTrue);
    });
  });

  test('requestWriteAccess', () async {
    http.on('POST', ApiRoutes.filesWriteAccess, (c) {
      expect(c.body, {
        'ids': ['ms:1'],
      });
      return {'granted': true};
    });
    expect(await source.requestWriteAccess([_ref('ms:1')]), isTrue);
    http.on('POST', ApiRoutes.filesWriteAccess, (_) => {'granted': false});
    expect(await source.requestWriteAccess([_ref('ms:1')]), isFalse);
  });

  test('unsupported members and local-only answers', () async {
    final f = _ref('ms:1');
    final item = TrashedItem(
      trashId: 't',
      original: f,
      location: TrashLocation.systemTrash,
      trashedAt: DateTime.utc(2026),
    );
    await expectLater(
      source.createFolder('R1', 'x'),
      _fails(FileOpFailure.unsupported),
    );
    await expectLater(
      source.deletePermanentlyBatch([f]),
      _fails(FileOpFailure.unsupported),
    );
    await expectLater(source.restore(item), _fails(FileOpFailure.unsupported));
    await expectLater(
      source.restoreBatch([item]),
      _fails(FileOpFailure.unsupported),
    );
    await expectLater(
      source.deleteFromTrash([item]),
      _fails(FileOpFailure.unsupported),
    );
    await expectLater(
      source.renameFolder('R1/a', 'b'),
      _fails(FileOpFailure.unsupported),
    );
    await expectLater(
      source.registerCreated(['/x']),
      _fails(FileOpFailure.unsupported),
    );
    expect(await source.listTrashed(), isEmpty);
    expect(await source.statPath('/storage/emulated/0/a.jpg'), isNull);
    expect(await source.freeBytes('R1'), isNull);
    expect(http.calls, isEmpty);
  });

  test('every network member throws unavailable while disconnected', () async {
    connected = false;
    final f = _ref('ms:1');
    final u = _fails(FileOpFailure.unavailable);
    await expectLater(source.page(const RemoteQueryDto(rootId: 'R1')), u);
    await expectLater(source.folders('R1'), u);
    await expectLater(source.roots(), u);
    await expectLater(source.scan().toList(), u);
    await expectLater(source.stat(f.id), u);
    await expectLater(source.openRead(f).toList(), u);
    await expectLater(source.move(f, 'R1'), u);
    await expectLater(source.copy(f, 'R1'), u);
    await expectLater(source.rename(f, 'b.jpg'), u);
    await expectLater(source.trashBatch([f]), u);
    await expectLater(source.requestWriteAccess([f]), u);
    expect(http.calls, isEmpty);
  });

  test('transport errors → unavailable; 401 also reports it', () async {
    http.failAll = const RemoteUnavailableException(
      RemoteUnavailableReason.network,
    );
    await expectLater(
      source.stat('remote:$_fp:ms:1'),
      _fails(FileOpFailure.unavailable),
    );
    http
      ..failAll = null
      ..fail('GET', ApiRoutes.fileStat('ms:1'), ApiErrorCode.unauthorized);
    await expectLater(
      source.stat('remote:$_fp:ms:1'),
      _fails(FileOpFailure.unavailable),
    );
    expect(unauthorized, 1);
  });

  test('ids, folder paths and uri round-trip helpers', () {
    expect(splitRemoteFolder('R1'), (rootId: 'R1', path: ''));
    expect(splitRemoteFolder('R1/a/b'), (rootId: 'R1', path: 'a/b'));
    expect(() => splitRemoteFolder('/sdcard'), throwsA(isA<FileOpException>()));
    expect(remoteFolderPath('R1', ''), 'R1');
    expect(source.serverIdOf(_ref('path:/x:y')), 'path:/x:y');
  });
}

/// Records the headers of `getStream`, delegating to a [FakeRemoteHttp].
class _HeaderRecorder extends FakeRemoteHttp {
  new(this._inner, this._onHeaders);

  final FakeRemoteHttp _inner;
  final void Function(Map<String, String>) _onHeaders;

  @override
  Future<HttpClientResponse> getStream(
    String path, {
    Map<String, String> query = const {},
    Map<String, String> headers = const {},
  }) {
    _onHeaders(headers);
    return _inner.getStream(path, query: query, headers: headers);
  }
}
