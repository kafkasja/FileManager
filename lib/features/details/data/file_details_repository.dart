import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/files/android/files_channel.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/source_rule.dart';
import 'package:kfm/features/details/domain/file_details.dart';
import 'package:kfm/features/details/domain/known_files.dart';
import 'package:kfm/features/details/domain/path_app.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'file_details_repository.g.dart';

const kKnownFilesAsset = 'assets/details/known_files_en.json';
const kKnownAppsAsset = 'assets/details/known_apps.json';

/// The native side of file details (Android: `com.kaf.kfm/files`). Rows are
/// documented on [FilesChannel.fileDetails] / [FilesChannel.appInfo] /
/// [FilesChannel.readExif].
abstract interface class DetailsPlatform {
  Future<MediaRow> fileDetails(String path, {int? id});
  Future<MediaRow?> appInfo(String packageName);
  Future<bool> openAppDetails(String packageName);

  /// One EXIF row for an `ms:` id ([mediaId]) or a `path:` file.
  Future<MediaRow?> exif({int? mediaId, String? path});
  Future<List<MediaRow>> storageVolumes();
}

class ChannelDetailsPlatform implements DetailsPlatform {
  const new(this._channel);

  final FilesChannel _channel;

  @override
  Future<MediaRow> fileDetails(String path, {int? id}) =>
      _channel.fileDetails(path, id: id);

  @override
  Future<MediaRow?> appInfo(String packageName) =>
      _channel.appInfo(packageName);

  @override
  Future<bool> openAppDetails(String packageName) =>
      _channel.openAppDetails(packageName);

  @override
  Future<MediaRow?> exif({int? mediaId, String? path}) async {
    final rows = mediaId != null
        ? await _channel.readExif([mediaId])
        : path != null
        ? await _channel.readExifPaths([path])
        : const <MediaRow>[];
    return rows.firstOrNull;
  }

  @override
  Future<List<MediaRow>> storageVolumes() => _channel.storageVolumes();
}

/// Not Android yet (PL1/PL2): only what the FileRef and the path say.
class NoDetailsPlatform implements DetailsPlatform {
  const new();

  @override
  Future<MediaRow> fileDetails(String path, {int? id}) async => {
    'exists': path.isEmpty ? null : File(path).existsSync(),
  };

  @override
  Future<MediaRow?> appInfo(String packageName) async => null;

  @override
  Future<bool> openAppDetails(String packageName) async => false;

  @override
  Future<MediaRow?> exif({int? mediaId, String? path}) async => null;

  @override
  Future<List<MediaRow>> storageVolumes() async => const [];
}

/// Builds [FileDetails] (TASK-B10). Every native part is optional: a
/// failure or a [timeout] gives a partial result, never an error.
class FileDetailsRepository {
  new({
    required this._platform,
    required this._knownFiles,
    required this._knownApps,
    this._placeName,
    this.timeout = const Duration(seconds: 5),
  });

  final DetailsPlatform _platform;
  final Future<KnownFiles> Function() _knownFiles;
  final Future<KnownApps> Function() _knownApps;
  final Future<String?> Function(String fileId)? _placeName;
  final Duration timeout;

  Future<FileDetails> load(FileRef file) async {
    var partial = false;
    Future<T?> guarded<T>(String what, Future<T?> Function() run) async {
      try {
        return await run().timeout(timeout);
      } on Object catch (e, st) {
        partial = true;
        developer.log(
          'details: $what failed',
          name: 'kfm.details',
          error: e,
          stackTrace: st,
        );
        return null;
      }
    }

    final remote = file.origin == FileOrigin.remote;
    final path = remote ? '' : file.path;
    final mediaId = file.id.startsWith('ms:')
        ? int.tryParse(file.id.substring(3))
        : null;
    final rel = volumeRelative(file.folderPath);

    final known = await guarded('known files', _knownFiles);
    final apps = await guarded('known apps', _knownApps) ?? const KnownApps();
    final explanation = known?.match(rel, file.name);
    final pathApp = remote ? null : pathAppFor(file, apps);

    final rowF = remote
        ? null
        : guarded(
            'fileDetails',
            () => _platform.fileDetails(path, id: mediaId),
          );
    final exifF = !remote && file.kind == FileKind.image
        ? guarded(
            'exif',
            () => _platform.exif(
              mediaId: mediaId,
              path: mediaId == null ? path : null,
            ),
          )
        : null;
    final volumesF = remote
        ? null
        : guarded('volumes', _platform.storageVolumes);
    final placeF = _placeName == null
        ? null
        : guarded('place', () => _placeName(file.id));

    final row = await rowF ?? const <String, Object?>{};
    if (row['error'] != null) partial = true;
    final exifRow = await exifF;
    final exif = exifRow == null ? null : _exif(exifRow);
    if (exifRow?['error'] != null) partial = true;

    final ownerPackage = _string(row['owner']);
    final appPackage = ownerPackage ?? pathApp?.packageName;
    OwnerApp? owner;
    if (appPackage != null) {
      final info = await guarded(
        'appInfo',
        () => _platform.appInfo(appPackage),
      );
      final label = _string(info?['label']);
      owner = OwnerApp(
        packageName: appPackage,
        label: label ?? apps.names[appPackage],
        icon: switch (info?['icon']) {
          final Uint8List b when b.isNotEmpty => b,
          _ => null,
        },
        installed: info != null,
      );
    }

    final (volumeKind, volumeLabel) = _volume(
      file.folderPath,
      await volumesF ?? const [],
    );
    final added = row['dateAdded'];
    return FileDetails(
      file: file,
      path: path,
      exists: switch (row['exists']) {
        final bool b => b,
        _ => null,
      },
      mimeType: _string(row['mime']) ?? file.mimeType,
      addedAt: added is int && added > 0
          ? DateTime.fromMillisecondsSinceEpoch(added * 1000, isUtc: true)
          : null,
      ownerPackage: ownerPackage,
      owner: owner,
      downloadUri: _string(row['downloadUri']),
      refererUri: _string(row['refererUri']),
      exif: exif,
      pathApp: pathApp,
      explanation: explanation,
      volumeKind: volumeKind,
      volumeLabel: volumeLabel,
      placeName: exif?.hasLocation ?? false ? await placeF : null,
      partial: partial,
    );
  }

