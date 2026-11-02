import 'dart:io';
import 'dart:math';

import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/utils/random_id.dart';
import 'package:kfm/features/privacy/domain/location_stripper.dart';
import 'package:kfm/features/transfers/data/transfer_run.dart';
import 'package:kfm/features/transfers/domain/transfer_job.dart';
import 'package:kfm/features/transfers/domain/transfer_preprocessor.dart';

/// N9 hook (TASK-X2): with "Remove location when sharing" on, photos and
/// videos are uploaded from a stripped copy; everything else (and all files
/// with the option off) goes through the fallback (as it is). The copy is the same bytes
/// on every attempt (N10 resumes by offset; the sender hash is of these
/// bytes, so N11's verify compares the stripped copy) and is deleted when
/// the attempt ends. A file whose location can't be removed fails with
/// [TransferErrors.locationNotRemoved].
class PrivacyTransferPreprocessor implements TransferPreprocessor {
  new({
    required this._enabled,
    required this._stripper,
    this._fallback = const IdentityPreprocessor(),
    Random? random,
  }) : _random = random ?? Random.secure();

  final Future<bool> Function() _enabled;
  final LocationStripper _stripper;
  final TransferPreprocessor _fallback;
  final Random _random;

  @override
  Future<PreparedSource> prepare(FileRef f, FileSource source) async {
    if (!LocationStripper.appliesTo(f) || !await _enabled()) {
      return await _fallback.prepare(f, source);
    }
    final sendId = 'tx-${randomHexId(_random)}';
    final StrippedFile copy;
    try {
      copy = await _stripper.stripToTemp(f, sendId: sendId);
    } on LocationStripException {
      await _stripper.release(sendId);
      // Never sent with location: the file fails (no retry helps).
      throw const TransferFailure(TransferErrors.locationNotRemoved);
    }
    final path = copy.path;
    return PreparedSource(
      sizeBytes: copy.sizeBytes,
      path: path,
      read: (start, end) => File(path).openRead(start, end),
      cleanup: () => _stripper.release(sendId),
    );
  }
}
