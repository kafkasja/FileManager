import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/core/db/db_providers.dart';

/// How long a tag/favorite undo snackbar stays (TASK-B9).
const tagUndoDuration = Duration(seconds: 8);

/// Runs [body] on the write queue (ordered, never coalesced) and returns
/// its result. A failure is already published on `dbWriteErrorsProvider`
/// (rule 8); it is rethrown so the caller stops.
Future<T> queuedTagWrite<T>(
  ProviderContainer container,
  Future<T> Function() body,
) async {
  late T result;
  await container.read(dbWriteQueueProvider).enqueue(null, () async {
    result = await body();
  });
  return result;
}

/// Shows "[text] · Undo" for [tagUndoDuration]. [undo] runs the exact
/// inverse of the write (the rows it returned); memory only.
void showTagUndo(
  ScaffoldMessengerState messenger,
  String text, {
  required String undoLabel,
  Future<void> Function()? undo,
}) => messenger
  ..hideCurrentSnackBar()
  ..showSnackBar(
    SnackBar(
      content: Text(text),
      duration: tagUndoDuration,
      persist: false,
      action: undo == null
          ? null
          : SnackBarAction(
              label: undoLabel,
              onPressed: () => unawaited(undo().catchError((Object _) {})),
            ),
    ),
  );