  /// False when it couldn't be opened.
  Future<bool> openAppDetails(String packageName) =>
      _platform.openAppDetails(packageName);

  static String? _string(Object? v) =>
      v is String && v.trim().isNotEmpty ? v.trim() : null;

  static ExifDetails? _exif(MediaRow r) {
    if (r['error'] != null) return null;
    double? positive(Object? v) => v is num && v > 0 ? v.toDouble() : null;
    final lat = r['lat'];
    final lng = r['lng'];
    final hasGps = lat is num && lng is num;
    final iso = r['iso'];
    return ExifDetails(
      make: _string(r['make']),
      model: _string(r['model']),
      software: _string(r['software']),
      lens: _string(r['lens']),
      iso: iso is int && iso > 0 ? iso : null,
      exposureSeconds: positive(r['exposure']),
      fNumber: positive(r['fNumber']),
      focalLengthMm: positive(r['focalLength']),
      description: _string(r['description']),
      userComment: _string(r['userComment']),
      lat: hasGps ? lat.toDouble() : null,
      lng: hasGps ? lng.toDouble() : null,
    );
  }

  static (VolumeKind, String?) _volume(String folder, List<MediaRow> vols) {
    for (final v in vols) {
      final root = v['path'];
      if (root is! String || root.isEmpty) continue;
      if (folder == root || folder.startsWith('$root/')) {
        return v['primary'] == true
            ? (VolumeKind.internal, null)
            : (VolumeKind.removable, _string(v['label']));
      }
    }
    if (RegExp(r'^/storage/emulated/\d+(/|$)').hasMatch(folder)) {
      return (VolumeKind.internal, null);
    }
    if (RegExp(r'^/storage/[^/]+(/|$)').hasMatch(folder)) {
      return (VolumeKind.removable, null);
    }
    return (VolumeKind.unknown, null);
  }
}

@Riverpod(keepAlive: true)
DetailsPlatform detailsPlatform(Ref ref) => Platform.isAndroid
    ? ChannelDetailsPlatform(FilesChannel())
    : const NoDetailsPlatform();

/// Parsed once per app run.
@Riverpod(keepAlive: true)
Future<KnownFiles> knownFiles(Ref ref) async =>
    KnownFiles.parse(await rootBundle.loadString(kKnownFilesAsset));

@Riverpod(keepAlive: true)
Future<KnownApps> knownApps(Ref ref) async =>
    KnownApps.parse(await rootBundle.loadString(kKnownAppsAsset));

@Riverpod(keepAlive: true)
FileDetailsRepository fileDetailsRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return FileDetailsRepository(
    platform: ref.watch(detailsPlatformProvider),
    knownFiles: () => ref.read(knownFilesProvider.future),
    knownApps: () => ref.read(knownAppsProvider.future),
    placeName: (id) => placeNameOf(db, id),
  );
}

/// The file's details; loaded on open, never stored.
@riverpod
Future<FileDetails> fileDetails(Ref ref, FileRef file) =>
    ref.watch(fileDetailsRepositoryProvider).load(file);

/// C5's stored name of the place group holding [fileId] (user title
/// first), or null. Never looks anything up.
Future<String?> placeNameOf(AppDatabase db, String fileId) async {
  final row = await db
      .customSelect(
        'SELECT COALESCE(g.user_title, g.place_name) AS name '
        'FROM smart_group_items i JOIN smart_groups g ON g.id = i.group_id '
        "WHERE i.file_id = ? AND g.kind = 'place' "
        'AND COALESCE(g.user_title, g.place_name) IS NOT NULL LIMIT 1',
        variables: [Variable.withString(fileId)],
        readsFrom: {db.smartGroupItems, db.smartGroups},
      )
      .getSingleOrNull();
  return row?.read<String?>('name');
}
