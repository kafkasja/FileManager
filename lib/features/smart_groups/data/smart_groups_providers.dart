import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:kfm/core/background/in_app_jobs.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/db/settings/settings_repository.dart';
import 'package:kfm/core/db/tables/smart_groups_table.dart';
import 'package:kfm/core/files/android/files_channel.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/features/smart_groups/data/exif_reader.dart';
import 'package:kfm/features/smart_groups/data/place_namer.dart';
import 'package:kfm/features/smart_groups/data/smart_groups_job.dart';
import 'package:kfm/features/smart_groups/data/smart_groups_repository.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'smart_groups_providers.g.dart';

/// Platforms without the Kotlin reader (Windows until PL1): no EXIF facts.
class _NoExifReader implements ExifReader {
  const new();

  @override
  Future<List<ExifFacts>> read(List<String> fileIds) async => [
    for (final id in fileIds) ExifFacts(fileId: id, locationReadable: false),
  ];
}

/// Where the clustering runs (an isolate; widget tests override it with an
/// inline one, fake time can't wait for a real isolate).
class GroupsComputer {
  const new();

  Future<R> call<R>(FutureOr<R> Function() fn) => Isolate.run(fn);
}

@Riverpod(keepAlive: true)
GroupsComputer groupsComputer(Ref ref) => const GroupsComputer();

@Riverpod(keepAlive: true)
ExifReader exifReader(Ref ref) => Platform.isAndroid
    ? ChannelExifReader(FilesChannel())
    : const _NoExifReader();

/// Registers the groups job with the in-app runner (watched in `App.build`)
/// and kicks it when Groups is activated or online names are turned on.
@Riverpod(keepAlive: true)
SmartGroupsJob smartGroupsJob(Ref ref) {
  final settings = ref.watch(settingsRepositoryProvider);
  final runner = ref.watch(inAppJobRunnerProvider);
  final repo = ref.watch(smartGroupsRepositoryProvider);
  final permissions = ref.watch(permissionServiceProvider);
  final job = SmartGroupsJob(
    repo: repo,
    settings: settings,
    exif: ref.watch(exifReaderProvider),
    namer: ref.watch(placeNamerProvider),
    compute: ref.watch(groupsComputerProvider).call,
    locationGranted: permissions.hasMediaLocation,
    canReadPaths: () async =>
        ref.read(storageAccessControllerProvider).value?.canSeeAllFiles ??
        false,
  );
  runner.register(job);
  final subs = [
    settings.watch(AppSettings.smartGroupsActivated).listen((on) {
      if (on) runner.kick();
    }),
    settings.watch(AppSettings.smartGroupsOnlinePlaceNames).skip(1).listen((
      on,
    ) {
      if (!on) return;
      // Turning it on again retries the groups that failed before.
      unawaited(
        repo.resetFailedLookups().then((_) => runner.kick(), onError: (_) {}),
      );
    }),
  ];
  ref.onDispose(() {
    for (final s in subs) {
      unawaited(s.cancel());
    }
    runner.unregister(job);
    job.dispose();
  });
  return job;
}

/// Job progress for the Groups screen ("Finding trips and places…").
@riverpod
Stream<SmartGroupsProgress> smartGroupsProgress(Ref ref) async* {
  final job = ref.watch(smartGroupsJobProvider);
  yield job.progress;
  yield* job.progressStream;
}

/// `ACCESS_MEDIA_LOCATION` (C5 §7). Checked when Groups opens; asked only
/// from [request] (first Groups open, the "Allow location access" row).
@Riverpod(keepAlive: true)
class MediaLocationAccess extends _$MediaLocationAccess {
  @override
  Future<bool> build() =>
      ref.read(permissionServiceProvider).hasMediaLocation();

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(permissionServiceProvider).hasMediaLocation(),
    );
  }

  /// Asks (or opens the app settings page when it was permanently denied).
  /// A grant re-reads GPS: the runner is kicked.
  Future<void> request() async {
    final service = ref.read(permissionServiceProvider);
    if (await service.mediaLocationPermanentlyDenied()) {
      await service.openAppSettings();
      return;
    }
    state = await AsyncValue.guard(service.requestMediaLocation);
    if (state.value ?? false) ref.read(inAppJobRunnerProvider).kick();
  }
}

/// First open of the Groups screen: turns the job on and asks for location
/// access once (rule 5: nothing runs before). Later opens only re-check.
Future<void> activateSmartGroups(
  SettingsRepository settings,
  MediaLocationAccess access,
  InAppJobRunner runner,
) async {
  if (!await settings.read(AppSettings.smartGroupsActivated)) {
    await access.request();
    await settings.write(AppSettings.smartGroupsActivated, true);
  } else {
    await access.refresh();
  }
  runner.kick();
}

@riverpod
Stream<bool> smartGroupsOnlinePlaceNames(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watch(AppSettings.smartGroupsOnlinePlaceNames);

@riverpod
Stream<List<SmartGroupView>> smartGroupList(Ref ref, SmartGroupKind kind) =>
    ref.watch(smartGroupsRepositoryProvider).watchGroups(kind);

@riverpod
Stream<SmartGroupView?> smartGroup(Ref ref, int id) => ref
    .watch(smartGroupsRepositoryProvider)
    .watchGroup(id)
    .map((row) => row == null ? null : SmartGroupView(row, null));

/// The three live groups (§1): plain [IndexQuery]s.
enum LiveGroup {
  screenshots(IndexQuery(screenshotsOnly: true)),
  selfies(IndexQuery(selfiesOnly: true)),
  documents(IndexQuery(documentsGroup: true));

  new(this.query);

  final IndexQuery query;
}

/// Count + newest file of a live group.
@immutable
class LiveGroupSummary {
  const new(this.count, this.cover);

  static const LiveGroupSummary empty = LiveGroupSummary(0, null);

  final int count;
  final FileRef? cover;

  @override
  bool operator ==(Object other) =>
      other is LiveGroupSummary && other.count == count && other.cover == cover;

  @override
  int get hashCode => Object.hash(count, cover);
}

/// Count + newest file of a live group (hidden at 0). Respects `visible()`.
@riverpod
Future<LiveGroupSummary> liveGroupSummary(Ref ref, LiveGroup group) async {
  ref.watch(changesFor(group.query));
  final canSeeAll =
      ref.watch(storageAccessControllerProvider).value?.canSeeAllFiles ?? false;
  final visible = group.query.visible(canSeeAllFiles: canSeeAll);
  if (visible == null) return LiveGroupSummary.empty;
  final dao = ref.watch(mediaIndexDaoProvider);
  final count = await dao.count(visible);
  if (count == 0) return LiveGroupSummary.empty;
  final page = await dao.page(visible, limit: 1);
  return LiveGroupSummary(count, page.items.firstOrNull);
}
