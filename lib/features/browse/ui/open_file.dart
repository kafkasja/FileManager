import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/files/file_kind_resolver.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/open_with.dart';
import 'package:kfm/features/apk_install/domain/apk_detect.dart';
import 'package:kfm/features/apk_install/ui/apk_info_sheet.dart';
import 'package:kfm/features/browse/ui/text_viewer_screen.dart';
import 'package:kfm/features/swipe/ui/file_viewer.dart';

/// Normal-mode tap on any file (Browse, B8/C4 results, B7's viewer). Only
/// visual media and text files open inside KFM (and `.apk` files get X5's
/// info sheet); the rest goes to Android "Open with" (user decision
/// 2026-10-24).
Future<void> openFile(BuildContext context, WidgetRef ref, FileRef f) async {
  switch (f.kind) {
    case FileKind.image || FileKind.video:
      await openViewer(
        context,
        f,
        swipeable: false,
        actions: [OpenWithButton(file: f)],
      );
    // X5: an app package shows what it is, then offers Install.
    case _ when Platform.isAndroid && isApk(f):
      await showApkInfoSheet(context, f);
    case _ when isTextFile(f):
      await Navigator.of(
        context,
        rootNavigator: true,
      ).push(TextViewerScreen.route(f));
    case _:
      await openOrExplain(context, ref, f);
  }
}

/// The file's default app (Windows; the chooser on Android). Failures
/// become a snackbar, never silence.
Future<void> openOrExplain(BuildContext context, WidgetRef ref, FileRef f) =>
    _handOff(context, ref, f, (s) => s.open(f));

/// "Open with"; failures become a snackbar (no app, or the system refused).
Future<void> openWithOrExplain(
  BuildContext context,
  WidgetRef ref,
  FileRef f,
) => _handOff(context, ref, f, (s) => s.openWith(f));

Future<void> _handOff(
  BuildContext context,
  WidgetRef ref,
  FileRef f,
  Future<void> Function(OpenWithService s) run,
) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final l10n = context.l10n;
  try {
    await run(ref.read(openWithServiceProvider));
  } on FileOpException catch (e) {
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          e.failure == FileOpFailure.unsupported
              ? l10n.openWithNone
              : l10n.openWithFailed,
        ),
      ),
    );
  } on Object {
    // Anything else (a provider that failed to build, a channel error):
    // still say so.
    messenger?.showSnackBar(SnackBar(content: Text(l10n.openWithFailed)));
  }
}

/// The viewer's / text viewer's "Open with" action.
class OpenWithButton extends ConsumerWidget {
  const new({required this.file, super.key});

  final FileRef file;

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
    tooltip: context.l10n.openWith,
    icon: const Icon(Icons.open_in_new),
    onPressed: () => openWithOrExplain(context, ref, file),
  );
}
