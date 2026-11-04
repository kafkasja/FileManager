import 'dart:io';

import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/core/platform/host_platform.dart';
import 'package:kfm/core/platform/volumes/mtp_channel.dart';
import 'package:kfm/core/platform/volumes/volumes_channel.dart';
import 'package:kfm/core/platform/windows/index_roots.dart';
import 'package:kfm/core/platform/windows/windows_volumes.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'volumes_providers.g.dart';

/// U1: the volume list (Android volumes, Windows drive letters). Null
/// elsewhere (and in tests unless overridden): then there are no places
/// and nothing is treated as detached.
@Riverpod(keepAlive: true)
VolumesPlatform? volumesPlatform(Ref ref) {
  if (Platform.isAndroid) return VolumesChannel();
  if (isWindowsHost) return WindowsVolumes(ref.watch(windowsChannelProvider));
  return null;
}

/// U1: cameras over USB. Null off Android.
@Riverpod(keepAlive: true)
MtpPlatform? mtpPlatform(Ref ref) => Platform.isAndroid ? MtpChannel() : null;

final _internalRoot = RegExp(r'^/storage/emulated(/|$)');

/// U1: indexed roots of removable volumes that aren't mounted in [volumes].
Set<String> detachedRoots(Set<String> indexedRoots, List<VolumeInfo> volumes) {
  final mounted = {
    for (final v in volumes)
      if (v.isMounted && v.rootPath != null) v.rootPath!,
  };
  return {
    for (final root in indexedRoots)
      if (!mounted.contains(root) && !_internalRoot.hasMatch(root)) root,
  };
}

/// U1: volume roots with indexed rows that could go away: `/storage/<id>`
/// on Android, every drive letter on Windows (the mounted ones drop out in
/// [detachedRoots]).
Future<Set<String>> indexedRemovableRoots(MediaIndexDao dao) =>
    isWindowsHost ? dao.indexedDriveRoots() : dao.indexedVolumeRoots();

/// U1: [detachedRoots] from a fresh volume list (the indexer's `keepRoots`,
/// so a scan never deletes the rows of a card that's only away).
Future<Set<String>> readDetachedRoots(
  MediaIndexDao dao,
  VolumesPlatform volumes,
) async {
  final indexed = await indexedRemovableRoots(dao);
  if (indexed.isEmpty) return const {};
  return detachedRoots(indexed, await volumes.list());
}

/// U1: roots of the mounted removable volumes reached by path (API 30+;
/// with All files access, which the walker checks itself). Full scans walk
/// them next to internal storage; below API 30 these volumes are SAF-only.
Future<List<String>> readDirectPathRemovableRoots(
  VolumesPlatform volumes,
) async {
  if (await volumes.sdkInt() < 30) return const [];
  return [
    for (final v in await volumes.list())
      if (!v.isPrimary && v.isMounted && v.uuid != null) ?v.rootPath,
  ];
}

/// PL1: roots of the mounted removable drives on Windows (USB sticks, SD
/// cards, USB disks). Full scans walk them next to the index roots.
Future<List<String>> readMountedRemovableRoots(
  VolumesPlatform volumes,
) async => [
  for (final v in await volumes.list())
    if (!v.isPrimary && !v.isFixed && v.isRemovable && v.isMounted) ?v.rootPath,
];
