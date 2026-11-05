import 'package:drift/drift.dart';

/// Remembered devices (TASK-N6). A peer IS its key: [publicKeyFingerprint]
/// (`sha256(cert DER)`) comes only from a verified pairing and is never
/// updated; a new key for the same `peerDeviceId` gets its own row.
@DataClassName('KnownDeviceRow')
class KnownDevices extends Table {
  /// Local random 128-bit hex (`randomHexId`), never the peer's id.
  TextColumn get id => text()();

  /// The peer's self-asserted deviceId; informational only.
  TextColumn get peerDeviceId => text()();
  TextColumn get name => text()();

  /// android | windows | ios; '' when unknown.
  TextColumn get platform => text()();

  /// Identity: 64 lowercase hex.
  TextColumn get publicKeyFingerprint => text().unique()();

  /// Epoch ms.
  IntColumn get lastSeenAtMs => integer()();

  /// JSON `["ip:port", ...]` (max 3, newest first): where the peer was our
  /// server.
  TextColumn get lastAddresses => text().withDefault(const Constant('[]'))();

  /// JSON `[{path, label, readOnly}]`: what THIS device shares with that
  /// peer. Local only; root ids are recomputed on load.
  TextColumn get allowedRootsJson => text().withDefault(const Constant('[]'))();

  /// The peer has been our server at least once.
  BoolColumn get canShareToUs => boolean().withDefault(const Constant(false))();

  /// Kept only for resuming transfers (N9/N10); hidden from the list.
  BoolColumn get isTemporary => boolean().withDefault(const Constant(false))();

  /// "Always allow": a verified `/v1/pair/known` from this peer is accepted
  /// without the accept prompt (sharing side only).
  BoolColumn get autoAccept => boolean().withDefault(const Constant(false))();

  /// "Accept files without asking" (TASK-N12): a verified, non-temporary
  /// peer's send-files offers are accepted without the offer prompt.
  BoolColumn get autoAcceptFiles =>
      boolean().withDefault(const Constant(false))();

  /// E1: "Let this peer see my files" (false → empty scope; sending still
  /// works).
  BoolColumn get letSee => boolean().withDefault(const Constant(true))();

  /// E1: "Let this peer take files without asking" (false → the take
  /// prompt asks first).
  BoolColumn get letTakeFreely => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (length(public_key_fingerprint) = 64)',
  ];
}
