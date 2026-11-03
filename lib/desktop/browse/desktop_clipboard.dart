import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/folders/domain/file_operation.dart';
import 'package:kfm/features/folders/ui/file_op_flow.dart';
import 'package:kfm/features/folders/ui/local_job_flow.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'desktop_clipboard.g.dart';

/// Files copied (Ctrl+C) or cut (Ctrl+X) inside KFM.
@immutable
class DesktopClip {
  const new(this.files, {required this.cut});

  final List<FileRef> files;
  final bool cut;
}

/// KFM's own clipboard for files (TASK-PL3: Ctrl+C/X/V within KFM; the
/// Windows clipboard comes with drag & drop in step 4).
@Riverpod(keepAlive: true)
class DesktopClipboard extends _$DesktopClipboard {
  @override
  DesktopClip? build() => null;

  void set(List<FileRef> files, {required bool cut}) => state = files.isEmpty
      ? null
      : DesktopClip(List.unmodifiable(files), cut: cut);

  void clear() => state = null;
}

/// Ctrl+V into [folder]: B4's copy/move (or a U2 job across places), with
/// its collision dialog, progress and Undo. A cut is used up by the paste.
Future<void> pasteFiles(
  BuildContext context,
  WidgetRef ref,
  DesktopClip clip,
  String folder,
) async {
  final files = clip.cut
      ? [
          for (final f in clip.files)
            if (f.folderPath != folder) f,
        ]
      : clip.files;
  if (files.isEmpty) return;
  if (clip.cut) ref.read(desktopClipboardProvider.notifier).clear();
  if (needsLocalJob(ref, files, folder)) {
    await startLocalJobFlow(context, ref, files, folder, move: clip.cut);
    return;
  }
  await runFileOperation(
    context,
    ref,
    clip.cut ? MoveOp(files, folder) : CopyOp(files, folder),
  );
}
