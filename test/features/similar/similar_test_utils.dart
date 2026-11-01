import 'dart:io';
import 'dart:typed_data';

import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/tables/pending_deletes_table.dart';
import 'package:kfm/core/db/tables/session_actions_table.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/media_index_dao.dart';

final base = DateTime.utc(2026, 10, 1, 12);

/// Fixture JPEG bytes (`tool/gen_similar_fixtures.dart`).
Uint8List fixture(String name) =>
    File('test/fixtures/similar/$name.jpg').readAsBytesSync();

FileRef photo(
  String id, {
  int minute = 0,
  int size = 1000,
  int modifiedMs = 0,
  FileKind kind = FileKind.image,
  bool screenshot = false,
  bool hidden = false,
  int? width,
  int? height,
}) => FileRef(
  id: id,
  uri: 'content://$id',
  name: screenshot ? 'Screenshot_$id.png' : '$id.jpg',
  kind: kind,
  sizeBytes: size,
  modifiedAt: DateTime.fromMillisecondsSinceEpoch(modifiedMs, isUtc: true),
  takenAt: base.add(Duration(minutes: minute)),
  folderPath: '/storage/emulated/0/DCIM/Camera',
  origin: FileOrigin.local,
  width: width,
  height: height,
  hidden: hidden,
);

Future<void> index(AppDatabase db, List<FileRef> files) =>
    MediaIndexDao(db).upsertBatch(files, 1);

Future<int> session(AppDatabase db) => db
    .into(db.sessions)
    .insert(
      SessionsCompanion.insert(
        layout: '{}',
        startedAt: base,
        updatedAt: base,
        isActive: true,
      ),
    );

var _seq = 0;

/// A trash action + its pending_deletes row in [status].
Future<void> pendingDelete(
  AppDatabase db,
  int sessionId,
  String fileId, {
  PendingDeleteStatus status = PendingDeleteStatus.queued,
}) async {
  final actionId = await db
      .into(db.sessionActions)
      .insert(
        SessionActionsCompanion.insert(
          sessionId: sessionId,
          seq: ++_seq,
          fileId: fileId,
          actionType: 'trash',
          payload: '{}',
          previousState: '{}',
          status: ActionStatus.applied,
          createdAt: base,
        ),
      );
  await db
      .into(db.pendingDeletes)
      .insert(
        PendingDeletesCompanion.insert(
          actionId: actionId,
          sessionId: sessionId,
          fileId: fileId,
          mode: 'trash',
          status: status,
          sizeBytes: 1,
          fileModifiedAtMs: 0,
          queuedAt: base,
        ),
      );
}
