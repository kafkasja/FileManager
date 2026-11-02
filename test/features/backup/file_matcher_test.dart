import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/backup/domain/backup_codec.dart';
import 'package:kfm/features/backup/domain/file_matcher.dart';

IndexedFile _local(
  String id,
  String folder,
  String name, {
  int size = 10,
  int? taken = 100,
}) => IndexedFile(
  id: id,
  folderPath: folder,
  name: name,
  size: size,
  takenAtMs: taken,
  modifiedAtMs: 1,
);

BackupFile _backup(
  String rel,
  String name, {
  String vol = 'int',
  int size = 10,
  int? taken = 100,
}) => BackupFile(vol: vol, rel: rel, name: name, size: size, takenAtMs: taken);

List<String?> _ids(List<BackupFile> files, List<IndexedFile> index) =>
    matchFiles(files, index).map((f) => f?.id).toList();

void main() {
  test('splitVolume', () {
    expect(splitVolume('/storage/emulated/0/DCIM/Camera'), (
      vol: 'int',
      rel: 'DCIM/Camera',
    ));
    expect(splitVolume('/storage/emulated/0'), (vol: 'int', rel: ''));
    expect(splitVolume('/storage/1234-ABCD/Pics'), (vol: 'sd', rel: 'Pics'));
    expect(splitVolume('/data/x'), (vol: 'root', rel: 'data/x'));
  });

  test('exact match on folder, name, size and capture time', () {
    expect(
      _ids(
        [_backup('DCIM/Camera', 'a.jpg')],
        [
          _local('1', '/storage/emulated/0/DCIM/Camera', 'a.jpg'),
          _local('2', '/storage/emulated/0/Other', 'a.jpg'),
        ],
      ),
      ['1'],
    );
  });

  test('moved folder: unique name + size + time matches', () {
    expect(
      _ids(
        [_backup('DCIM/Camera', 'a.jpg')],
        [_local('1', '/storage/emulated/0/Pictures/Sorted', 'a.jpg')],
      ),
      ['1'],
    );
  });

  test('duplicate name + size elsewhere stays unmatched', () {
    expect(
      _ids(
        [_backup('DCIM/Camera', 'a.jpg')],
        [
          _local('1', '/storage/emulated/0/X', 'a.jpg'),
          _local('2', '/storage/emulated/0/Y', 'a.jpg'),
        ],
      ),
      [null],
    );
  });

  test('never by name alone: other size or time stays unmatched', () {
    expect(
      _ids(
        [_backup('DCIM', 'a.jpg'), _backup('DCIM', 'b.jpg')],
        [
          _local('1', '/storage/emulated/0/DCIM', 'a.jpg', size: 11),
          _local('2', '/storage/emulated/0/DCIM', 'b.jpg', taken: 101),
        ],
      ),
      [null, null],
    );
  });

  test('null capture time matches only null', () {
    expect(
      _ids(
        [_backup('DCIM', 'a.jpg', taken: null), _backup('DCIM', 'b.jpg')],
        [
          _local('1', '/storage/emulated/0/DCIM', 'a.jpg', taken: null),
          _local('2', '/storage/emulated/0/DCIM', 'b.jpg', taken: null),
        ],
      ),
      ['1', null],
    );
  });

  test('SD card with another UUID matches by volume', () {
    expect(
      _ids(
        [_backup('Pics', 'a.jpg', vol: 'sd')],
        [
          _local('1', '/storage/9999-0000/Pics', 'a.jpg'),
          _local('2', '/storage/emulated/0/Pics', 'a.jpg'),
        ],
      ),
      ['1'],
    );
  });

  test('a local file is matched at most once', () {
    expect(
      _ids(
        [_backup('A', 'a.jpg'), _backup('B', 'a.jpg')],
        [_local('1', '/storage/emulated/0/A', 'a.jpg')],
      ),
      ['1', null],
    );
  });
}
