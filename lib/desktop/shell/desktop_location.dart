import 'package:kfm/desktop/shell/desktop_shell_state.dart';
import 'package:meta/meta.dart';

/// What one desktop tab shows (TASK-E3).
@immutable
sealed class DesktopLocation {
  const new();

  /// A stored location; anything unknown is Home.
  static DesktopLocation fromJson(Map<String, Object?> j) => switch (j['k']) {
    'folder' => switch (j['path']) {
      final String p when p.isNotEmpty => FolderLocation(p),
      _ => const HomeLocation(),
    },
    'search' => switch (j['q']) {
      final String q => SearchLocation(q, scope: j['scope'] as String?),
      _ => const HomeLocation(),
    },
    'sort' => const SortLocation(),
    'trash' => const TrashLocation(),
    'devices' => const DevicesLocation(),
    'settings' => const SettingsLocation(),
    'route' => switch (j['uri']) {
      final String u when u.startsWith('/') => RouteLocation(u),
      _ => const HomeLocation(),
    },
    _ => const HomeLocation(),
  };

  Map<String, Object?> toJson();

  /// Sort/Trash/Devices/Settings exist once: opening one focuses its tab.
  bool get singleInstance => false;

  /// The shell section (branch) that shows it.
  DesktopSection get section => DesktopSection.browse;
}

/// Quick access pins + drives (Explorer's Home, without recent files).
final class HomeLocation extends DesktopLocation {
  const new();

  @override
  Map<String, Object?> toJson() => const {'k': 'home'};

  @override
  bool operator ==(Object other) => other is HomeLocation;

  @override
  int get hashCode => 0;
}

/// One folder on disk ('/'-separated, a drive root is `C:`).
final class FolderLocation extends DesktopLocation {
  const new(this.path);

  final String path;

  @override
  Map<String, Object?> toJson() => {'k': 'folder', 'path': path};

  @override
  bool operator ==(Object other) =>
      other is FolderLocation && other.path.toLowerCase() == path.toLowerCase();

  @override
  int get hashCode => path.toLowerCase().hashCode;
}

/// Search results for [query] inside [scope] (a folder; null = everywhere).
final class SearchLocation extends DesktopLocation {
  const new(this.query, {this.scope});

  final String query;
  final String? scope;

  @override
  Map<String, Object?> toJson() => {
    'k': 'search',
    'q': query,
    if (scope != null) 'scope': scope,
  };

  @override
  bool operator ==(Object other) =>
      other is SearchLocation && other.query == query && other.scope == scope;

  @override
  int get hashCode => Object.hash(query, scope);
}

final class SortLocation extends DesktopLocation {
  const new();

  @override
  Map<String, Object?> toJson() => const {'k': 'sort'};

  @override
  bool get singleInstance => true;

  @override
  DesktopSection get section => DesktopSection.sort;

  @override
  bool operator ==(Object other) => other is SortLocation;

  @override
  int get hashCode => 1;
}

final class TrashLocation extends DesktopLocation {
  const new();

  @override
  Map<String, Object?> toJson() => const {'k': 'trash'};

  @override
  bool get singleInstance => true;

  @override
  DesktopSection get section => DesktopSection.trash;

  @override
  bool operator ==(Object other) => other is TrashLocation;

  @override
  int get hashCode => 2;
}

final class DevicesLocation extends DesktopLocation {
  const new();

  @override
  Map<String, Object?> toJson() => const {'k': 'devices'};

  @override
  bool get singleInstance => true;

  @override
  DesktopSection get section => DesktopSection.devices;

  @override
  bool operator ==(Object other) => other is DevicesLocation;

  @override
  int get hashCode => 3;
}

final class SettingsLocation extends DesktopLocation {
  const new();

  @override
  Map<String, Object?> toJson() => const {'k': 'settings'};

  @override
  bool get singleInstance => true;

  @override
  DesktopSection get section => DesktopSection.settings;

  @override
  bool operator ==(Object other) => other is SettingsLocation;

  @override
  int get hashCode => 4;
}

/// A screen without a typed location (collections, similar, groups…):
/// its go_router [uri].
final class RouteLocation extends DesktopLocation {
  const new(this.uri);

  final String uri;

  @override
  Map<String, Object?> toJson() => {'k': 'route', 'uri': uri};

  @override
  DesktopSection get section => sectionOfUri(uri);

  /// The shell section a go_router location belongs to.
  static DesktopSection sectionOfUri(String uri) {
    if (uri.startsWith('/swipe')) return DesktopSection.sort;
    if (uri.startsWith('/trash')) return DesktopSection.trash;
    if (uri.startsWith('/settings')) return DesktopSection.settings;
    if (uri.startsWith('/connect') || uri.startsWith('/devices')) {
      return DesktopSection.devices;
    }
    return DesktopSection.browse;
  }

  @override
  bool operator ==(Object other) => other is RouteLocation && other.uri == uri;

  @override
  int get hashCode => uri.hashCode;
}
