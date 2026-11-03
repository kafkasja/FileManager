import 'package:flutter/material.dart';
import 'package:kfm/core/db/app_database.dart' show CloudItemRow;
import 'package:kfm/core/db/tables/cloud_items_table.dart';
import 'package:kfm/core/db/tables/transfers_table.dart' show SourceOutcome;
import 'package:kfm/features/cloud/data/cloud_destinations_repository.dart';
import 'package:kfm/features/cloud/domain/cloud_destination.dart';
import 'package:kfm/features/cloud/domain/cloud_writer.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

IconData cloudProviderIcon(CloudProviderGuess p) => switch (p) {
  CloudProviderGuess.googleDrive => Icons.add_to_drive_outlined,
  CloudProviderGuess.oneDrive => Icons.cloud_outlined,
  CloudProviderGuess.dropbox => Icons.inventory_2_outlined,
  CloudProviderGuess.iCloud => Icons.cloud_outlined,
  CloudProviderGuess.other => Icons.cloud_queue_outlined,
};

/// A stored `cloud_items.error` code as text.
String cloudErrorText(AppLocalizations l10n, String? code) => switch (code) {
  CloudItemErrors.destinationRemoved => l10n.cloudDestinationRemovedError,
  CloudItemErrors.needsReconnecting => l10n.cloudNeedsReconnecting,
  CloudItemErrors.cancelled => l10n.cloudCancelled,
  CloudItemErrors.verify => l10n.cloudVerifyFailed,
  CloudItemErrors.verifyUnavailable => l10n.cloudVerifyUnavailable,
  CloudItemErrors.sourceGone => l10n.cloudSourceGone,
  CloudItemErrors.sourceChanged => l10n.cloudSourceChanged,
  CloudItemErrors.unsupported => l10n.cloudUnsupported,
  CloudItemErrors.locationNotRemoved => l10n.cloudLocationNotRemoved,
  CloudItemErrors.copyMissing => l10n.cloudCopyMissing,
  _ when code == CloudWriteFailure.noSpace.name => l10n.cloudNoSpace,
  _ => l10n.cloudWriteError,
};

/// The status line of one row ("Saved to Drive › Photos", "Waiting", …).
String cloudStatusText(
  AppLocalizations l10n,
  CloudItemRow row,
  String destinationLabel,
) => switch (row.status) {
  CloudItemStatus.queued => l10n.cloudWaiting,
  CloudItemStatus.uploading => l10n.cloudUploading(destinationLabel),
  CloudItemStatus.handedToProvider => l10n.cloudSavedToFolder(destinationLabel),
  CloudItemStatus.verified => l10n.cloudVerified(destinationLabel),
  CloudItemStatus.failed => l10n.cloudFailed(cloudErrorText(l10n, row.error)),
};

/// What happened to a moved file's original; null for copies.
String? cloudOutcomeText(AppLocalizations l10n, CloudItemRow row) {
  if (row.mode != CloudItemMode.move ||
      row.status != CloudItemStatus.verified) {
    return null;
  }
  return switch (row.sourceOutcome) {
    null => l10n.cloudOriginalNotDeleted,
    SourceOutcome.trashed => l10n.transferOriginalTrashed,
    SourceOutcome.deletedPermanently => l10n.transferOriginalDeleted,
    SourceOutcome.alreadyGone => l10n.transferOriginalGone,
    SourceOutcome.keptDeclined => l10n.transferOriginalKeptDeclined,
    SourceOutcome.keptCancelled => l10n.transferOriginalKeptCancelled,
    SourceOutcome.keptChanged => l10n.transferOriginalKeptChanged,
    SourceOutcome.keptFailed =>
      row.error == CloudItemErrors.copyMissing
          ? l10n.cloudCopyMissing
          : l10n.transferOriginalKeptFailed,
  };
}

/// A verified move row whose original may still be deleted.
bool cloudOriginalLeft(CloudItemRow row) =>
    row.mode == CloudItemMode.move &&
    row.status == CloudItemStatus.verified &&
    switch (row.sourceOutcome) {
      null ||
      SourceOutcome.keptDeclined ||
      SourceOutcome.keptFailed ||
      SourceOutcome.keptCancelled => true,
      _ => false,
    };
