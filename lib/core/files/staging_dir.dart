import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Where transfer partials are written before `FileSource.importFile`
/// publishes them (TASK-N9): private to KFM, hidden from galleries, never
/// inside a shared folder. Android: the app-specific external folder
/// (`Android/data/com.kaf.kfm/files/transfers`, same volume as primary
/// storage, excluded by N4's path guard); elsewhere the app support folder.
///
/// Client partials: `dl-<transferFileId>.part`; server partials:
/// `up-<uploadId>.part` + `.json`.
Future<Directory> transferStagingDir() async {
  Directory? base;
  if (Platform.isAndroid) base = await getExternalStorageDirectory();
  base ??= await getApplicationSupportDirectory();
  final dir = Directory('${base.path}/transfers');
  await dir.create(recursive: true);
  return dir;
}
