import 'package:drift/drift.dart';

/// Who made the offer this device's share server holds (TASK-N12):
/// `incoming` = a client pushes files to us; `outgoing` = we offer files to
/// a connected client (N12b).
enum OfferDirection { incoming, outgoing }

/// The lifecycle of one offer.
enum OfferStatus {
  pending,
  accepted,
  declined,
  expired,
  cancelled,
  done,
  failed,
}

/// One offered file.
enum OfferFileStatus { waiting, transferring, done, failed, cancelled }

/// Send-files offers held by this device's SERVER (TASK-N12). No foreign
/// key to `known_devices`: the peer may not be remembered.
@DataClassName('ShareOfferRow')
@TableIndex(name: 'share_offers_status', columns: {#status, #direction})
class ShareOffers extends Table {
  /// 32 hex. Incoming: the sender's offerId (owner-bound: another fp → 404).
  TextColumn get id => text()();
  TextColumn get direction => textEnum<OfferDirection>()();

  /// The verified peer key.
  TextColumn get peerFingerprint => text()();
  TextColumn get peerName => text()();
  TextColumn get status => textEnum<OfferStatus>()();

  /// `OfferDeclineReason` wire name.
  TextColumn get declineReason => text().nullable()();

  /// Incoming + accepted: the absolute local folder files land in.
  TextColumn get folder => text().nullable()();
  IntColumn get fileCount => integer()();
  IntColumn get totalBytes => integer()();
  BoolColumn get autoAccepted => boolean().withDefault(const Constant(false))();
  IntColumn get createdAtMs => integer()();

  /// Pending: the decision deadline. Accepted: the grant end (last
  /// activity + 7 days).
  IntColumn get expiresAtMs => integer()();
  IntColumn get decidedAtMs => integer().nullable()();
  IntColumn get updatedAtMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (length(peer_fingerprint) = 64)',
  ];
}

/// One file of a [ShareOffers] row.
@DataClassName('ShareOfferFileRow')
@TableIndex(name: 'share_offer_files_upload', columns: {#uploadId})
class ShareOfferFiles extends Table {
  TextColumn get offerId =>
      text().references(ShareOffers, #id, onDelete: KeyAction.cascade)();
  IntColumn get seq => integer()();
  TextColumn get name => text()();
  IntColumn get sizeBytes => integer()();
  TextColumn get mimeType => text().nullable()();

  /// Outgoing: the offered local file id. Incoming: the imported file's id.
  TextColumn get localFileId => text().nullable()();

  /// Outgoing: the canonical path read clients may fetch (original or
  /// staged copy) and its mtime at offer time.
  TextColumn get canonicalPath => text().nullable()();
  IntColumn get sourceModifiedAtMs => integer().nullable()();

  /// Incoming: the claimed N9 upload.
  TextColumn get uploadId => text().nullable()();
  TextColumn get status => textEnum<OfferFileStatus>()();
  TextColumn get error => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {offerId, seq};
}
