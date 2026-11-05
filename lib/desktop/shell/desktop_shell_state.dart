import 'dart:async';

import 'package:kfm/core/files/file_ref.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'desktop_shell_state.g.dart';

/// The desktop shell's sections (TASK-PL3), with the shell branch each
/// one shows. Branches 0–3 are the phone's tabs; Devices is desktop-only.
enum DesktopSection {
  sort(0),
  browse(1),
  trash(2),
  devices(4),
  settings(3);

  new(this.branch);

  /// Index of the `StatefulShellBranch` (see `router.dart`).
  final int branch;

  static DesktopSection ofBranch(int branch) =>
      values.firstWhere((s) => s.branch == branch, orElse: () => sort);
}

/// Right details pane shown (Ctrl+I). Off by default (rule 5).
@Riverpod(keepAlive: true)
class DesktopDetailsPane extends _$DesktopDetailsPane {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

/// The focused file of a desktop screen (the details pane shows it).
@Riverpod(keepAlive: true)
class DesktopFocusedFile extends _$DesktopFocusedFile {
  @override
  FileRef? build(DesktopSection section) => null;

  void set(FileRef? file) {
    if (file?.id != state?.id || file?.modifiedAt != state?.modifiedAt) {
      state = file;
    }
  }
}

/// What the status bar says for one section.
@immutable
class DesktopStatus {
  const new({
    this.items,
    this.selected = 0,
    this.selectedBytes = 0,
    this.left,
    this.driveHint,
    this.totalBytes,
    this.message,
  });

  /// Items in view (null = not counted).
  final int? items;
  final int selected;
  final int selectedBytes;

  /// E3: Sort's files still to sort.
  final int? left;

  /// E3: a path whose drive the bar shows (Sort: the focused file).
  final String? driveHint;

  /// E3: the size of everything listed (Trash).
  final int? totalBytes;

  /// E3: the last action ("Trashed 3"), shown for a few seconds.
  final String? message;

  @override
  bool operator ==(Object other) =>
      other is DesktopStatus &&
      other.items == items &&
      other.selected == selected &&
      other.selectedBytes == selectedBytes &&
      other.left == left &&
      other.driveHint == driveHint &&
      other.totalBytes == totalBytes &&
      other.message == message;

  @override
  int get hashCode => Object.hash(
    items,
    selected,
    selectedBytes,
    left,
    driveHint,
    totalBytes,
    message,
  );
}

/// Each desktop screen reports its counts here; the status bar shows the
/// current section's.
@Riverpod(keepAlive: true)
class DesktopStatusLine extends _$DesktopStatusLine {
  @override
  DesktopStatus build(DesktopSection section) => const DesktopStatus();

  void set(DesktopStatus status) {
    if (status != state) state = status;
  }
}

/// E3: the status bar's last action ("Path copied", "Trashed 3"), cleared
/// after a few seconds.
@Riverpod(keepAlive: true)
class DesktopStatusMessage extends _$DesktopStatusMessage {
  Timer? _clear;

  @override
  String? build() {
    ref.onDispose(() => _clear?.cancel());
    return null;
  }

  void show(String message, {Duration duration = const Duration(seconds: 4)}) {
    _clear?.cancel();
    state = message;
    _clear = Timer(duration, () {
      if (ref.mounted) state = null;
    });
  }
}
