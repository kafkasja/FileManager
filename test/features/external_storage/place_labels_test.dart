import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/external_storage/domain/storage_place.dart';
import 'package:kfm/features/external_storage/ui/place_labels.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

StoragePlace _drive(String id, String label, PlaceKind kind) => StoragePlace(
  id: id,
  label: label,
  kind: kind,
  access: AccessMethod.directPath,
  isMounted: true,
  rootPath: 'E:',
);

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  test('PL1: Windows drives without a volume label are named by kind', () {
    expect(
      placeLabel(l10n, _drive('ABCD-1234', 'E:', PlaceKind.usbDrive)),
      'USB drive (E:)',
    );
    expect(
      placeLabel(l10n, _drive('ABCD-1234', 'E:', PlaceKind.unknown)),
      'Removable disk (E:)',
    );
    expect(
      placeLabel(l10n, _drive('ABCD-1234', 'E:', PlaceKind.sdCard)),
      'SD card (E:)',
    );
    expect(
      placeLabel(l10n, _drive('ABCD-1234', 'D:', PlaceKind.internal)),
      'Local disk (D:)',
    );
    expect(
      placeLabel(l10n, _drive('Z:', 'Z:', PlaceKind.internal)),
      'Network drive (Z:)',
    );
    // A labelled drive keeps its own name.
    expect(
      placeLabel(l10n, _drive('ABCD-1234', 'Photos (E:)', PlaceKind.usbDrive)),
      'Photos (E:)',
    );
  });

  test('nl/tr have the unnamed drive strings', () {
    final nl = lookupAppLocalizations(const Locale('nl'));
    final tr = lookupAppLocalizations(const Locale('tr'));
    expect(nl.driveUsbUnnamed('E:'), 'USB-stick (E:)');
    expect(tr.driveRemovableUnnamed('E:'), 'Çıkarılabilir disk (E:)');
  });
}
