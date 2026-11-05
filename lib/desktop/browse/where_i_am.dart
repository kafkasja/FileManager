import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/platform/host_platform.dart';
import 'package:kfm/core/platform/windows/index_roots.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

/// TASK-E2 §6: desktop Browse tells the Windows index which folder is open.
/// With Look everywhere off ([IndexScope.whereIAm]) opening a folder scans
/// it, and the full scan drops index rows outside the open folders (tags,
/// favorites and reviewed marks live in their own tables). E3's tabs pass
/// every open tab's folder instead of one.
void syncWhereIAm(Ref ref, List<String> openFolders) {
  if (!isWindowsHost) return;
  final roots = ref.read(windowsIndexRootsProvider)
    ..setOpenFolders(openFolders);
  if (openFolders.isEmpty) return;
  roots.scope().then((scope) {
    if (scope != IndexScope.whereIAm || !ref.mounted) return;
    ref.read(mediaIndexerProvider).fullScan().ignore();
  }).ignore();
}
