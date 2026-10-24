import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/files/android/android_file_source.dart';
import 'package:kfm/core/files/android/files_channel.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/files/trash_types.dart';

import 'file_source_contract.dart';

const _channel = MethodChannel(FilesChannel.name);

typedef _Handler = Future<Object?> Function(MethodCall call);

void _mockChannel(_Handler handler) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_channel, handler);
}

/// AndroidFileSource on a real temp folder: covers the `path:` (dart:io)
/// half. The channel only answers scans with "no media".
class _TempHarness implements ContractHarness {
  new(this._dir, this.source);

  static Future<_TempHarness> create() async {
    final dir = await Directory.systemTemp.createTemp('kfm_fs');
    _mockChannel((call) async {
      switch (call.method) {
        case 'queryMedia':
          return <Object?>[];
        case 'scanPaths':
          return <Object?, Object?>{};
      }
      throw MissingPluginException(call.method);
    });
    final root = dir.path.replaceAll(r'\', '/');
    return _TempHarness(
      dir,
      AndroidFileSource(channel: FilesChannel(), primaryRoot: root),
    );
  }

  final Directory _dir;

  @override
  final AndroidFileSource source;

  @override
  String get root => source.primaryRoot;

  @override
  Future<FileRef> addFile(String path, List<int> bytes) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
    return (await source.stat('path:$path'))!;
  }

  @override
  Future<void> removeExternally(FileRef f) => File(f.path).delete();

  @override
  Future<void> dispose() async {
    await source.dispose();
    await _dir.delete(recursive: true);
  }
}

Map<String, Object?> _row(
  int id, {
  String path = '/storage/emulated/0/DCIM/Camera/img.jpg',
  int modified = 1700000000,
}) => {
  'id': id,
  'uri': 'content://media/external/images/media/$id',
  'path': path,
  'name': path.substring(path.lastIndexOf('/') + 1),
  'mime': 'image/jpeg',
  'mediaType': 'image',
  'size': 1000 + id,
  'modified': modified,
  'taken': 1699999999000,
  'width': 4000,
  'height': 3000,
  'duration': null,
};

