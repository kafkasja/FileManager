import 'package:drift/drift.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_write_queue.dart';
import 'package:kfm/core/db/tables/share_offers_table.dart';
import 'package:kfm/features/connect/domain/share_offer.dart';

part 'share_offers_dao.g.dart';

/// Finished offers older than this are removed at startup.
const Duration kFinishedOfferRetention = Duration(days: 30);

/// Raw access to `share_offers` + `share_offer_files` (TASK-N12). Use
/// [OfferRepository] from the UI isolate (writes go through the queue).
@DriftAccessor(tables: [ShareOffers, ShareOfferFiles])
class ShareOffersDao extends DatabaseAccessor<AppDatabase>
    with _$ShareOffersDaoMixin {
  new(super.attachedDatabase);

  static const List<OfferStatus> _open = [
    OfferStatus.pending,
    OfferStatus.accepted,
  ];

  Future<List<ShareOffer>> _withFiles(List<ShareOfferRow> rows) async {
    if (rows.isEmpty) return const [];
    final files =
        await (select(shareOfferFiles)
              ..where((f) => f.offerId.isIn([for (final r in rows) r.id]))
              ..orderBy([(f) => OrderingTerm.asc(f.seq)]))
            .get();
    final byOffer = <String, List<ShareOfferFile>>{};
    for (final f in files) {
      (byOffer[f.offerId] ??= []).add(_file(f));
    }
    return [for (final r in rows) _offer(r, byOffer[r.id] ?? const [])];
  }

  /// Pending and accepted offers (the service's cache at start).
  Future<List<ShareOffer>> open() async => await _withFiles(
    await (select(shareOffers)..where((o) => o.status.isInValues(_open))).get(),
  );

  Future<ShareOffer?> byId(String id) async {
    final rows = await (select(
      shareOffers,
    )..where((o) => o.id.equals(id))).get();
    final out = await _withFiles(rows);
    return out.firstOrNull;
  }

  /// Every offer, newest first (Transfers page sections).
  Stream<List<ShareOffer>> watchAll() =>
      (select(shareOffers)..orderBy([
            (o) => OrderingTerm.desc(o.createdAtMs),
            (o) => OrderingTerm.asc(o.id),
          ]))
          .watch()
          .asyncMap(_withFiles);

  Future<void> insertOffer(ShareOffer o) => transaction(() async {
    await into(shareOffers).insert(_row(o));
    for (final f in o.files) {
      await into(shareOfferFiles).insert(_fileRow(o.id, f));
    }
  });

  Future<void> updateOffer(ShareOffer o) =>
      (update(shareOffers)..where((r) => r.id.equals(o.id))).write(
        ShareOffersCompanion(
          status: Value(o.status),
          declineReason: Value(o.declineReason),
          folder: Value(o.folder),
          autoAccepted: Value(o.autoAccepted),
          expiresAtMs: Value(o.expiresAt.millisecondsSinceEpoch),
          decidedAtMs: Value(o.decidedAt?.millisecondsSinceEpoch),
          updatedAtMs: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );

  Future<void> updateFile(String offerId, ShareOfferFile f) =>
      (update(
        shareOfferFiles,
      )..where((r) => r.offerId.equals(offerId) & r.seq.equals(f.seq))).write(
        ShareOfferFilesCompanion(
          localFileId: Value(f.localFileId),
          uploadId: Value(f.uploadId),
          status: Value(f.status),
          error: Value(f.error),
        ),
      );

  /// Removes finished offers (Transfers "Clear finished").
  Future<int> clearFinished() =>
      (delete(shareOffers)..where((o) => o.status.isNotInValues(_open))).go();

  /// Startup: finished offers not touched since [cutoffMs].
  Future<int> purgeFinishedBefore(int cutoffMs) =>
      (delete(shareOffers)..where(
            (o) =>
                o.status.isNotInValues(_open) &
                o.updatedAtMs.isSmallerThanValue(cutoffMs),
          ))
          .go();

  static ShareOffer _offer(ShareOfferRow r, List<ShareOfferFile> files) =>
      ShareOffer(
        id: r.id,
        direction: r.direction,
        peerFingerprint: r.peerFingerprint,
        peerName: r.peerName,
        status: r.status,
        files: List.unmodifiable(files),
        createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAtMs),
        expiresAt: DateTime.fromMillisecondsSinceEpoch(r.expiresAtMs),
        declineReason: r.declineReason,
        folder: r.folder,
        autoAccepted: r.autoAccepted,
        decidedAt: r.decidedAtMs == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(r.decidedAtMs!),
      );

  static ShareOfferFile _file(ShareOfferFileRow f) => ShareOfferFile(
    seq: f.seq,
    name: f.name,
    sizeBytes: f.sizeBytes,
    mimeType: f.mimeType,
    localFileId: f.localFileId,
    canonicalPath: f.canonicalPath,
    sourceModifiedAtMs: f.sourceModifiedAtMs,
    uploadId: f.uploadId,
    status: f.status,
    error: f.error,
  );

  static ShareOffersCompanion _row(ShareOffer o) => ShareOffersCompanion.insert(
    id: o.id,
    direction: o.direction,
    peerFingerprint: o.peerFingerprint,
    peerName: o.peerName,
    status: o.status,
    declineReason: Value(o.declineReason),
    folder: Value(o.folder),
    fileCount: o.fileCount,
    totalBytes: o.totalBytes,
    autoAccepted: Value(o.autoAccepted),
    createdAtMs: o.createdAt.millisecondsSinceEpoch,
    expiresAtMs: o.expiresAt.millisecondsSinceEpoch,
    decidedAtMs: Value(o.decidedAt?.millisecondsSinceEpoch),
    updatedAtMs: o.createdAt.millisecondsSinceEpoch,
  );

  static ShareOfferFilesCompanion _fileRow(String offerId, ShareOfferFile f) =>
      ShareOfferFilesCompanion.insert(
        offerId: offerId,
        seq: f.seq,
        name: f.name,
        sizeBytes: f.sizeBytes,
        mimeType: Value(f.mimeType),
        localFileId: Value(f.localFileId),
        canonicalPath: Value(f.canonicalPath),
        sourceModifiedAtMs: Value(f.sourceModifiedAtMs),
        uploadId: Value(f.uploadId),
        status: f.status,
        error: Value(f.error),
      );
}

/// Offers for the UI isolate (TASK-N12): reads go to the DAO, every write
/// through [DbWriteQueue] (status rows are never coalesced).
class OfferRepository {
  new(this.dao, this._queue);

  final ShareOffersDao dao;
  final DbWriteQueue _queue;

  Stream<List<ShareOffer>> watchAll() => dao.watchAll();

  Future<void> insert(ShareOffer o) =>
      _queue.enqueue(null, () => dao.insertOffer(o));

  Future<void> save(ShareOffer o) =>
      _queue.enqueue(null, () => dao.updateOffer(o));

  Future<void> saveFile(String offerId, ShareOfferFile f) =>
      _queue.enqueue(null, () => dao.updateFile(offerId, f));

  Future<int> clearFinished() async {
    late int n;
    await _queue.enqueue(null, () async => n = await dao.clearFinished());
    return n;
  }

  Future<int> purgeOld({DateTime? now}) async {
    final cutoff = (now ?? DateTime.now())
        .subtract(kFinishedOfferRetention)
        .millisecondsSinceEpoch;
    late int n;
    await _queue.enqueue(
      null,
      () async => n = await dao.purgeFinishedBefore(cutoff),
    );
    return n;
  }
}
