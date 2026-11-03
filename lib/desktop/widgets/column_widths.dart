import 'dart:async';
import 'dart:convert';

import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'column_widths.g.dart';

/// The desktop lists whose Details columns can be resized.
abstract final class ColumnWidthLists {
  static const browse = 'browse';
  static const sort = 'sort';
  static const trash = 'trash';
}

/// [AppSettings.desktopColumnWidths] → list id → column id → width.
/// Anything malformed is dropped (the defaults stay).
Map<String, Map<String, double>> decodeColumnWidths(String raw) {
  if (raw.isEmpty) return const {};
  final Object? json;
  try {
    json = jsonDecode(raw);
  } on FormatException {
    return const {};
  }
  if (json is! Map<String, Object?>) return const {};
  return {
    for (final MapEntry(:key, :value) in json.entries)
      if (value is Map<String, Object?>)
        key: {
          for (final c in value.entries)
            if (c.value case final num w when w.isFinite && w > 0)
              c.key: w.toDouble(),
        },
  };
}

String encodeColumnWidths(Map<String, Map<String, double>> widths) =>
    widths.isEmpty
    ? ''
    : jsonEncode({
        for (final MapEntry(:key, :value) in widths.entries)
          if (value.isNotEmpty) key: value,
      });

/// Column widths the user dragged in the desktop Details lists (PL3),
/// remembered between runs. Kept per PC (not in X6 backups: they fit this
/// screen).
@Riverpod(keepAlive: true)
class DesktopColumnWidths extends _$DesktopColumnWidths {
  /// A change before the stored value is read wins over it.
  bool _changed = false;

  @override
  Map<String, Map<String, double>> build() {
    _changed = false;
    unawaited(_restore());
    return const {};
  }

  Future<void> _restore() async {
    final String raw;
    try {
      raw = await ref
          .read(settingsRepositoryProvider)
          .read(AppSettings.desktopColumnWidths);
    } on Object {
      return; // Defaults stay.
    }
    if (!ref.mounted || _changed) return;
    state = decodeColumnWidths(raw);
  }

  /// [list]'s dragged widths (unscaled; empty = all defaults).
  void save(String list, Map<String, double> widths) {
    _changed = true;
    final next = {...state};
    if (widths.isEmpty) {
      next.remove(list);
    } else {
      next[list] = Map.unmodifiable(widths);
    }
    state = Map.unmodifiable(next);
    ref
        .read(settingsRepositoryProvider)
        .write(AppSettings.desktopColumnWidths, encodeColumnWidths(next))
        .fireAndForget();
  }
}
