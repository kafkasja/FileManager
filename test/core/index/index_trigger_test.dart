import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/platform/permissions/storage_access.dart';

import '../platform/permissions/fake_permission_service.dart';

void main() {
  StorageAccess media(MediaAccess m) => grantedAccess.copyWith(media: m);
  final noAllFiles = grantedAccess.copyWith(
    allFiles: AllFilesAccess.notGranted,
  );

  test('no access: nothing', () {
    expect(
      indexTriggerFor(null, media(MediaAccess.unknown)),
      IndexTrigger.none,
    );
    expect(indexTriggerFor(null, null), IndexTrigger.none);
  });

  test('app start with access: start (incremental when indexed)', () {
    expect(indexTriggerFor(null, grantedAccess), IndexTrigger.start);
  });

  test('access granted or widened later: full scan', () {
    expect(
      indexTriggerFor(media(MediaAccess.unknown), grantedAccess),
      IndexTrigger.fullScan,
    );
    expect(
      indexTriggerFor(media(MediaAccess.limited), grantedAccess),
      IndexTrigger.fullScan,
    );
    expect(indexTriggerFor(noAllFiles, grantedAccess), IndexTrigger.fullScan);
  });

  test('a re-check with nothing changed: nothing', () {
    expect(indexTriggerFor(grantedAccess, grantedAccess), IndexTrigger.none);
  });
}
