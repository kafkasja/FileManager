import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/connect/domain/files_protocol.dart';
import 'package:kfm/features/connect/domain/protocol.dart';

void main() {
  test('RemoteFileDto round-trips; optional fields are omitted', () {
    const f = RemoteFileDto(
      id: 'path:/storage/emulated/0/Download/a.pdf',
      name: 'a.pdf',
      kind: FileKind.document,
      sizeBytes: 10,
      modifiedAtMs: 1700000000000,
      rootId: 'r1',
      relativeFolder: '',
      mimeType: 'application/pdf',
    );
    final j = f.toJson();
    expect(j.containsKey('takenAtMs'), isFalse);
    final back = RemoteFileDto.fromJson(j);
    expect(back.toJson(), j);
    expect(back.kind, FileKind.document);
    expect(
      () => RemoteFileDto.fromJson({...j, 'kind': 'hologram'}),
      throwsFormatException,
    );
    expect(
      () => RemoteFileDto.fromJson({...j, 'sizeBytes': '10'}),
      throwsFormatException,
    );
  });

  test('RemoteQueryDto encodes into q and back; defaults; bad enums fail', () {
    const q = RemoteQueryDto(
      rootId: 'r1',
      path: 'Camera',
      includeSubfolders: true,
      kinds: {FileKind.image, FileKind.video},
      sort: FileSort(FileSortField.size, descending: false),
      minSizeBytes: 5,
      nameContains: 'x',
    );
    final back = RemoteQueryDto.decode(q.encode());
    expect(back.toJson(), q.toJson());
    expect(back.sort.field, FileSortField.size);
    expect(back.sort.descending, isFalse);
    final d = RemoteQueryDto.fromJson(const {'rootId': 'r'});
    expect(d.path, '');
    expect(d.sort.field, FileSortField.date);
    expect(d.sort.descending, isTrue);
    expect(d.kinds, isEmpty);
    expect(
      () => RemoteQueryDto.fromJson(const {'rootId': 'r', 'sort': 'colour'}),
      throwsFormatException,
    );
    expect(
      () => RemoteQueryDto.fromJson(const {
        'rootId': 'r',
        'kinds': ['x'],
      }),
      throwsFormatException,
    );
    expect(() => RemoteQueryDto.decode('[1]'), throwsFormatException);
    expect(() => RemoteQueryDto.fromJson(const {}), throwsFormatException);
  });

  test('cursor codec round-trips ints and strings; garbage fails', () {
    final a = decodeCursor(encodeCursor(1700000000000, 'ms:12'));
    expect(a.sortValue, 1700000000000);
    expect(a.id, 'ms:12');
    final b = decodeCursor(encodeCursor('Ärger.jpg', 'path:/x/y'));
    expect(b.sortValue, 'Ärger.jpg');
    for (final bad in ['', '!!!', 'W10', encodeCursor(true, 'x')]) {
      expect(() => decodeCursor(bad), throwsFormatException, reason: bad);
    }
  });

  test('pages, folders, session, move, rename round-trip', () {
    const page = FilePageDto(
      items: [
        RemoteFileDto(
          id: 'ms:1',
          name: 'a.jpg',
          kind: FileKind.image,
          sizeBytes: 1,
          modifiedAtMs: 2,
          rootId: 'r',
          relativeFolder: 'Camera',
        ),
      ],
      nextCursor: 'c',
      total: 9,
    );
    expect(FilePageDto.fromJson(page.toJson()).toJson(), page.toJson());
    const folders = FoldersResponseDto([
      RemoteFolderDto(name: 'Camera', relativePath: 'Camera', fileCount: 3),
    ]);
    expect(
      FoldersResponseDto.fromJson(folders.toJson()).folders.single.fileCount,
      3,
    );
    expect(SessionDto.fromJson(const {}).changeToken, isNull);
    expect(
      SessionDto.fromJson(const SessionDto(changeToken: 't').toJson())
          .changeToken,
      't',
    );
    expect(MoveRequestDto.fromJson(const {'targetRootId': 'r'}).targetPath, '');
    expect(
      RenameRequestDto.fromJson(const RenameRequestDto('b.jpg').toJson())
          .newName,
      'b.jpg',
    );
  });

  test('N11 verifiedMove trash request carries a hash and a size per id', () {
    final sha = 'c' * 64;
    final dto = TrashRequestDto.fromJson(
      TrashRequestDto(
        ids: const ['a'],
        reason: TrashReason.verifiedMove,
        sha256ById: {'a': sha},
        sizeById: const {'a': 7},
      ).toJson(),
    );
    expect(dto.reason, TrashReason.verifiedMove);
    expect(dto.sha256ById, {'a': sha});
    expect(dto.sizeById, {'a': 7});
    expect(
      () => TrashRequestDto.fromJson({
        'ids': const ['a', 'b'],
        'reason': 'verifiedMove',
        'sha256ById': {'a': sha},
        'sizeById': const {'a': 7},
      }),
      throwsFormatException,
    );
    expect(const TrashRequestDto(ids: ['a']).toJson().keys, ['ids', 'reason']);
  });

  test('trash request caps ids; response round-trips', () {
    expect(
      TrashRequestDto.fromJson(const {
        'ids': ['a'],
        'reason': 'swipe',
      }).reason,
      TrashReason.swipe,
    );
    expect(
      () => TrashRequestDto.fromJson({
        'ids': List.filled(TrashRequestDto.kMaxTrashIds + 1, 'x'),
      }),
      throwsFormatException,
    );
    expect(
      () => TrashRequestDto.fromJson(const {
        'ids': ['a'],
        'reason': 'verifiedMove',
      }),
      throwsFormatException,
    );
    const r = TrashResponseDto(
      trashed: [
        RemoteTrashedDto(
          id: 'ms:1',
          trashId: 't1',
          location: 'systemTrash',
          trashedAtMs: 5,
        ),
      ],
      failed: {'ms:2': 'not_found'},
    );
    expect(TrashResponseDto.fromJson(r.toJson()).toJson(), r.toJson());
  });

  test('route helpers encode ids into one segment', () {
    const id = 'path:/storage/emulated/0/DCIM/a b.jpg';
    expect(
      ApiRoutes.fileStat(id),
      '/v1/files/path%3A%2Fstorage%2Femulated%2F0%2FDCIM%2Fa%20b.jpg',
    );
    expect(ApiRoutes.fileMove(id), endsWith('/move'));
    expect(ApiRoutes.fileRename(id).split('/').length, 5);
  });
}
