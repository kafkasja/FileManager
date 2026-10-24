import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/utils/debouncer.dart';
import 'package:kfm/features/session/domain/session.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';

/// The active swipe session and its quiet, lag-free saving (TASK-SE1).
///
/// - Progress (cursor) is debounced 300 ms and coalesced in the write queue.
/// - Layout/filter are written when they change.
/// - Undo rows (S2) and pending deletes (D2) are written immediately by their
///   own repositories through the same queue.
class SessionRepository {
  new(this._db, this._queue, {this._clock = DateTime.now});

  static const cursorDebounce = Duration(milliseconds: 300);

  final AppDatabase _db;
  final DbWriteQueue _queue;
  final DateTime Function() _clock;
  final Debouncer _cursorDebouncer = Debouncer(cursorDebounce);

  Future<Session?> active() async {
    final row = await (_db.select(
      _db.sessions,
    )..where((s) => s.isActive.equals(true))).getSingleOrNull();
    return row == null ? null : _toSession(row);
  }

  Stream<Session?> watchActive() =>
      (_db.select(_db.sessions)..where((s) => s.isActive.equals(true)))
          .watchSingleOrNull()
          .map((row) => row == null ? null : _toSession(row));

  /// The active session, or a new one using the saved layout and the
  /// [deleteMode] (default: the current setting).
  Future<Session> getOrCreateActive({DeleteMode? deleteMode}) async {
    await _queue.flush();
    return await _db.transaction(() async {
      final existing = await active();
      if (existing != null) return existing;
      final layoutJson = await _setting(AppSettings.swipeLayoutCurrent.name);
      final mode =
          deleteMode ??
          DeleteMode.parse(
            AppSettings.deleteMode.decodeFromDb(
              await _setting(AppSettings.deleteMode.name) ?? '"trash"',
            ),
          );
      final now = _clock();
      final id = await _db
          .into(_db.sessions)
          .insert(
            SessionsCompanion.insert(
              layout: _layoutOrBasic(layoutJson),
              deleteMode: Value(mode.name),
              startedAt: now,
              updatedAt: now,
              isActive: true,
            ),
          );
      return (await _byId(id))!;
    });
  }

  /// Debounced: ten swipes in a second become one UPDATE.
  void saveCursor(int sessionId, int cursor, String? fileId) {
    _cursorDebouncer.run(
      () => _queue
          .enqueue(
            'session.cursor:$sessionId',
            () =>
                (_db.update(
                  _db.sessions,
                )..where((s) => s.id.equals(sessionId))).write(
                  SessionsCompanion(
                    cursor: Value(cursor),
                    cursorFileId: Value(fileId),
                    updatedAt: Value(_clock()),
                  ),
                ),
          )
          .fireAndForget(),
    );
  }

  /// Saves the layout on the session and as the app-wide current layout.
  Future<void> saveLayout(int sessionId, SwipeLayout layout) {
    final json = jsonEncode(layout.toJson());
    return _queue.enqueue(
      'session.layout:$sessionId',
      () => _db.transaction(() async {
        await (_db.update(
          _db.sessions,
        )..where((s) => s.id.equals(sessionId))).write(
          SessionsCompanion(layout: Value(json), updatedAt: Value(_clock())),
        );
        await _db
            .into(_db.settings)
            .insertOnConflictUpdate(
              SettingRow(
                key: AppSettings.swipeLayoutCurrent.name,
                value: AppSettings.swipeLayoutCurrent.encodeToDb(json),
              ),
            );
      }),
    );
  }

  Future<void> saveFilter(int sessionId, String? filterJson) => _queue.enqueue(
    'session.filter:$sessionId',
    () =>
        (_db.update(_db.sessions)..where((s) => s.id.equals(sessionId))).write(
          SessionsCompanion(
            filter: Value(filterJson),
            updatedAt: Value(_clock()),
          ),
        ),
  );

  /// Ends the active session (Done / SE3). Its history stays for stats.
  Future<void> endActive() async {
    await flush();
    await _queue.enqueue(
      null,
      () => (_db.update(_db.sessions)..where((s) => s.isActive.equals(true)))
          .write(
            SessionsCompanion(
              isActive: const Value(false),
              updatedAt: Value(_clock()),
            ),
          ),
    );
  }

  /// App pause/hide/detach and before SE3 clears: everything lands on disk.
  Future<void> flush() async {
    _cursorDebouncer.flushNow();
    await _queue.flush();
  }

  Future<String?> _setting(String key) async => (await (_db.select(
    _db.settings,
  )..where((s) => s.key.equals(key))).getSingleOrNull())?.value;

  Future<Session?> _byId(int id) async {
    final row = await (_db.select(
      _db.sessions,
    )..where((s) => s.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toSession(row);
  }

  /// Settings value is JSON-encoded layout JSON; '' or bad → basic.
  static String _layoutOrBasic(String? settingValue) {
    final layout = settingValue == null
        ? ''
        : AppSettings.swipeLayoutCurrent.decodeFromDb(settingValue);
    return layout.isEmpty ? jsonEncode(SwipeLayout.basic.toJson()) : layout;
  }

  static Session _toSession(SessionRow r) => Session(
    id: r.id,
    layout: _parseLayout(r.layout),
    deleteMode: DeleteMode.parse(r.deleteMode),
    filterJson: r.filter,
    cursor: r.cursor,
    cursorFileId: r.cursorFileId,
    presetId: r.presetId,
    startedAt: r.startedAt,
    updatedAt: r.updatedAt,
  );

  /// Corrupt layout → basic (logged); the user's files are unaffected.
  static SwipeLayout _parseLayout(String json) => SwipeLayout.decode(json);
}
