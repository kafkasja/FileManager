import 'package:meta/meta.dart';

/// `major.minor.patch` of a KFM release (TASK-X7).
@immutable
class AppVersion implements Comparable<AppVersion> {
  const new(this.major, this.minor, this.patch);

  final int major;
  final int minor;
  final int patch;

  static final _pattern = RegExp(r'^[vV]?(\d+)\.(\d+)\.(\d+)(?:[-+].*)?$');

  /// Accepts "v1.2.3" / "1.2.3"; ignores "-suffix" and "+build". Null if
  /// not a version.
  static AppVersion? tryParse(String s) {
    final m = _pattern.firstMatch(s.trim());
    if (m == null) return null;
    final parts = [for (var i = 1; i <= 3; i++) int.tryParse(m.group(i)!)];
    if (parts.contains(null)) return null;
    return AppVersion(parts[0]!, parts[1]!, parts[2]!);
  }

  @override
  int compareTo(AppVersion o) => major != o.major
      ? major.compareTo(o.major)
      : minor != o.minor
      ? minor.compareTo(o.minor)
      : patch.compareTo(o.patch);

  bool operator >(AppVersion o) => compareTo(o) > 0;

  @override
  bool operator ==(Object other) =>
      other is AppVersion && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(major, minor, patch);

  @override
  String toString() => '$major.$minor.$patch';
}
