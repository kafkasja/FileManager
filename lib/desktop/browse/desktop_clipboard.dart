import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/platform/windows/windows_clipboard.dart';
import 'package:kfm/desktop/shell/desktop_drops.dart';
import 'package:kfm/features/folders/domain/file_operation.dart';
import 'package:kfm/features/folders/ui/file_op_flow.dart';
import 'package:kfm/features/folders/ui/local_job_flow.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'desktop_clipboard.g.dart';

/// Files (and folders) copied (Ctrl+C) or cut (Ctrl+X) inside KFM.
@immutable
class DesktopClip {
  const new(
    this.files, {
    required this.cut,
    this.folders = const [],
    this.systemSequence,
  });

  final List<FileRef> files;
  final bool cut;

  /// Whole folders ('/'-separated paths).
  final List<String> folders;

  /// The Windows clipboard's sequence number right after KFM put these
  /// paths there; another value later = someone else wrote it since.
  final int? systemSequence;

  bool get isEmpty => files.isEmpty && folders.isEmpty;

  /// Every path (files, then folders), for the Windows clipboard.
  List<String> get paths => [for (final f in files) f.path, ...folders];
}

/// KFM's own clipboard for files and folders (TASK-PL3: Ctrl+C/X/V). The
/// Windows clipboard mirrors it ([copyToClipboard] / [pasteClipboard]).
@Riverpod(keepAlive: true)
class DesktopClipboard extends _$DesktopClipboard {
  @override
  DesktopClip? build() => null;

  void set(
    List<FileRef> files, {
    required bool cut,
    List<String> folders = const [],
    int? systemSequence,
  }) => state = files.isEmpty && folders.isEmpty
      ? null
      : DesktopClip(
          List.unmodifiable(files),
          cut: cut,
          folders: List.unmodifiable(folders),
          systemSequence: systemSequence,
        );

  void clear() => state = null;
}

/// Ctrl+C / Ctrl+X: KFM's clipboard, and the same paths on the Windows
/// clipboard so Explorer can paste them (a cut pasted in Explorer is
/// Explorer's own move: KFM's Undo doesn't cover it).
Future<void> copyToClipboard(
  WidgetRef ref,
  List<FileRef> files, {
  required bool cut,
  List<String> folders = const [],
}) async {
  if (files.isEmpty && folders.isEmpty) return;
  final clipboard = ref.read(desktopClipboardProvider.notifier)
    ..set(files, cut: cut, folders: folders);
  final mine = ref.read(desktopClipboardProvider);
  final system = ref.read(systemFileClipboardProvider);
  if (system == null || mine == null) return;
  final seq = await system.write(mine.paths, cut: cut);
  // Only when no newer Ctrl+C/X replaced it meanwhile.
  if (seq != null && identical(ref.read(desktopClipboardProvider), mine)) {
    clipboard.set(files, cut: cut, folders: folders, systemSequence: seq);
  }
}

/// Ctrl+V into [folder]: what KFM copied last, unless something else
/// (Explorer) wrote the Windows clipboard since; then its files are copied
/// in (or moved, for an Explorer Cut, which then empties the clipboard).
/// Returns false when there was nothing to paste.
Future<bool> pasteClipboard(
  BuildContext context,
  WidgetRef ref,
  String folder,
) async {
  var clip = ref.read(desktopClipboardProvider);
  final system = ref.read(systemFileClipboardProvider);
  final sys = system == null ? null : await system.read();
  if (!context.mounted) return false;
  if (clip?.systemSequence case final seq?
      when sys != null && seq != sys.sequence) {
    // Copied or cut elsewhere since (or KFM's cut was pasted in Explorer).
    ref.read(desktopClipboardProvider.notifier).clear();
    clip = null;
  }
  if (clip != null) {
    final wasCut = clip.cut;
    await pasteFiles(context, ref, clip, folder);
    if (wasCut) await system?.clear();
    return true;
  }
  if (sys == null || sys.paths.isEmpty) return false;
  await importPaths(context, ref, sys.paths, folder, move: sys.cut);
  if (sys.cut) await system?.clear();
  return true;
}

/// Ctrl+V into [folder]: B4's copy/move (or a U2 job across places), with
/// its collision dialog, progress and Undo; folders go through
/// `transferFolders`. A cut is used up by the paste.
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
  if (files.isEmpty && clip.folders.isEmpty) return;
  if (clip.cut) ref.read(desktopClipboardProvider.notifier).clear();
  if (clip.folders.isNotEmpty) {
    await transferFolders(
      context,
      ref,
      folders: clip.folders,
      files: files,
      target: folder,
      move: clip.cut,
    );
    return;
  }
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
