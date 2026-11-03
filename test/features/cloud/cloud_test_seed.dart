import 'package:drift/drift.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/cloud/data/cloud_items_repository.dart';
import 'package:kfm/features/cloud/domain/cloud_destination.dart';

/// X4 test seeding: destinations and cloud_items rows written directly.
Future<int> seedDestination(AppDatabase db, String label) => db
    .into(db.cloudDestinations)
    .insert(
      CloudDestinationsCompanion.insert(
        label: label,
        providerGuess: CloudProviderGuess.googleDrive,
        location: 'content://drive/tree/$label',
        addedAt: DateTime.utc(2026),
      ),
    );

Future<int> seedUpload(
  AppDatabase db,
  FileRef f,
  int destinationId, {
  CloudItemStatus status = CloudItemStatus.handedToProvider,
  int? sizeBytes,
  int? modifiedAtMs,
  int uploadedAtMs = 1000,
}) => db
    .into(db.cloudItems)
    .insert(
      CloudItemsCompanion.insert(
        fileId: f.id,
        name: f.name,
        destinationId: destinationId,
        mode: CloudItemMode.copy,
        status: status,
        sizeBytes: sizeBytes ?? f.sizeBytes,
        sourceModifiedAtMs: modifiedAtMs ?? f.modifiedAt.millisecondsSinceEpoch,
        uploadedAtMs: Value(uploadedAtMs),
        createdAt: DateTime.utc(2026),
      ),
    );
