import 'dart:convert';

import 'package:kfm/features/backup/domain/backup_codec.dart';
import 'package:kfm/features/backup/domain/backup_settings_policy.dart';
import 'package:kfm/features/backup/domain/file_matcher.dart';
import 'package:kfm/features/filters/domain/file_filter.dart';
import 'package:kfm/features/presets/domain/preset.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/tags/domain/tag.dart';
import 'package:meta/meta.dart';

// Ids in a plan: >= 0 = an existing local row (0 = Basic for presets),
// < 0 = a row the import creates; the apply step swaps them for the new ids.

@immutable
class PlannedTag {
  const new({required this.id, required this.name, required this.color});

  /// Provisional (negative).
  final int id;
  final String name;
  final int color;
}

@immutable
class PlannedPreset {
  const new({
    required this.id,
    required this.name,
    required this.layout,
    required this.filter,
    required this.includeReviewed,
    required this.sortOrder,
  });

  /// Provisional (negative).
  final int id;
  final String name;

  /// Tag ids are plan ids.
  final SwipeLayout layout;
  final FileFilter? filter;
  final bool includeReviewed;
  final int sortOrder;
}

/// A setting the import overwrites. Exactly one of [raw], [layout] (null
/// with [raw] '' = basic) or [presetId] describes the new value.
@immutable
class PlannedSetting {
  const new({required this.name, this.raw, this.layout, this.presetId});

  final String name;
  final String? raw;

  /// Tag ids are plan ids.
  final SwipeLayout? layout;
  final int? presetId;
}

@immutable
class PlannedReview {
  const new({
    required this.fileId,
    required this.presetId,
    required this.action,
    required this.detail,
    required this.at,
    required this.fileModifiedAtMs,
  });

  final String fileId;

  /// Plan id; 0 = Basic.
  final int presetId;
  final String action;
  final String? detail;
  final DateTime at;

  /// The matched file's current modified time, so it doesn't count as
  /// edited since the review.
  final int fileModifiedAtMs;
}

/// What an import would change, built before anything is written.
@immutable
class ImportPlan {
  const new({
    required this.newTags,
    required this.reusedTags,
    required this.newPresets,
    required this.skippedPresets,
    required this.settingChanges,
    required this.matched,
    required this.unmatched,
    required this.fileTagsToAdd,
    required this.favoritesToAdd,
    required this.reviewedToAdd,
  });

  final List<PlannedTag> newTags;

  /// Backup tags that already exist here (same name, ignoring case).
  final int reusedTags;
  final List<PlannedPreset> newPresets;

  /// Backup presets identical to one here.
  final int skippedPresets;
  final List<PlannedSetting> settingChanges;
  final int matched;
  final List<BackupFile> unmatched;
  final List<({String fileId, int tagId})> fileTagsToAdd;
  final List<String> favoritesToAdd;
  final List<PlannedReview> reviewedToAdd;

  bool get changesData =>
      newTags.isNotEmpty ||
      newPresets.isNotEmpty ||
      fileTagsToAdd.isNotEmpty ||
      favoritesToAdd.isNotEmpty ||
      reviewedToAdd.isNotEmpty;
}

/// This device's rows the plan compares against.
@immutable
class LocalBackupState {
  const new({
    required this.tags,
    required this.presets,
    required this.settings,
    required this.fileTags,
    required this.favorites,
    required this.latestReviews,
  });

  final List<({int id, String name})> tags;
  final List<({int id, String name, String layoutJson, String? filterJson})>
  presets;

  /// Setting name → stored DB value.
  final Map<String, String> settings;

  /// `fileTagKey(fileId, tagId)`.
  final Set<String> fileTags;
  final Set<String> favorites;

  /// `reviewKey(fileId, presetKey)` → newest reviewedAt.
  final Map<String, DateTime> latestReviews;

  static String fileTagKey(String fileId, int tagId) => '$fileId\u0000$tagId';
  static String reviewKey(String fileId, int presetKey) =>
      '$fileId\u0000$presetKey';
}

/// The tag ids of [layout] mapped by [map]; unknown ids (null) leave the
/// action without a tag ("tag missing" at swipe time).
SwipeLayout remapLayoutTags(SwipeLayout layout, int? Function(int) map) {
  SwipeAction fix(SwipeAction a) => a.tagId == null
      ? a
      : SwipeAction(
          a.type,
          targetFolder: a.targetFolder,
          tagId: map(a.tagId!),
          deviceId: a.deviceId,
        );
  return SwipeLayout(
    directions: {
      for (final MapEntry(:key, :value) in layout.directions.entries)
        key: fix(value),
    },
    actionBar: [for (final a in layout.actionBar) fix(a)],
  );
}

