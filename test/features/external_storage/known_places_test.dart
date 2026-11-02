import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/browse/ui/widgets/browse_parts.dart';
import 'package:kfm/features/external_storage/data/known_places.dart';
import 'package:kfm/features/external_storage/domain/storage_place.dart';
import 'package:kfm/l10n/generated/app_localizations_en.dart';

const _sd = StoragePlace(
  id: '0000-0000',
  label: 'SDCARD',
  kind: PlaceKind.sdCard,
  access: AccessMethod.directPath,
  isMounted: true,
  rootPath: '/storage/0000-0000',
);

void main() {
  final l10n = AppLocalizationsEn();
  tearDown(KnownPlaces.reset);

  // U2 follow-up (b): Places said "SDCARD", breadcrumb and picker said
  // "SD card or USB (0000-0000)".
  test('a volume root is named like its place, also once detached', () {
    expect(
      nameOfFolder(l10n, '/storage/0000-0000'),
      'SD card or USB (0000-0000)',
    );
    KnownPlaces.update(const [_sd]);
    expect(nameOfFolder(l10n, '/storage/0000-0000'), 'SDCARD');
    expect(nameOfFolder(l10n, '/storage/0000-0000/DCIM'), 'DCIM');
    expect(nameOfFolder(l10n, '/storage/emulated/0'), 'Internal storage');

    // Detached: no root path any more, the name stays.
    KnownPlaces.update(const [
      StoragePlace(
        id: '0000-0000',
        label: 'SDCARD',
        kind: PlaceKind.sdCard,
        access: AccessMethod.directPath,
        isMounted: false,
      ),
    ]);
    expect(nameOfFolder(l10n, '/storage/0000-0000'), 'SDCARD');
  });
}
