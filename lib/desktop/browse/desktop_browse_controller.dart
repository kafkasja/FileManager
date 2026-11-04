import 'dart:async';

import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/desktop/widgets/explorer_view.dart';
import 'package:kfm/desktop/widgets/file_explorer_parts.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'desktop_browse_controller.g.dart';

/// Where desktop Browse is and how it shows it (TASK-PL3 step 3).
@immutable
class DesktopBrowseState {
  const new({
    this.folder,
    this.layout = ExplorerLayout.details,
    this.sortColumn = FileColumns.name,
    this.descending = false,
    this.back = const [],
    this.forward = const [],
    this.showHidden = false,
  });

  /// The open folder ('/'-separated); null = Places (the scanned folders).
  final String? folder;
  final ExplorerLayout layout;

  /// A [FileColumns] id: name, date or size.
  final String sortColumn;
  final bool descending;

  /// Back / Forward history (Alt+← / Alt+→).
  final List<String?> back;
  final List<String?> forward;

  /// Hidden items (dot-files, the Windows hidden attribute) are shown.
  /// For this run only, like the phone's Browse.
  final bool showHidden;

  /// The index sort for the files of the folder.
  FileSort get fileSort => FileSort(switch (sortColumn) {
    FileColumns.date => FileSortField.date,
    FileColumns.size => FileSortField.size,
    _ => FileSortField.name,
  }, descending: descending);

  /// The files of [folder] (not its subfolders), hidden files left out
  /// unless [showHidden].
  IndexQuery? get filesQuery => switch (folder) {
    final f? => IndexQuery(
      folderPath: f,
      sort: fileSort,
      hidden: showHidden ? HiddenFilter.include : HiddenFilter.exclude,
    ),
    null => null,
  };

  /// The index scope for [folder]'s subfolders.
  IndexQuery get foldersScope => showHidden
      ? const IndexQuery(hidden: HiddenFilter.include)
      : IndexQuery.all;

  DesktopBrowseState copyWith({
    String? Function()? folder,
    ExplorerLayout? layout,
    String? sortColumn,
    bool? descending,
    List<String?>? back,
    List<String?>? forward,
    bool? showHidden,
  }) => DesktopBrowseState(
    folder: folder == null ? this.folder : folder(),
    layout: layout ?? this.layout,
    sortColumn: sortColumn ?? this.sortColumn,
    descending: descending ?? this.descending,
    back: back ?? this.back,
    forward: forward ?? this.forward,
    showHidden: showHidden ?? this.showHidden,
  );
}

/// Desktop Browse's folder, layout and sort. Kept while the app runs.
@Riverpod(keepAlive: true)
class DesktopBrowseController extends _$DesktopBrowseController {
  @override
  DesktopBrowseState build() {
    unawaited(_restore());
    return const DesktopBrowseState();
  }

  /// The last layout and sort (PL3 polish: remembered between runs).
  Future<void> _restore() async {
    final settings = ref.read(settingsRepositoryProvider);
    final String layout;
    final String sort;
    try {
      layout = await settings.read(AppSettings.desktopBrowseLayout);
      sort = await settings.read(AppSettings.desktopBrowseSort);
    } on Object {
      return; // Defaults stay.
    }
    if (!ref.mounted) return;
    final parts = sort.split(':');
    final column = switch (parts.first) {
      FileColumns.date => FileColumns.date,
      FileColumns.size => FileColumns.size,
      _ => FileColumns.name,
    };
    state = state.copyWith(
      layout: ExplorerLayout.values.asNameMap()[layout] ?? state.layout,
      sortColumn: column,
      descending: parts.length > 1 && parts[1] == 'desc',
    );
  }

  void _save() {
    final settings = ref.read(settingsRepositoryProvider);
    settings
        .write(AppSettings.desktopBrowseLayout, state.layout.name)
        .fireAndForget();
    settings
        .write(
          AppSettings.desktopBrowseSort,
          '${state.sortColumn}:${state.descending ? 'desc' : 'asc'}',
        )
        .fireAndForget();
  }

  void setShowHidden({required bool show}) =>
      state = state.copyWith(showHidden: show);

  /// Opens [folder] (null = Places), remembering where it came from.
  void open(String? folder) {
    if (folder == state.folder) return;
    state = state.copyWith(
      folder: () => folder,
      back: [...state.back, state.folder],
      forward: const [],
    );
  }

  /// The parent folder; from a top folder back to Places.
  void up({Set<String> roots = const {}}) {
    final f = state.folder;
    if (f == null) return;
    final slash = f.lastIndexOf('/');
    open(roots.contains(f) || slash <= 0 ? null : f.substring(0, slash));
  }

  void goBack() {
    if (state.back.isEmpty) return;
    final to = state.back.last;
    state = state.copyWith(
      folder: () => to,
      back: state.back.sublist(0, state.back.length - 1),
      forward: [state.folder, ...state.forward],
    );
  }

  void goForward() {
    if (state.forward.isEmpty) return;
    final to = state.forward.first;
    state = state.copyWith(
      folder: () => to,
      back: [...state.back, state.folder],
      forward: state.forward.sublist(1),
    );
  }

  void setLayout(ExplorerLayout layout) {
    state = state.copyWith(layout: layout);
    _save();
  }

  /// A column header click: that column, or the other direction when it is
  /// already the sort column. Dates and sizes start largest/newest first.
  void sortBy(String column) {
    if (column == FileColumns.type) return;
    state = column == state.sortColumn
        ? state.copyWith(descending: !state.descending)
        : state.copyWith(
            sortColumn: column,
            descending: column != FileColumns.name,
          );
    _save();
  }
}

/// One row of desktop Browse: a folder or a file.
@immutable
sealed class BrowseEntry {
  const new();

  String get id;
  String get name;
}

final class FolderBrowseEntry extends BrowseEntry {
  const new(this.path, {this.fileCount, this.available = true});

  final String path;
  final int? fileCount;
  final bool available;

  @override
  String get id => 'dir:$path';

  @override
  String get name {
    final i = path.lastIndexOf('/');
    return i < 0 ? path : path.substring(i + 1);
  }
}

final class FileBrowseEntry extends BrowseEntry {
  const new(this.file);

  final FileRef file;

  @override
  String get id => file.id;

  @override
  String get name => file.name;
}
