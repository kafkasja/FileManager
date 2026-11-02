import 'package:kfm/core/files/file_names.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:meta/meta.dart';

/// TASK-N12 send-files protocol (offers). An offer must be accepted
/// before any byte flows; the bytes then go through the N9/N10 upload
/// routes into the pseudo root `offer:<offerId>` (push) or the N7 file
/// routes (reverse, N12b).
const int kMaxOfferFiles = 500;

/// `POST /v1/offers` reads its body with this cap (own limit, like chunks).
const int kMaxOfferBodyBytes = 256 * 1024;

/// An undecided offer expires after this.
const Duration kOfferDecisionTimeout = Duration(minutes: 2);

/// An accepted grant without a chunk for this long ends (as N10 partials).
const Duration kOfferGrantIdle = Duration(days: 7);

/// A grant never lives longer than this after it was accepted, however
/// often activity extends it.
const Duration kOfferGrantMaxAge = Duration(days: 7);

/// X2's location strip may change a file's size: a claimed upload may be
/// this much bigger than offered.
const int kOfferSizeSlackBytes = 1024 * 1024;

/// Offer ids are client-made `randomHexId()`s.
final RegExp kOfferIdPattern = RegExp(r'^[0-9a-f]{32}$');

const String _kOfferRootPrefix = 'offer:';
const String _kInboxRootPrefix = 'inbox:';

/// The pseudo root id an accepted push offer is uploaded into.
String offerRootId(String offerId) => '$_kOfferRootPrefix$offerId';

bool isOfferRootId(String rootId) => rootId.startsWith(_kOfferRootPrefix);

/// The offer id of [rootId], or null when it isn't an offer root.
String? offerIdOfRoot(String? rootId) => rootId != null && isOfferRootId(rootId)
    ? rootId.substring(_kOfferRootPrefix.length)
    : null;

/// N12b: the `transfers.targetRootId` of a download job made from an
/// offer this device received (so the job end can report).
String inboxRootId(String offerId) => '$_kInboxRootPrefix$offerId';

String? offerIdOfInboxRoot(String? rootId) =>
    rootId != null && rootId.startsWith(_kInboxRootPrefix)
    ? rootId.substring(_kInboxRootPrefix.length)
    : null;

/// Whether [name] may be an offered file name: [validateFileName], no
/// leading dot (hidden, `.nomedia`).
bool isValidOfferName(String name) {
  if (name.startsWith('.')) return false;
  try {
    validateFileName(name);
    return true;
  } on FileOpException {
    return false;
  }
}

/// N12b: whether a client may prompt for [o] at all (the sharing device
/// is checked like any sender): 1 to [kMaxOfferFiles] files, every name
/// valid, sizes not negative, and a server id for each file.
bool isAcceptableInboxOffer(OfferDto o) {
  if (o.files.isEmpty || o.files.length > kMaxOfferFiles) return false;
  for (final f in o.files) {
    if (!isValidOfferName(f.name) || f.size < 0 || f.size > (1 << 50)) {
      return false;
    }
    if (f.id == null || f.id!.isEmpty || f.id!.length > 128) return false;
  }
  return true;
}

String _str(Map<String, Object?> json, String key) {
  final v = json[key];
  if (v is String) return v;
  throw FormatException('missing or non-string "$key"');
}

int _int(Map<String, Object?> json, String key) {
  final v = json[key];
  if (v is int) return v;
  throw FormatException('missing or non-int "$key"');
}

String? _strOrNull(Map<String, Object?> json, String key) {
  final v = json[key];
  return v is String ? v : null;
}

int? _intOrNull(Map<String, Object?> json, String key) {
  final v = json[key];
  return v is int ? v : null;
}

List<OfferFileDto> _files(Map<String, Object?> json, {required bool strict}) {
  final v = json['files'];
  if (v == null && !strict) return const [];
  if (v is! List<Object?>) {
    throw const FormatException('missing or non-list "files"');
  }
  return List.unmodifiable([
    for (final f in v)
      if (f is Map<String, Object?>)
        OfferFileDto.fromJson(f)
      else
        throw const FormatException('non-object file'),
  ]);
}

/// One offered file. Names are checked by the receiver (`invalid_name`),
/// not here, so the error is precise.
@immutable
class OfferFileDto {
  const new({
    required this.name,
    required this.size,
    this.mime,
    this.id,
    this.modifiedAtMs,
  });

  factory fromJson(Map<String, Object?> json) {
    final size = _int(json, 'size');
    if (size < 0) throw const FormatException('negative size');
    return OfferFileDto(
      name: _str(json, 'name'),
      size: size,
      mime: _strOrNull(json, 'mime'),
      id: _strOrNull(json, 'id'),
      modifiedAtMs: _intOrNull(json, 'modifiedAtMs'),
    );
  }

