import 'package:drift/drift.dart';
import 'package:kfm/core/db/tables/sessions_table.dart';

/// applied: done (and undoable); undone: history only; committed: a delete
/// that D2 physically carried out.
enum ActionStatus { applied, undone, committed }

/// The undo log (TASK-S2): one row per swipe, including keeps.
@DataClassName('SessionActionRow')
@TableIndex(name: 'sa_session_status_seq', columns: {#sessionId, #status, #seq})
class SessionActions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId =>
      integer().references(Sessions, #id, onDelete: KeyAction.cascade)();

  /// 1..n per session, assigned in memory, never reused.
  IntColumn get seq => integer()();

  /// FileRef.id at the time of the action.
  TextColumn get fileId => text()();

  /// SwipeActionType.name.
  TextColumn get actionType => text()();

  /// SwipeAction JSON.
  TextColumn get payload => text()();

  /// PreviousState JSON (what undo needs).
  TextColumn get previousState => text()();
  TextColumn get status => textEnum<ActionStatus>()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {sessionId, seq},
  ];
}
