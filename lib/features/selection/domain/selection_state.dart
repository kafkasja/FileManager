import 'package:flutter/foundation.dart' show setEquals;
import 'package:meta/meta.dart';

/// TASK-B6. Normal: tap opens. Select: tap only adds. Edit: tap only
/// removes.
enum SelectionMode { normal, select, edit }

@immutable
class SelectionState {
  const new({
    this.mode = SelectionMode.normal,
    this.ids = const {},
    this.totalBytes = 0,
    this.canRestoreCleared = false,
  });

  final SelectionMode mode;

  /// Unmodifiable; a new set per change.
  final Set<String> ids;
  final int totalBytes;

  /// A Clear all snapshot exists ("Restore last selection").
  final bool canRestoreCleared;

  int get count => ids.length;
  bool get isEmpty => ids.isEmpty;
  bool contains(String id) => ids.contains(id);

  SelectionState copyWith({
    SelectionMode? mode,
    Set<String>? ids,
    int? totalBytes,
    bool? canRestoreCleared,
  }) => SelectionState(
    mode: mode ?? this.mode,
    ids: ids ?? this.ids,
    totalBytes: totalBytes ?? this.totalBytes,
    canRestoreCleared: canRestoreCleared ?? this.canRestoreCleared,
  );

  @override
  bool operator ==(Object other) =>
      other is SelectionState &&
      other.mode == mode &&
      other.totalBytes == totalBytes &&
      other.canRestoreCleared == canRestoreCleared &&
      (identical(other.ids, ids) || setEquals(other.ids, ids));

  @override
  int get hashCode =>
      Object.hash(mode, ids.length, totalBytes, canRestoreCleared);
}