  final String name;
  final int size;
  final String? mime;

  /// Reverse only: the server's file id (the download source).
  final String? id;

  /// Reverse only.
  final int? modifiedAtMs;

  Map<String, Object?> toJson() => {
    'name': name,
    'size': size,
    'mime': ?mime,
    'id': ?id,
    'modifiedAtMs': ?modifiedAtMs,
  };
}

/// `POST /v1/offers`.
@immutable
class CreateOfferDto {
  const new({required this.offerId, required this.files});

  /// Throws [FormatException] on a bad id, a bad file or a wrong count.
  factory fromJson(Map<String, Object?> json) {
    final id = _str(json, 'offerId');
    if (!kOfferIdPattern.hasMatch(id)) {
      throw const FormatException('bad offerId');
    }
    final files = _files(json, strict: true);
    if (files.isEmpty || files.length > kMaxOfferFiles) {
      throw const FormatException('file count');
    }
    return CreateOfferDto(offerId: id, files: files);
  }

  /// Client-made 128-bit hex; idempotent per owner.
  final String offerId;
  final List<OfferFileDto> files;

  Map<String, Object?> toJson() => {
    'offerId': offerId,
    'files': [for (final f in files) f.toJson()],
  };
}

enum OfferWireStatus {
  pending,
  accepted,
  declined,
  expired,
  cancelled,
  done;

  static OfferWireStatus fromWire(String v) {
    for (final s in values) {
      if (s.name == v) return s;
    }
    throw FormatException('unknown offer status "$v"');
  }
}

enum OfferDeclineReason {
  user,
  noSpace,
  busy;

  /// Null for an unknown reason (a newer peer).
  static OfferDeclineReason? fromWire(String? v) {
    for (final r in values) {
      if (r.name == v) return r;
    }
    return null;
  }
}

/// An offer's state on the wire.
@immutable
class OfferDto {
  const new({
    required this.id,
    required this.status,
    this.reason,
    this.expiresInSeconds,
    this.rootId,
    this.senderName,
    this.files = const [],
  });

  factory fromJson(Map<String, Object?> json) => OfferDto(
    id: _str(json, 'id'),
    status: OfferWireStatus.fromWire(_str(json, 'status')),
    reason: OfferDeclineReason.fromWire(_strOrNull(json, 'reason')),
    expiresInSeconds: _intOrNull(json, 'expiresInSeconds'),
    rootId: _strOrNull(json, 'rootId'),
    senderName: _strOrNull(json, 'senderName'),
    files: _files(json, strict: false),
  );

  final String id;
  final OfferWireStatus status;
  final OfferDeclineReason? reason;

  /// Pending only.
  final int? expiresInSeconds;

  /// Push + accepted: `offer:<id>`.
  final String? rootId;

  /// Reverse (N12b).
  final String? senderName;

  /// Reverse (N12b).
  final List<OfferFileDto> files;

  Map<String, Object?> toJson() => {
    'id': id,
    'status': status.name,
    'reason': ?reason?.name,
    'expiresInSeconds': ?expiresInSeconds,
    'rootId': ?rootId,
    'senderName': ?senderName,
    if (files.isNotEmpty) 'files': [for (final f in files) f.toJson()],
  };
}

/// N12b `GET /v1/inbox`.
@immutable
class InboxDto {
  const new(this.offers);

  factory fromJson(Map<String, Object?> json) {
    final v = json['offers'];
    if (v is! List<Object?>) {
      throw const FormatException('missing or non-list "offers"');
    }
    return InboxDto([
      for (final o in v)
        if (o is Map<String, Object?>)
          OfferDto.fromJson(o)
        else
          throw const FormatException('non-object offer'),
    ]);
  }

  final List<OfferDto> offers;

  Map<String, Object?> toJson() => {
    'offers': [for (final o in offers) o.toJson()],
  };
}

/// N12b `POST /v1/inbox/<id>/finished`.
@immutable
class InboxFinishedDto {
  const new({this.done = const [], this.failed = const []});

  factory fromJson(Map<String, Object?> json) {
    List<int> ints(String key) {
      final v = json[key];
      if (v == null) return const [];
      if (v is! List<Object?>) throw FormatException('non-list "$key"');
      return [
        for (final i in v)
          if (i is int) i else throw FormatException('non-int in "$key"'),
      ];
    }

    return InboxFinishedDto(done: ints('done'), failed: ints('failed'));
  }

  final List<int> done;
  final List<int> failed;

  Map<String, Object?> toJson() => {'done': done, 'failed': failed};
}