Matcher _fails(FileOpFailure failure) => throwsA(
  isA<FileOpException>().having((e) => e.failure, 'failure', failure),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => _mockChannel((_) async => null));

  fileSourceContract('AndroidFileSource (path files)', _TempHarness.create);

  group('MediaStore half (mocked channel)', () {
    late AndroidFileSource source;
    final calls = <MethodCall>[];

    AndroidFileSource create(_Handler handler) {
      calls.clear();
      _mockChannel((call) {
        calls.add(call);
        return handler(call);
      });
      return source = AndroidFileSource(
        channel: FilesChannel(),
        walker: (_) => const Stream.empty(),
      );
    }

    tearDown(() => source.dispose());

    test('maps rows to FileRefs', () async {
      create((call) async => [_row(7)]);
      final pages = await source
          .scan(query: const FileQuery(kinds: {FileKind.image}))
          .toList();
      final f = pages.single.single;
      expect(f.id, 'ms:7');
      expect(f.kind, FileKind.image);
      expect(f.sizeBytes, 1007);
      expect(f.folderPath, '/storage/emulated/0/DCIM/Camera');
      expect(f.modifiedAt, DateTime.utc(2023, 11, 14, 22, 13, 20));
      expect(f.takenAt, isNotNull);
      expect(f.origin, FileOrigin.local);
    });

    test('pages with keyset arguments until a short page', () async {
      create((call) async {
        final afterId = (call.arguments as Map<Object?, Object?>)['afterId'];
        return switch (afterId) {
          null => [_row(9, modified: 30), _row(8, modified: 20)],
          8 => [_row(5, modified: 10)],
          _ => <Object?>[],
        };
      });
      final pages = await source
          .scan(query: const FileQuery(kinds: {FileKind.image}, pageSize: 2))
          .toList();
      expect(pages.map((p) => p.map((f) => f.id).toList()), [
        ['ms:9', 'ms:8'],
        ['ms:5'],
      ]);
      final second = calls[1].arguments as Map<Object?, Object?>;
      expect(second['afterModified'], 20);
      expect(second['afterId'], 8);
    });

    test('skips media in dot-folders unless includeHidden', () async {
      create(
        (call) async => [
          _row(1),
          _row(2, path: '/storage/emulated/0/.hidden/x.jpg'),
        ],
      );
      final visible = await source
          .scan(query: const FileQuery(kinds: {FileKind.image}))
          .expand((p) => p)
          .toList();
      expect(visible.map((f) => f.id), ['ms:1']);
    });

    test('move asks for consent once, then retries', () async {
      var attempts = 0;
      create((call) async {
        switch (call.method) {
          case 'moveMedia':
            attempts++;
            if (attempts == 1) {
              throw PlatformException(code: 'NEEDS_CONSENT');
            }
            return _row(7, path: '/storage/emulated/0/Pictures/B/img.jpg');
          case 'requestWriteConsent':
            return true;
        }
        return null;
      });
      final f = _ref(7);
      final changes = <FileIdChange>[];
      final sub = source.idChanges.listen(changes.add);
      addTearDown(sub.cancel);

      final moved = await source.move(f, '/storage/emulated/0/Pictures/B');
      expect(moved.id, 'ms:7');
      expect(moved.folderPath, '/storage/emulated/0/Pictures/B');
      expect(calls.map((c) => c.method), [
        'moveMedia',
        'requestWriteConsent',
        'moveMedia',
      ]);
      await Future<void>.delayed(Duration.zero);
      expect(changes, isEmpty, reason: 'MediaStore update keeps the id');
    });

    test('declined consent throws userCancelled', () async {
      create((call) async {
        if (call.method == 'moveMedia') {
          throw PlatformException(code: 'NEEDS_CONSENT');
        }
        return false;
      });
      await expectLater(
        source.move(_ref(7), '/storage/emulated/0/Pictures/B'),
        _fails(FileOpFailure.userCancelled),
      );
    });

    test('a move that changes the id emits FileIdChange', () async {
      create((call) async => _row(99, path: '/storage/emulated/0/B/img.jpg'));
      final changes = <FileIdChange>[];
      final sub = source.idChanges.listen(changes.add);
      addTearDown(sub.cancel);
      final moved = await source.move(_ref(7), '/storage/emulated/0/B');
      await Future<void>.delayed(Duration.zero);
      expect(moved.id, 'ms:99');
      expect(changes.single.oldId, 'ms:7');
    });

    test('platform errors map to FileOpFailure', () async {
      create((call) async {
        throw PlatformException(code: 'NOT_FOUND');
      });
      await expectLater(
        source.rename(_ref(7), 'new.jpg'),
        _fails(FileOpFailure.notFound),
      );
      create((call) async => throw PlatformException(code: 'CROSS_VOLUME'));
      await expectLater(
        source.move(_ref(7), '/storage/1234-ABCD/DCIM'),
        _fails(FileOpFailure.unsupported),
      );
      create(
        (call) async => throw PlatformException(code: 'PERMISSION_DENIED'),
      );
      await expectLater(
        source.scan(query: const FileQuery(kinds: {FileKind.image})).toList(),
        _fails(FileOpFailure.permissionDenied),
      );
    });

    group('system trash (D3)', () {
      Future<Object?> Function(MethodCall) api(int sdk, {bool allow = true}) =>
          (call) async => switch (call.method) {
            'sdkInt' => sdk,
            'trashMedia' || 'deleteMedia' => allow,
            'statMedia' => _row(7),
            'listTrashed' => [
              {..._row(7), 'expires': 1700000000 + 30 * 86400},
            ],
            'scanPaths' => <Object?, Object?>{},
            _ => null,
          };

      test('API 30+: media goes to the system trash in one request', () async {
        create(api(34));
        final pdf = _ref(9)
            .copyWith(id: 'path:/s/a.pdf', kind: FileKind.document);
        final result = await source.trashBatch([_ref(7), _ref(8), pdf]);
        expect(result.userCancelled, isFalse);
        expect(result.trashed.map((t) => t.trashId), ['ms:7', 'ms:8']);
        expect(result.trashed.first.location.name, 'systemTrash');
        expect(result.failed.keys, ['path:/s/a.pdf']);
        expect(result.failed.values.single.failure, FileOpFailure.unsupported);
        final trash = calls.singleWhere((c) => c.method == 'trashMedia');
        // Collection-specific URIs: MediaStore rejects generic Files URIs.
        expect((trash.arguments as Map)['uris'], [
          'content://media/external/images/media/7',
          'content://media/external/images/media/8',
        ]);
        expect((trash.arguments as Map)['value'], isTrue);
      });

      test('declined dialog → userCancelled, nothing trashed', () async {
        create(api(34, allow: false));
        final result = await source.trashBatch([_ref(7)]);
        expect(result.userCancelled, isTrue);
        expect(result.trashed, isEmpty);
      });

      test(
        'API 29: no system trash, routed to the pending folder (D4)',
        () async {
          create(api(29));
          final result = await source.trashBatch([_ref(7)]);
          expect(result.trashed, isEmpty);
          expect(result.failed['ms:7']?.failure, FileOpFailure.unsupported);
          expect(calls.map((c) => c.method), isNot(contains('trashMedia')));
        },
      );

      test('permanent delete: declined → userCancelled', () async {
        create(api(34, allow: false));
        await expectLater(
          source.deletePermanentlyBatch([_ref(7)]),
          _fails(FileOpFailure.userCancelled),
        );
      });

      test('restore takes it out of the trash and returns the file', () async {
        create(api(34));
        final restored = await source.restore(
          TrashedItem(
            trashId: 'ms:7',
            original: _ref(7),
            location: TrashLocation.systemTrash,
            trashedAt: DateTime.utc(2026),
          ),
        );
        expect(restored.id, 'ms:7');
        final call = calls.singleWhere((c) => c.method == 'trashMedia');
        expect((call.arguments as Map)['value'], isFalse);
      });

      test('listTrashed maps expiry', () async {
        create(api(34));
        final items = await source.listTrashed();
        expect(items.single.trashId, 'ms:7');
        expect(
          items.single.expiresAt,
          DateTime.utc(2023, 11, 14, 22, 13, 20).add(const Duration(days: 30)),
        );
      });
    });
  });
}

FileRef _ref(int id) => FileRef(
  id: 'ms:$id',
  uri: 'content://media/external/images/media/$id',
  name: 'img.jpg',
  kind: FileKind.image,
  sizeBytes: 1000,
  modifiedAt: DateTime.utc(2024),
  folderPath: '/storage/emulated/0/DCIM/Camera',
  origin: FileOrigin.local,
);
