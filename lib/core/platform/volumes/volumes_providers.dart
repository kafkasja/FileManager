import 'dart:io';

import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/core/platform/volumes/mtp_channel.dart';
import 'package:kfm/core/platform/volumes/volumes_channel.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'volumes_providers.g.dart';

/// U1: the volume list. Null off Android (and in tests unless overridden):
/// then there are no places and nothing is treated as detached.
@Riverpod(keepAlive: true)
VolumesPlatform? volumesPlatform(Ref ref) =>
    Platform.isAndroid ? VolumesChannel() : null;

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

/// U1: [detachedRoots] from a fresh volume list (the indexer's `keepRoots`,
/// so a scan never deletes the rows of a card that's only away).
Future<Set<String>> readDetachedRoots(
  MediaIndexDao dao,
  VolumesPlatform volumes,
) async {
  final indexed = await dao.indexedVolumeRoots();
  if (indexed.isEmpty) return const {};
  return detachedRoots(indexed, await volumes.list());
}
