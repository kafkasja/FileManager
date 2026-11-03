import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart' show StreamProvider;
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/android/files_channel.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/features/cloud/data/cloud_destinations_repository.dart';
import 'package:kfm/features/cloud/data/cloud_items_repository.dart';
import 'package:kfm/features/cloud/data/cloud_upload_runner.dart';
import 'package:kfm/features/cloud/data/saf_cloud_writer.dart';
import 'package:kfm/features/cloud/domain/cloud_destination.dart';
import 'package:kfm/features/cloud/domain/cloud_writer.dart';
import 'package:kfm/features/privacy/data/privacy_providers.dart';
import 'package:kfm/features/privacy/domain/location_stripper.dart';
import 'package:kfm/features/transfers/data/transfer_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cloud_providers.g.dart';

/// Null off Android: no destination can be added there yet (PL1/PL2).
@Riverpod(keepAlive: true)
CloudTreePlatform? cloudTreePlatform(Ref ref) =>
    Platform.isAndroid ? ChannelCloudTreePlatform(FilesChannel()) : null;

/// Null off Android.
@Riverpod(keepAlive: true)
CloudDestinationWriter? cloudWriter(Ref ref) =>
    Platform.isAndroid ? SafCloudWriter(FilesChannel()) : null;

@Riverpod(keepAlive: true)
CloudDestinationsRepository cloudDestinationsRepository(Ref ref) {
  final settings = ref.watch(settingsRepositoryProvider);
  return CloudDestinationsRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(dbWriteQueueProvider),
    platform: ref.watch(cloudTreePlatformProvider),
    // U1's volume grants are never released by a cloud removal.
    protectedTrees: () async =>
        (await settings.read(AppSettings.externalSafGrants)).values.toSet(),
  );
}

@Riverpod(keepAlive: true)
CloudItemsRepository cloudItemsRepository(Ref ref) => CloudItemsRepository(
  ref.watch(appDatabaseProvider),
  ref.watch(dbWriteQueueProvider),
);

/// X2: with "Remove location when sharing" on, photos and videos go up
/// from a stripped copy (the checksum and the read-back are of that copy).
CloudSourcePreparer _strippingPreparer(Ref ref) => (file, itemId) async {
  final on = await ref
      .read(settingsRepositoryProvider)
      .read(AppSettings.privacyStripLocation);
  if (!on || !LocationStripper.appliesTo(file)) {
    return await plainCloudSource(file, itemId);
  }
  final stripper = ref.read(locationStripperProvider);
  final sendId = 'cloud-$itemId';
  try {
    final copy = await stripper.stripToTemp(file, sendId: sendId);
    return CloudSource(
      source: copy.path,
      sizeBytes: copy.sizeBytes,
      cleanup: () => stripper.release(sendId),
    );
  } on LocationStripException {
    await stripper.release(sendId);
    throw const CloudLocationNotRemoved();
  }
};

/// The cloud upload runner (TASK-X3). Null off Android. Creating it runs
/// nothing: work starts on the first `start` or `resume` (Hard rule 1).
@Riverpod(keepAlive: true)
CloudUploadRunner? cloudUploadRunner(Ref ref) {
  final writer = ref.watch(cloudWriterProvider);
  if (writer == null) return null;
  final runner = CloudUploadRunner(
    items: ref.watch(cloudItemsRepositoryProvider),
    destinations: ref.watch(cloudDestinationsRepositoryProvider),
    writer: writer,
    files: ref.watch(fileSourceProvider),
    verifiedMove: ref.watch(verifiedMoveProvider),
    prepare: _strippingPreparer(ref),
  );
  ref.onDispose(runner.dispose);
  return runner;
}

/// App start (watched in `App.build`): resumes interrupted uploads only
/// when an active destination **and** queued/uploading rows exist; two
/// cheap queries otherwise, no channel call.
@Riverpod(keepAlive: true)
Future<bool> cloudResume(Ref ref) async {
  final destinations = ref.read(cloudDestinationsRepositoryProvider);
  if (!await destinations.hasActive()) return false;
  if (!await ref.read(cloudItemsRepositoryProvider).hasPending()) {
    return false;
  }
  final runner = ref.read(cloudUploadRunnerProvider);
  if (runner == null) return false;
  await runner.resume();
  return true;
}

@riverpod
Stream<List<CloudDestination>> activeCloudDestinations(Ref ref) =>
    ref.watch(cloudDestinationsRepositoryProvider).watchActive();

/// Persisted-grant check for the destinations screen (re-read on open).
@riverpod
Future<Map<int, CloudDestinationHealth>> cloudDestinationHealth(Ref ref) async {
  final list = await ref.watch(activeCloudDestinationsProvider.future);
  return await ref.read(cloudDestinationsRepositoryProvider).health(list);
}

/// Cloud rows of the last 7 days (and every unfinished one). Not codegen:
/// drift row types aren't resolved when riverpod_generator runs.
final StreamProvider<List<CloudItemRow>> cloudRecentItemsProvider =
    StreamProvider<List<CloudItemRow>>(
      (ref) => ref
          .watch(cloudItemsRepositoryProvider)
          .watchJobs(since: DateTime.now().subtract(const Duration(days: 7))),
    );

@riverpod
Stream<Map<int, CloudDestination>> cloudDestinationsById(Ref ref) =>
    ref.watch(cloudDestinationsRepositoryProvider).watchAllById();

/// Bytes written per uploading row.
@riverpod
Stream<Map<int, int>> cloudProgress(Ref ref) {
  final runner = ref.watch(cloudUploadRunnerProvider);
  return runner == null ? const Stream.empty() : runner.progress;
}
