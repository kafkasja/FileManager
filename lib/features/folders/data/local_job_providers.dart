import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/core/files/routing_file_source.dart';
import 'package:kfm/core/files/staging_dir.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/features/external_storage/data/places_repository.dart';
import 'package:kfm/features/external_storage/data/volume_activity_tracker.dart';
import 'package:kfm/features/external_storage/domain/storage_place.dart';
import 'package:kfm/features/folders/data/local_job_runner.dart';
import 'package:kfm/features/folders/data/local_jobs_dao.dart';
import 'package:kfm/features/transfers/data/transfer_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'local_job_providers.g.dart';

@Riverpod(keepAlive: true)
LocalJobsDao localJobsDao(Ref ref) => LocalJobsDao(
  ref.watch(appDatabaseProvider),
  ref.watch(dbWriteQueueProvider),
);

/// Whether [placeId] is mounted in [places] (internal storage always is;
/// no place list = nothing known, assume yes).
bool placeMounted(List<StoragePlace> places, String placeId) {
  if (placeId == kInternalPlaceId || places.isEmpty) return true;
  return places.any((p) => p.id == placeId && p.isMounted);
}

/// The "On this phone" job runner (TASK-U2). Null when the file source
/// isn't the routing one (tests, other platforms). Recovers interrupted
/// jobs once and follows U1's place changes (pause / resume).
@Riverpod(keepAlive: true)
LocalJobRunner? localJobRunner(Ref ref) {
  final fs = routingOf(ref.watch(fileSourceProvider));
  if (fs == null) return null;
  var places = const <StoragePlace>[];
  final runner = LocalJobRunner(
    dao: ref.watch(localJobsDaoProvider),
    files: fs,
    crossPlace: fs.crossPlace,
    verifiedMove: ref.watch(verifiedMoveProvider),
    addToIndex: (files) => ref.read(mediaIndexerProvider).addFiles(files),
    isMounted: (id) => placeMounted(places, id),
    placeOfFile: fs.placeOfFile,
    placeOfFolder: fs.placeOfFolder,
    staging: transferStagingDir,
    stagesInTarget: fs.saf.locator.owns,
    track: ref.watch(volumeActivityTrackerProvider.notifier).runAll,
    onJobEnded: ref.read(placesSpaceRefreshProvider).request,
  );
  final ready = runner.recover();
  ref.listen(placesProvider, (_, next) {
    if (next.value case final p?) {
      places = p;
      ready.then((_) => runner.onPlacesChanged()).ignore();
    }
  }, fireImmediately: true);
  return runner;
}
