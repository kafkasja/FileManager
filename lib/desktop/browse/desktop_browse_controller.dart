import 'dart:async';

import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/desktop/shell/desktop_location.dart';
import 'package:kfm/desktop/tabs/desktop_tabs_controller.dart';
import 'package:kfm/desktop/widgets/explorer_view.dart';
import 'package:kfm/desktop/widgets/file_explorer_parts.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'desktop_browse_controller.g.dart';

/// Where desktop Browse is and how it shows it (TASK-PL3 step 3). E3: the
/// folder follows the active tab (`DesktopTabsController`), which also
/// owns Back / Forward.
@immutable
class DesktopBrowseState {
  const new({
    this.folder,
    this.layout = ExplorerLayout.details,
    this.sortColumn = FileColumns.name,
    this.descending = false,
    this.showHidden = false,
  });

  /// The open folder ('/'-separated); null = Home.
  final String? folder;
  final ExplorerLayout layout;

  /// A [FileColumns] id: name, date or size.
  final String sortColumn;
  final bool descending;

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
    bool? showHidden,
  }) => DesktopBrowseState(
    folder: folder == null ? this.folder : folder(),
    layout: layout ?? this.layout,
    sortColumn: sortColumn ?? this.sortColumn,
    descending: descending ?? this.descending,
    showHidden: showHidden ?? this.showHidden,
  );
}

/// Desktop Browse's folder, layout and sort. Kept while the app runs.
@Riverpod(keepAlive: true)
class DesktopBrowseController extends _$DesktopBrowseController {
  @override
  DesktopBrowseState build() {
    unawaited(_restore());
    ref.listen(desktopTabsControllerProvider, (_, next) {
      final loc = next.current.location;
      if (loc is FolderLocation || loc is HomeLocation) {
        final folder = folderOfLocation(loc);
        if (folder != state.folder) {
          state = state.copyWith(folder: () => folder);
        }
      }
    });
    return DesktopBrowseState(
      folder: folderOfLocation(
        ref.read(desktopTabsControllerProvider).current.location,
      ),
    );
  }

  DesktopTabsController get _tabs =>
      ref.read(desktopTabsControllerProvider.notifier);

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

  /// Opens [folder] (null = Home) in the active tab (Back returns).
  void open(String? folder) => _tabs.navigate(
    folder == null ? const HomeLocation() : FolderLocation(folder),
  );

  /// The parent folder; a drive root goes to Home.
  void up() => _tabs.up();

  void goBack() => _tabs.back();

  void goForward() => _tabs.forward();

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

/// The folder a Browse location shows (null = Home / not a folder).
String? folderOfLocation(DesktopLocation loc) =>
    loc is FolderLocation ? loc.path : null;

/// One row of desktop Browse: a folder or a file.
@immutable
sealed class BrowseEntry {
  const new();

  String get id;
  String get name;
}

final class FolderBrowseEntry extends BrowseEntry {
  const new(this.path, {this.fileCount, this.available = true, this.label});

  final String path;
  final int? fileCount;
  final bool available;

  /// E3: shown instead of the folder name (Home's drives: "Local disk
  /// (C:)").
  final String? label;

  /// A drive root (`C:`).
  bool get isDrive => path.length == 2 && path.endsWith(':');

  @override
  String get id => 'dir:$path';

  @override
  String get name {
    if (label case final l?) return l;
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
