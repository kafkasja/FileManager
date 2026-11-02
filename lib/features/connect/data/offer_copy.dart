import 'dart:io';

import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/privacy/domain/location_stripper.dart';
import 'package:kfm/features/transfers/domain/transfer_preprocessor.dart';

/// N12b with X2 "Remove location" on: a photo or video offered to a
/// connected client is prepared once (the deterministic stripper, through
/// the transfer [prepare]) and written to `dir/<seq>-<name>`; the offer
/// then lists and grants that copy. Null = offer the original (X2 off, or
/// not a photo/video). Throws when location can't be removed (the file is
/// never offered with it).
Future<({String path, int sizeBytes})?> prepareOfferCopy(
  FileRef f, {
  required Future<Directory> Function() dir,
  required int seq,
  required Future<bool> Function() enabled,
  required Future<PreparedSource> Function(FileRef f) prepare,
}) async {
  if (!LocationStripper.appliesTo(f) || !await enabled()) return null;
  final prepared = await prepare(f);
  try {
    final folder = await dir();
    await folder.create(recursive: true);
    final out = File('${folder.path}/$seq-${f.name}');
    final sink = out.openWrite();
    try {
      await sink.addStream(prepared.read(0, prepared.sizeBytes));
    } finally {
      await sink.close();
    }
    return (
      path: out.path.replaceAll(r'\', '/'),
      sizeBytes: prepared.sizeBytes,
    );
  } finally {
    await prepared.cleanup();
  }
}
