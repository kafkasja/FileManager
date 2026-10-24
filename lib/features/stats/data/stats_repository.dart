import 'package:drift/drift.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'stats_repository.g.dart';

@immutable
class StatsTotals {
  const new({required this.reviewed, required this.freedBytes});

  static const zero = StatsTotals(reviewed: 0, freedBytes: 0);

  final int reviewed;
  final int freedBytes;
}

/// One session's numbers (summary sheet after Done).
@immutable
class SessionStats {
  const new({
    required this.reviewed,
    required this.toTrashBytes,
    required this.freedBytes,
  });

  final int reviewed;
  final int toTrashBytes;
  final int freedBytes;
}

/// Swipe stats (TASK-P8), all derived from the undo log and the delete
/// queue: nothing to keep in step when undoing or restoring.
///
/// - reviewed = non-undone actions
/// - in trash = committed to the trash, still there, not undone (live)
/// - freed = committed permanently, or left the trash without a restore
class StatsRepository {
  new(this._db);

  final AppDatabase _db;

  static int _s(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;

  Future<int> inTrashBytes() async {
    final row = await _db
        .customSelect(
          'SELECT COALESCE(SUM(pd.size_bytes), 0) AS b FROM pending_deletes pd '
          'JOIN session_actions sa ON sa.id = pd.action_id '
          "WHERE pd.status = 'committed' AND pd.committed_mode = 'trash' "
          'AND pd.trash_id IS NOT NULL AND pd.left_trash_at IS NULL '
          "AND sa.status != 'undone'",
          readsFrom: {_db.pendingDeletes, _db.sessionActions},
        )
        .getSingle();
    return row.read<int>('b');
  }

  /// Since [from] (inclusive) and before [to].
  Future<StatsTotals> totals({DateTime? from, DateTime? to}) async {
    final m = await byPreset(from: from, to: to);
    return StatsTotals(
      reviewed: m.values.fold(0, (a, t) => a + t.reviewed),
      freedBytes: m.values.fold(0, (a, t) => a + t.freedBytes),
    );
  }

  /// Key = preset id, 0 = Basic.
  Future<Map<int, StatsTotals>> byPreset({DateTime? from, DateTime? to}) async {
    final lo = from == null ? -1 : _s(from);
    final hi = to == null ? 1 << 62 : _s(to);
    final reviewed = await _db
        .customSelect(
          'SELECT COALESCE(s.preset_id, 0) AS k, COUNT(*) AS n '
          'FROM session_actions sa JOIN sessions s ON s.id = sa.session_id '
          "WHERE sa.status != 'undone' AND sa.created_at >= ? "
          'AND sa.created_at < ? GROUP BY k',
          variables: [Variable.withInt(lo), Variable.withInt(hi)],
          readsFrom: {_db.sessionActions, _db.sessions},
        )
        .get();
    final freed = await _db
        .customSelect(
          'SELECT k, SUM(b) AS b FROM ( '
          'SELECT COALESCE(s.preset_id, 0) AS k, pd.size_bytes AS b '
          'FROM pending_deletes pd JOIN sessions s ON s.id = pd.session_id '
          "WHERE pd.status = 'committed' AND pd.committed_mode = 'permanent' "
          'AND pd.committed_at >= ? AND pd.committed_at < ? '
          'UNION ALL '
          'SELECT COALESCE(s.preset_id, 0), pd.size_bytes '
          'FROM pending_deletes pd JOIN sessions s ON s.id = pd.session_id '
          "WHERE pd.left_trash_reason = 'purged' "
          'AND pd.left_trash_at >= ? AND pd.left_trash_at < ? '
          ') GROUP BY k',
          variables: [
            Variable.withInt(lo),
            Variable.withInt(hi),
            Variable.withInt(lo),
            Variable.withInt(hi),
          ],
          readsFrom: {_db.pendingDeletes, _db.sessions},
        )
        .get();
    final keys = {
      for (final r in reviewed) r.read<int>('k'),
      for (final r in freed) r.read<int>('k'),
    };
    final n = {for (final r in reviewed) r.read<int>('k'): r.read<int>('n')};
    final b = {for (final r in freed) r.read<int>('k'): r.read<int>('b')};
    return {
      for (final k in keys)
        k: StatsTotals(reviewed: n[k] ?? 0, freedBytes: b[k] ?? 0),
    };
  }

  /// The last [weeks] weeks, oldest first; [weekStart] is the current one.
  Future<List<({DateTime weekStart, StatsTotals totals})>> weekly({
    required DateTime weekStart,
    int weeks = 8,
    DateTime? notBefore,
  }) async => [
    for (var i = weeks - 1; i >= 0; i--)
      (
        weekStart: DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day - 7 * i,
        ),
        totals: await totals(
          from: _max(
            DateTime(weekStart.year, weekStart.month, weekStart.day - 7 * i),
            notBefore,
          ),
          to: DateTime(
            weekStart.year,
            weekStart.month,
            weekStart.day - 7 * i + 7,
          ),
        ),
      ),
  ];

  Future<SessionStats> forSession(int sessionId) async {
    final row = await _db
        .customSelect(
          'SELECT '
          '(SELECT COUNT(*) FROM session_actions WHERE session_id = ?1 '
          "AND status != 'undone') AS n, "
          '(SELECT COALESCE(SUM(pd.size_bytes), 0) FROM pending_deletes pd '
          'JOIN session_actions sa ON sa.id = pd.action_id '
          "WHERE pd.session_id = ?1 AND pd.status = 'committed' "
          "AND pd.committed_mode = 'trash' AND pd.trash_id IS NOT NULL "
          "AND sa.status != 'undone') AS t, "
          '(SELECT COALESCE(SUM(size_bytes), 0) FROM pending_deletes '
          "WHERE session_id = ?1 AND status = 'committed' "
          "AND committed_mode = 'permanent') AS f",
          variables: [Variable.withInt(sessionId)],
          readsFrom: {_db.sessionActions, _db.pendingDeletes},
        )
        .getSingle();
    return SessionStats(
      reviewed: row.read<int>('n'),
      toTrashBytes: row.read<int>('t'),
      freedBytes: row.read<int>('f'),
    );
  }

  static DateTime _max(DateTime a, DateTime? b) =>
      b != null && b.isAfter(a) ? b : a;
}

@Riverpod(keepAlive: true)
StatsRepository statsRepository(Ref ref) =>
    StatsRepository(ref.watch(appDatabaseProvider));
