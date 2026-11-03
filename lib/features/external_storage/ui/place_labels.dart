import 'package:flutter/material.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/features/external_storage/domain/storage_place.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// The name of [place] in the UI.
String placeLabel(AppLocalizations l10n, StoragePlace place) {
  final label = place.label.trim();
  // PL1: a Windows drive without a volume label is described as just
  // its letter ("E:"); name it by kind instead.
  if (place.id != kInternalPlaceId && _bareDrive.hasMatch(label)) {
    final drive = label.toUpperCase();
    return switch (place.kind) {
      PlaceKind.usbDrive => l10n.driveUsbUnnamed(drive),
      PlaceKind.sdCard => l10n.driveSdUnnamed(drive),
      // Network drives are keyed by their letter (no volume serial).
      PlaceKind.internal when place.id.toUpperCase() == drive =>
        l10n.driveNetworkUnnamed(drive),
      PlaceKind.internal => l10n.desktopSystemDrive(drive),
      _ => l10n.driveRemovableUnnamed(drive),
    };
  }
  return switch (place.kind) {
    // PL1: a second disk / network drive on Windows keeps its own name.
    PlaceKind.internal when place.id != kInternalPlaceId && label.isNotEmpty =>
      label,
    PlaceKind.internal => l10n.externalInternal,
    PlaceKind.camera => l10n.externalCameraLabel(
      label.isEmpty ? l10n.externalGeneric : label,
    ),
    PlaceKind.sdCard when label.isEmpty => l10n.externalSdCard,
    PlaceKind.usbDrive when label.isEmpty => l10n.externalUsbDrive,
    _ when label.isEmpty => l10n.externalGeneric,
    _ => label,
  };
}

final _bareDrive = RegExp(r'^[A-Za-z]:$');

/// "12.3 GB free of 64 GB", a camera's state, or null.
String? placeSubtitle(AppLocalizations l10n, StoragePlace place) {
  if (place.kind == PlaceKind.camera) {
    if (place.needsPermission) return l10n.externalPermissionNeeded;
    if (place.isUnsupported) return l10n.externalCameraUnsupported;
    return l10n.externalCameraReadOnly;
  }
  final free = place.freeBytes;
  final total = place.totalBytes;
  if (free == null || total == null) return null;
  return l10n.externalFreeOf(formatBytes(free), formatBytes(total));
}

IconData placeIcon(PlaceKind kind) => switch (kind) {
  PlaceKind.internal => Icons.smartphone_outlined,
  PlaceKind.sdCard => Icons.sd_card_outlined,
  PlaceKind.usbDrive => Icons.usb,
  PlaceKind.camera => Icons.photo_camera_outlined,
  PlaceKind.unknown => Icons.sd_storage_outlined,
};