/// Unknown ids are dropped.
FileFilter remapFilterTags(FileFilter filter, int? Function(int) map) =>
    filter.copyWith(tagIds: {...filter.tagIds.map(map).nonNulls});

bool _usesNewIds(SwipeLayout l) =>
    [...l.directions.values, ...l.actionBar].any((a) => (a.tagId ?? 0) < 0);

final Map<String, SwipeActionType> _actionNames = SwipeActionType.values
    .asNameMap();

/// Builds the plan. Pure (TASK-X6 merge rules): same-named tags are reused,
/// identical presets skipped and different same-named ones added as
/// "Name (imported)", file tags/favorites only added, a review only when
/// this device has no newer one for that file and preset.
ImportPlan buildImportPlan(
  BackupData data,
  List<IndexedFile?> matches,
  LocalBackupState local, {
  required String importedSuffix,
}) {
  // Tags.
  final tagByName = {for (final t in local.tags) t.name.toLowerCase(): t.id};
  final newTags = <PlannedTag>[];
  final tagMap = <int, int>{};
  var reusedTags = 0;
  for (final t in data.tags) {
    final name = t.name.trim();
    if (name.isEmpty || name.length > kTagNameMax) continue;
    final existing = tagByName[name.toLowerCase()];
    if (existing != null) {
      tagMap[t.key] = existing;
      if (existing >= 0) reusedTags++;
      continue;
    }
    final planned = PlannedTag(
      id: -(newTags.length + 1),
      name: name,
      color: t.color & 0xFFFFFFFF,
    );
    newTags.add(planned);
    tagByName[name.toLowerCase()] = planned.id;
    tagMap[t.key] = planned.id;
  }
  int? mapTag(int key) => tagMap[key];

  // Presets.
  final takenNames = {for (final p in local.presets) p.name.toLowerCase()};
  final localParsed = [
    for (final p in local.presets) (id: p.id, name: p.name, parsed: _parse(p)),
  ];
  final presetMap = <int, int>{0: 0};
  final newPresets = <PlannedPreset>[];
  var skippedPresets = 0;
  for (final p in data.presets) {
    final name = p.name.trim();
    if (name.isEmpty || name.length > kPresetNameMax || p.key == 0) continue;
    final SwipeLayout layout;
    final FileFilter? filter;
    try {
      layout = remapLayoutTags(SwipeLayout.fromJson(p.layout), mapTag);
      filter = p.filter == null
          ? null
          : remapFilterTags(FileFilter.fromJson(p.filter!), mapTag);
    } on FormatException {
      continue;
    }
    final same = localParsed.where(
      (l) =>
          l.name.toLowerCase() == name.toLowerCase() &&
          l.parsed != null &&
          l.parsed!.layout == layout &&
          l.parsed!.filter == filter,
    );
    if (same.isNotEmpty) {
      presetMap[p.key] = same.first.id;
      skippedPresets++;
      continue;
    }
    final finalName = _freeName(name, takenNames, importedSuffix);
    takenNames.add(finalName.toLowerCase());
    final planned = PlannedPreset(
      id: -(newPresets.length + 1),
      name: finalName,
      layout: layout,
      filter: filter,
      includeReviewed: p.includeReviewed,
      sortOrder: p.sortOrder,
    );
    newPresets.add(planned);
    presetMap[p.key] = planned.id;
  }

  // Settings.
  final settingChanges = <PlannedSetting>[];
  for (final MapEntry(:key, :value) in data.settings.entries) {
    final policy = backupSettingsByName[key];
    if (policy == null) continue;
    final raw = policy.canonical(value);
    if (raw == null) continue;
    final current = local.settings[key] ?? policy.defaultRaw;
    switch (policy.kind) {
      case BackupSettingKind.plain:
        if (raw != current) {
          settingChanges.add(PlannedSetting(name: key, raw: raw));
        }
      case BackupSettingKind.layout:
        if (value is! String) continue;
        if (value.isEmpty) {
          if (raw != current) {
            settingChanges.add(PlannedSetting(name: key, raw: raw));
          }
          continue;
        }
        final SwipeLayout layout;
        try {
          layout = switch (jsonDecode(value)) {
            final Map<String, Object?> j => remapLayoutTags(
              SwipeLayout.fromJson(j),
              mapTag,
            ),
            _ => throw const FormatException('not a layout'),
          };
        } on FormatException {
          continue;
        }
        if (!_usesNewIds(layout) &&
            jsonEncode(jsonEncode(layout.toJson())) == current) {
          continue;
        }
        settingChanges.add(PlannedSetting(name: key, layout: layout));
      case BackupSettingKind.preset:
        if (value is! int) continue;
        final id = presetMap[value];
        if (id == null) continue;
        if (id >= 0 && jsonEncode(id) == current) continue;
        settingChanges.add(PlannedSetting(name: key, presetId: id));
    }
  }

  // Files.
  final unmatched = <BackupFile>[];
  final fileTagsToAdd = <({String fileId, int tagId})>[];
  final favoritesToAdd = <String>[];
  final reviewedToAdd = <PlannedReview>[];
  var matched = 0;
  for (final (i, f) in data.files.indexed) {
    final hit = i < matches.length ? matches[i] : null;
    if (hit == null) {
      unmatched.add(f);
      continue;
    }
    matched++;
    final tagIds = {...f.tags.map(mapTag).nonNulls};
    for (final tagId in tagIds) {
      if (tagId >= 0 &&
          local.fileTags.contains(LocalBackupState.fileTagKey(hit.id, tagId))) {
        continue;
      }
      fileTagsToAdd.add((fileId: hit.id, tagId: tagId));
    }
    if (f.favorite && !local.favorites.contains(hit.id)) {
      favoritesToAdd.add(hit.id);
    }
    final newest = <int, BackupReview>{};
    for (final r in f.reviewed) {
      final presetId = presetMap[r.preset];
      if (presetId == null || !_actionNames.containsKey(r.action)) continue;
      final prev = newest[presetId];
      if (prev == null || r.at.isAfter(prev.at)) newest[presetId] = r;
    }
    for (final MapEntry(key: presetId, value: r) in newest.entries) {
      final existing =
          local.latestReviews[LocalBackupState.reviewKey(hit.id, presetId)];
      if (existing != null && !existing.isBefore(r.at)) continue;
      reviewedToAdd.add(
        PlannedReview(
          fileId: hit.id,
          presetId: presetId,
          action: r.action,
          detail: r.detail,
          at: r.at,
          fileModifiedAtMs: hit.modifiedAtMs,
        ),
      );
    }
  }

  return ImportPlan(
    newTags: List.unmodifiable(newTags),
    reusedTags: reusedTags,
    newPresets: List.unmodifiable(newPresets),
    skippedPresets: skippedPresets,
    settingChanges: List.unmodifiable(settingChanges),
    matched: matched,
    unmatched: List.unmodifiable(unmatched),
    fileTagsToAdd: List.unmodifiable(fileTagsToAdd),
    favoritesToAdd: List.unmodifiable(favoritesToAdd),
    reviewedToAdd: List.unmodifiable(reviewedToAdd),
  );
}

({SwipeLayout layout, FileFilter? filter})? _parse(
  ({int id, String name, String layoutJson, String? filterJson}) p,
) {
  try {
    final layout = switch (jsonDecode(p.layoutJson)) {
      final Map<String, Object?> j => SwipeLayout.fromJson(j),
      _ => throw const FormatException('layout'),
    };
    final filter = p.filterJson == null
        ? null
        : switch (jsonDecode(p.filterJson!)) {
            final Map<String, Object?> j => FileFilter.fromJson(j),
            _ => throw const FormatException('filter'),
          };
    return (layout: layout, filter: filter);
  } on FormatException {
    return null;
  }
}

/// "Name (imported)", then "Name (imported 2)" …, within [kPresetNameMax].
String _freeName(String name, Set<String> taken, String suffix) {
  if (!taken.contains(name.toLowerCase())) return name;
  for (var n = 1; ; n++) {
    final s = n == 1 ? ' ($suffix)' : ' ($suffix $n)';
    final base = name.length + s.length > kPresetNameMax
        ? name.substring(0, kPresetNameMax - s.length).trimRight()
        : name;
    final candidate = '$base$s';
    if (!taken.contains(candidate.toLowerCase())) return candidate;
  }
}
