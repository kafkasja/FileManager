import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/tables/smart_groups_table.dart';
import 'package:kfm/features/smart_groups/data/smart_groups_providers.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// Displayed title of a Trip/Place (never stored in English):
/// `userTitle ?? placeName ?? generated`.
String smartGroupTitle(AppLocalizations l10n, SmartGroupRow g) =>
    g.userTitle ??
    g.placeName ??
    switch (g.kind) {
      SmartGroupKind.place => l10n.smartGroupPlace(g.rank),
      SmartGroupKind.trip => _tripTitle(l10n, g.startAtMs, g.endAtMs),
    };

String _tripTitle(AppLocalizations l10n, int startMs, int endMs) {
  final start = DateTime.fromMillisecondsSinceEpoch(startMs);
  final end = DateTime.fromMillisecondsSinceEpoch(endMs);
  final sameDay =
      start.year == end.year &&
      start.month == end.month &&
      start.day == end.day;
  return sameDay
      ? l10n.smartGroupTripOneDay(start)
      : l10n.smartGroupTrip(start, end);
}

String liveGroupTitle(AppLocalizations l10n, LiveGroup g) => switch (g) {
  LiveGroup.screenshots => l10n.groupsScreenshots,
  LiveGroup.selfies => l10n.groupsSelfies,
  LiveGroup.documents => l10n.groupsDocuments,
};

/// Route key of a group detail screen: `screenshots` | `selfies` |
/// `documents` | `g<id>`.
sealed class GroupKey {
  const new();

  static GroupKey? parse(String key) {
    for (final g in LiveGroup.values) {
      if (g.name == key) return LiveGroupKey(g);
    }
    if (key.startsWith('g')) {
      final id = int.tryParse(key.substring(1));
      if (id != null && id > 0) return StoredGroupKey(id);
    }
    return null;
  }

  String get value;
}

final class LiveGroupKey extends GroupKey {
  const new(this.group);

  final LiveGroup group;

  @override
  String get value => group.name;
}

final class StoredGroupKey extends GroupKey {
  const new(this.id);

  final int id;

  @override
  String get value => 'g$id';
}
