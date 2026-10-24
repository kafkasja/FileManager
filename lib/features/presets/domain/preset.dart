import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:meta/meta.dart';

/// A row of the presets list (TASK-P6).
@immutable
sealed class PresetEntry {
  const new({required this.id, required this.name, required this.sortOrder});

  final int id;
  final String name;
  final int sortOrder;
}

/// A saved swipe setup: layout + optional filter.
final class Preset extends PresetEntry {
  const new({
    required super.id,
    required super.name,
    required super.sortOrder,
    required this.layout,
    required this.includeReviewed,
    this.filterJson,
  });

  final SwipeLayout layout;

  /// Raw FileFilter JSON, copied into `sessions.filter` as-is.
  final String? filterJson;

  /// P7: include files already reviewed in this preset.
  final bool includeReviewed;
}

/// A row whose layout or filter JSON doesn't decode: "Can't load".
final class PresetLoadError extends PresetEntry {
  const new({required super.id, required super.name, required super.sortOrder});
}

/// Preset names are 1–40 characters after trimming.
const kPresetNameMax = 40;

enum PresetNameProblem { invalid, taken }

class PresetNameException implements Exception {
  const new(this.problem);

  final PresetNameProblem problem;

  @override
  String toString() => 'PresetNameException(${problem.name})';
}

/// Leaving the current preset needs its queued deletes committed; that
/// failed (declined dialog), so the switch didn't happen.
class PresetSwitchBlocked implements Exception {
  const new();
}
