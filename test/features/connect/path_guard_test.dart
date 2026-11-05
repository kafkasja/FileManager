import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/connect/data/path_guard.dart';
import 'package:kfm/features/connect/domain/protocol.dart';
import 'package:kfm/features/connect/domain/share_scope.dart';

import '../../core/files/fake_file_source.dart';

const _root = '/storage/emulated/0';

/// A fake disk: [existing] paths resolve to themselves, [links] to their
/// target (prefix-based, like a symlinked folder).
PathGuard fakeGuard({
  Set<String> existing = const {},
  Map<String, String> links = const {},
}) => PathGuard(
  resolver: (path) async {
    for (final l in links.entries) {
      if (path == l.key) return l.value;
      if (path.startsWith('${l.key}/')) {
        return '${l.value}${path.substring(l.key.length)}';
      }
    }
    return existing.contains(path) ? path : null;
  },
);

Matcher _rejected([ApiErrorCode code = ApiErrorCode.forbiddenPath]) =>
    throwsA(isA<GuardRejection>().having((e) => e.code, 'code', code));

SharedRoot _r(String path, {bool readOnly = true}) =>
    SharedRoot(id: path, path: path, label: path, readOnly: readOnly);

void main() {
  final guard = fakeGuard(
    existing: {_root, '$_root/DCIM', '$_root/Download', '$_root/DCIM/a.jpg'},
    links: {
      '$_root/DCIM/escape': '$_root/Download',
      '/storage/self/primary': _root,
    },
  );

  group('canonicalise', () {
    test('normalises .., ., //, trailing / (decoded once by shelf)', () async {
      expect(
        await guard.canonicalise('$_root/DCIM/../Download'),
        '$_root/Download',
      );
      expect(
        await guard.canonicalise('$_root/DCIM//a.jpg'),
        '$_root/DCIM/a.jpg',
      );
      expect(await guard.canonicalise('$_root/./DCIM/'), '$_root/DCIM');
      expect(await guard.canonicalise('/../../$_root'), _root);
    });

    test('rejects NUL, backslash and relative paths', () async {
      await expectLater(guard.canonicalise('$_root/DCIM\u0000/x'), _rejected());
      await expectLater(guard.canonicalise(r'/storage\emulated'), _rejected());
      await expectLater(guard.canonicalise(r'..\..\x'), _rejected());
      await expectLater(guard.canonicalise('DCIM/a.jpg'), _rejected());
      // A still-encoded value is just a name (shelf decodes once).
      expect(
        await guard.canonicalise('$_root/DCIM/%2e%2e%2fDownload'),
        '$_root/DCIM/%2e%2e%2fDownload',
      );
    });

    test('resolves symlinks, also below a missing leaf', () async {
      expect(
        await guard.canonicalise('$_root/DCIM/escape/x.pdf'),
        '$_root/Download/x.pdf',
      );
      expect(
        await guard.canonicalise('$_root/DCIM/new/b.jpg'),
        '$_root/DCIM/new/b.jpg',
      );
    });

    test('maps volume aliases back to /storage/emulated/0', () async {
      expect(
        await guard.canonicalise('/storage/self/primary/DCIM'),
        '$_root/DCIM',
      );
      final aliased = PathGuard(
        resolver: (p) async => p.replaceFirst(_root, '/storage/self/primary'),
      );
      expect(
        await aliased.canonicalise('$_root/DCIM/a.jpg'),
        '$_root/DCIM/a.jpg',
      );
    });
  });

  group('joinRelative', () {
    final camera = _r('$_root/DCIM');

    test('stays inside the root', () async {
      expect(await guard.joinRelative(camera, ''), '$_root/DCIM');
      expect(await guard.joinRelative(camera, 'a.jpg'), '$_root/DCIM/a.jpg');
    });

    test('../ escapes, absolute paths, symlinks out → 403', () async {
      await expectLater(
        guard.joinRelative(camera, '../../Download'),
        _rejected(),
      );
      await expectLater(guard.joinRelative(camera, '../Download'), _rejected());
      await expectLater(
        guard.joinRelative(camera, '/storage/emulated/0'),
        _rejected(),
      );
      await expectLater(
        guard.joinRelative(camera, 'escape/x.pdf'),
        _rejected(),
      );
      await expectLater(
        guard.joinRelative(camera, r'..\Download'),
        _rejected(),
      );
    });
  });

  test('ShareScope.rootFor: no prefix collision; deepest root wins', () {
    final scope = ShareScope([
      _r('$_root/DCIM'),
      _r('$_root/DCIM/Camera', readOnly: false),
    ]);
    expect(scope.rootFor('$_root/DCIM2/a.jpg'), isNull);
    expect(scope.rootFor('$_root/DCIM')?.path, '$_root/DCIM');
    expect(scope.rootFor('$_root/DCIM/Camera/x')?.readOnly, isFalse);
    expect(scope.rootFor('$_root/DCIMx'), isNull);
    expect(ShareScope.empty.rootFor('$_root/DCIM'), isNull);
  });

  test('isExcluded: dot segments, Android/data and Android/obb (any case)', () {
    expect(PathGuard.isExcluded('$_root/DCIM/.KFMTrash/a.jpg'), isTrue);
    expect(PathGuard.isExcluded('$_root/DCIM/.thumbnails'), isTrue);
    expect(PathGuard.isExcluded('$_root/Download/.fm-partial/u1'), isTrue);
    expect(PathGuard.isExcluded('$_root/DCIM/.nomedia'), isTrue);
    expect(PathGuard.isExcluded('$_root/Android/data/com.x/db'), isTrue);
    expect(PathGuard.isExcluded('$_root/ANDROID/OBB'), isTrue);
    expect(PathGuard.isExcluded('$_root/Android/media/x'), isFalse);
    expect(PathGuard.isExcluded('$_root/DCIM/a.b.jpg'), isFalse);
  });

  group('resolveFileId', () {
    late FakeFileSource files;
    setUp(() {
      files = FakeFileSource()
        ..addFile('$_root/DCIM/a.jpg')
        ..addFile('$_root/Android/data/x.db');
    });
    tearDown(() => files.dispose());

    test('canonical path: id resolves through the server FileSource', () async {
      final f = await guard.resolveFileId('path:$_root/DCIM/a.jpg', files);
      expect(f.canonicalPath, '$_root/DCIM/a.jpg');
      expect(f.canonicalFolder, '$_root/DCIM');
      expect(f.ref.id, 'path:$_root/DCIM/a.jpg');
    });

    test('non-canonical path ids are 403 (even if the file exists)', () async {
      await expectLater(
        guard.resolveFileId('path:$_root/DCIM/../Android/data/x.db', files),
        _rejected(),
      );
      await expectLater(
        guard.resolveFileId('path:$_root/DCIM//a.jpg', files),
        _rejected(),
      );
      await expectLater(
        guard.resolveFileId('path:$_root/DCIM/a.jpg/', files),
        _rejected(),
      );
      await expectLater(guard.resolveFileId('remote:x:y', files), _rejected());
    });

    test('unknown ids are 404', () async {
      await expectLater(
        guard.resolveFileId('path:$_root/DCIM/nope.jpg', files),
        _rejected(ApiErrorCode.notFound),
      );
      await expectLater(
        guard.resolveFileId('ms:99', files),
        _rejected(ApiErrorCode.notFound),
      );
    });
  });

  test('root ids: stable per salt + path, 16 chars, differ by salt', () {
    final a = PathGuard.rootId([1, 2, 3], '$_root/DCIM');
    expect(a, PathGuard.rootId([1, 2, 3], '$_root/DCIM'));
    expect(a, hasLength(16));
    expect(a, isNot(PathGuard.rootId([1, 2, 4], '$_root/DCIM')));
    expect(a, isNot(PathGuard.rootId([1, 2, 3], '$_root/Download')));
    expect(a, isNot(contains('DCIM')));
  });

  group('E1 Windows paths', () {
    final win = PathGuard(
      windows: true,
      resolver: (path) async =>
          {'C:', 'C:/Users', 'C:/Users/kaf'}.contains(path) ? path : null,
    );

    test('drive paths are absolute only with windows: true', () async {
      expect(await win.canonicalise('C:/Users/kaf/'), 'C:/Users/kaf');
      expect(await win.canonicalise('C:/Users/kaf/new'), 'C:/Users/kaf/new');
      expect(await win.canonicalise('C:/'), 'C:');
      expect(() => win.canonicalise('C:/..'), _rejected());
      expect(() => win.canonicalise('Users/kaf'), _rejected());
      expect(() => win.canonicalise(r'C:\Users'), _rejected());
      expect(() => guard.canonicalise('C:/Users'), _rejected());
    });

    test('AppData, the Recycle Bin and System Volume Information are '
        'excluded', () {
      expect(PathGuard.isExcluded('C:/Users/kaf/AppData/Local'), isTrue);
      expect(PathGuard.isExcluded(r'D:/$RECYCLE.BIN/x'), isTrue);
      expect(PathGuard.isExcluded('E:/System Volume Information'), isTrue);
      expect(PathGuard.isExcluded('C:/Users/kaf/Pictures'), isFalse);
    });
  });
}
