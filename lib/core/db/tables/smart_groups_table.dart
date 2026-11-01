import 'package:drift/drift.dart';

enum SmartGroupKind { trip, place }

/// Computed Trips/Places (TASK-C5). Ids survive recomputes when the members
/// overlap ≥ 80% (`matchGroups`), so open screens and renamed titles stay
/// valid.
@DataClassName('SmartGroupRow')
@TableIndex(name: 'sg_kind_rank', columns: {#kind, #rank})
class SmartGroups extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get kind => textEnum<SmartGroupKind>()();

  /// Places: 1 = largest shown place ("Place 1"). Trips: 0.
  IntColumn get rank => integer()();

  /// Min sortDateMs of the members.
  IntColumn get startAtMs => integer()();

  /// Max sortDateMs of the members.
  IntColumn get endAtMs => integer()();
  RealColumn get centerLat => real().nullable()();
  RealColumn get centerLng => real().nullable()();

  /// Newest member.
  TextColumn get coverFileId => text()();
  IntColumn get itemCount => integer()();

  /// Set by the user (rename); wins over everything. 1–80 chars.
  TextColumn get userTitle => text().withLength(min: 1, max: 80).nullable()();

  /// Online lookup result (setting on); null = none.
  TextColumn get placeName => text().withLength(min: 1, max: 120).nullable()();

  /// Last lookup attempt (success or failure), so failures aren't retried
  /// on every run. Cleared when the setting is turned on again.
  IntColumn get geocodedAtMs => integer().nullable()();

  @override
  List<String> get customConstraints => [
    'CHECK ((center_lat IS NULL) = (center_lng IS NULL))',
    'CHECK (end_at_ms >= start_at_ms)',
  ];
}

/// Members of a smart group. (Index named `smgi_file`: C2 already owns
/// `sgi_file`.)
@DataClassName('SmartGroupItemRow')
@TableIndex(name: 'smgi_file', columns: {#fileId})
class SmartGroupItems extends Table {
  IntColumn get groupId =>
      integer().references(SmartGroups, #id, onDelete: KeyAction.cascade)();
  TextColumn get fileId => text()();

  @override
  Set<Column<Object>> get primaryKey => {groupId, fileId};
}
