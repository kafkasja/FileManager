import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/platform/host_platform.dart';
import 'package:kfm/core/platform/windows/index_roots.dart';
import 'package:kfm/features/browse/ui/browse_controller.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'desktop_shell_state.g.dart';

/// The desktop sidebar's sections (TASK-PL3), with the shell branch each
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

/// Sidebar collapsed to icons.
@Riverpod(keepAlive: true)
class DesktopSidebarCollapsed extends _$DesktopSidebarCollapsed {
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
  const new({this.items, this.selected = 0, this.selectedBytes = 0});

  /// Items in view (null = not counted).
  final int? items;
  final int selected;
  final int selectedBytes;

  @override
  bool operator ==(Object other) =>
      other is DesktopStatus &&
      other.items == items &&
      other.selected == selected &&
      other.selectedBytes == selectedBytes;

  @override
  int get hashCode => Object.hash(items, selected, selectedBytes);
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

/// One folder under Places.
@immutable
class DesktopPlace {
  const new(this.path, {this.available = true});

  /// '/'-separated, no trailing '/' (a drive root is `C:`).
  final String path;
  final bool available;

  String get name {
    final i = path.lastIndexOf('/');
    return i < 0 ? path : path.substring(i + 1);
  }

  @override
  bool operator ==(Object other) =>
      other is DesktopPlace &&
      other.path == path &&
      other.available == available;

  @override
  int get hashCode => Object.hash(path, available);
}

/// Places in the sidebar: on Windows the folders KFM scans (PL1 index
/// roots: Pictures, Videos, Downloads, Documents by default), elsewhere the
/// index's top folders. Drives and devices come later (TASK-PL3 step 5).
@riverpod
Future<List<DesktopPlace>> desktopPlaces(Ref ref) async {
  if (isWindowsHost) {
    final roots = await ref.watch(windowsIndexRootStatusProvider.future);
    return [
      for (final r in roots)
        DesktopPlace(r.path.replaceAll(r'\', '/'), available: r.available),
    ];
  }
  final folders = await ref.watch(browseFoldersProvider(IndexQuery.all).future);
  return [for (final f in folders) DesktopPlace(f.path)];
}
