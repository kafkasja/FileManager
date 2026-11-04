import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/connect/data/offer_copy.dart';
import 'package:kfm/features/transfers/domain/transfer_preprocessor.dart';

/// Q4: a stripped offer copy that fails mid-write (disk full).
void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('kfm_offer_copy'));
  tearDown(() => dir.deleteSync(recursive: true));

  final photo = FileRef(
    id: 'path:/p/a.jpg',
    uri: '/p/a.jpg',
    name: 'a.jpg',
    kind: FileKind.image,
    sizeBytes: 10,
    modifiedAt: DateTime.utc(2026),
    folderPath: '/p',
    origin: FileOrigin.local,
  );

  Stream<List<int>> failing(int s, int e) async* {
    yield List.filled(4, 1);
    throw const FileSystemException(
      'write failed',
      'x',
      OSError('There is not enough space on the disk.', 112),
    );
  }

  test('the disk-full error comes through and no half copy is left', () async {
    var cleaned = false;
    await expectLater(
      prepareOfferCopy(
        photo,
        dir: () async => dir,
        seq: 1,
        enabled: () async => true,
        prepare: (f) async => PreparedSource(
          sizeBytes: 9,
          read: failing,
          cleanup: () async => cleaned = true,
        ),
      ),
      throwsA(
        isA<FileSystemException>().having(
          (e) => e.osError?.errorCode,
          'code',
          112,
        ),
      ),
    );
    expect(dir.listSync(), isEmpty);
    expect(cleaned, isTrue);
  });
}
