import 'package:drift/drift.dart';
import 'package:kfm/core/db/tables/sessions_table.dart';

/// filter: FileFilter JSON, re-evaluated per deck build.
/// files: swipe_source_items in order. groups: items with a groupIndex.
/// outside: actions recorded outside the deck (runOutsideDeck); no items,
/// inserted already closed. Stored by name: APPEND ONLY.
enum SwipeSourceKind { filter, files, groups, outside }

/// Who opened the source: icon and "Back to …" label only.
enum SwipeSourceOrigin {
  storage, // C1
  similar, // C2
  contentSearch, // C4
  smartGroup, // C5
  sameTime, // B3
  search, // B8
  browse, // B1 view / Sources row, B6 selection
  sharedIn, // X1
  cloud, // X4
  externalPlace, // U2 "Swipe this folder" on USB/SD
  other,
}

/// A swipe source opened inside a session (TASK-SS1). At most one open
/// (closedAt IS NULL) per session. Closed rows of non-ended sessions are kept
/// for the main deck's resume floor (closedAtSeq).
@DataClassName('SwipeSourceRow')
@TableIndex.sql(
  'CREATE UNIQUE INDEX one_open_source_per_session ON swipe_sources '
  '(session_id) WHERE closed_at IS NULL',
)
@TableIndex(name: 'ss_session_closed_seq', columns: {#sessionId, #closedAtSeq})
class SwipeSources extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId =>
      integer().references(Sessions, #id, onDelete: KeyAction.cascade)();
  TextColumn get kind => textEnum<SwipeSourceKind>()();
  TextColumn get origin => textEnum<SwipeSourceOrigin>()();

  /// Shown in the source bar as given (caller localizes it or passes user
  /// data such as a group title or the search text). 1–80 chars.
  TextColumn get title => text().withLength(min: 1, max: 80)();

  /// P5 FileFilter JSON; set only for kind = filter.
  TextColumn get filterJson => text().nullable()();

  /// Files stored in swipe_source_items (0 for filter sources).
  IntColumn get itemCount => integer().withDefault(const Constant(0))();

  /// Number of groups (kind = groups only).
  IntColumn get groupCount => integer().nullable()();

  /// go_router location for "Back to …" when the source is finished.
  TextColumn get returnRoute => text().nullable()();

  /// Highest session_actions.seq when opened (0 = none yet).
  IntColumn get openedAfterSeq => integer()();

  /// Highest seq when closed; null while open.
  IntColumn get closedAtSeq => integer().nullable()();
  DateTimeColumn get openedAt => dateTime()();
  DateTimeColumn get closedAt => dateTime().nullable()();

  @override
  List<String> get customConstraints => [
    "CHECK ((kind = 'filter') = (filter_json IS NOT NULL))",
    "CHECK ((kind = 'groups') = (group_count IS NOT NULL))",
    'CHECK ((closed_at IS NULL) = (closed_at_seq IS NULL))',
    "CHECK (kind <> 'outside' OR closed_at IS NOT NULL)",
  ];
}
