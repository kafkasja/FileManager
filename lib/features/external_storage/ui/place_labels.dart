import 'package:flutter/material.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/features/external_storage/domain/storage_place.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// The name of [place] in the UI.
String placeLabel(AppLocalizations l10n, StoragePlace place) {
  final label = place.label.trim();
  return switch (place.kind) {
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
