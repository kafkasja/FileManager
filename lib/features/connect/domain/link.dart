import 'package:meta/meta.dart';

/// What this device lets a linked peer do with ITS OWN files (TASK-E1).
/// Each side keeps and enforces its own choice; what the peer claims about
/// its perms is shown only.
@immutable
final class LinkPerms {
  const new({this.see = true, this.takeFreely = true});

  /// Lenient: anything but `false` is the default `true`.
  factory fromJson(Object? json) {
    if (json is! Map<String, Object?>) return const LinkPerms();
    return LinkPerms(
      see: json['see'] != false,
      takeFreely: json['takeFreely'] != false,
    );
  }

  /// False → the peer gets no roots (it can still send files here).
  final bool see;

  /// False → the take prompt asks before the peer copies a file's bytes.
  final bool takeFreely;

  Map<String, Object?> toJson() => {'see': see, 'takeFreely': takeFreely};

  LinkPerms copyWith({bool? see, bool? takeFreely}) => LinkPerms(
    see: see ?? this.see,
    takeFreely: takeFreely ?? this.takeFreely,
  );

  @override
  bool operator ==(Object other) =>
      other is LinkPerms && other.see == see && other.takeFreely == takeFreely;

  @override
  int get hashCode => Object.hash(see, takeFreely);

  @override
  String toString() => 'LinkPerms(see: $see, takeFreely: $takeFreely)';
}

/// The one linked device as the UI sees it (TASK-E1): this device's
/// connection to the peer's server and/or the peer's session on this
/// device's server.
@immutable
final class DeviceLink {
  const new({
    required this.peerFingerprint,
    required this.peerName,
    this.iSeeTheirs = false,
    this.connectedToThem = false,
    this.theyAreConnected = false,
    this.mine = const LinkPerms(),
    this.reverseReachable = true,
  });

  final String peerFingerprint;
  final String peerName;

  /// This device's client to the peer has roots to browse.
  final bool iSeeTheirs;

  /// This device holds a (non send-only) connection to the peer's server:
  /// sends go as N12 offers through it.
  final bool connectedToThem;

  /// The peer has a session on this device's server (it can browse and
  /// send here); sends from here go as N12b inbox offers.
  final bool theyAreConnected;

  /// What this device lets the peer do (its own choice).
  final LinkPerms mine;

  /// False when the reverse half couldn't be set up (NAT, firewall, an
  /// older peer): the link works one way.
  final bool reverseReachable;

  bool get theySeeMine => theyAreConnected && mine.see;
  bool get theyTakeFreely => mine.takeFreely;

  @override
  bool operator ==(Object other) =>
      other is DeviceLink &&
      other.peerFingerprint == peerFingerprint &&
      other.peerName == peerName &&
      other.iSeeTheirs == iSeeTheirs &&
      other.connectedToThem == connectedToThem &&
      other.theyAreConnected == theyAreConnected &&
      other.mine == mine &&
      other.reverseReachable == reverseReachable;

  @override
  int get hashCode => Object.hash(
    peerFingerprint,
    peerName,
    iSeeTheirs,
    connectedToThem,
    theyAreConnected,
    mine,
    reverseReachable,
  );
}

/// A device row in the desktop nav pane: the linked device, or a
/// remembered one (not connected now).
enum DeviceRowStatus { linked, remembered }

@immutable
final class DeviceRow {
  const new({
    required this.fingerprint,
    required this.name,
    required this.platform,
    required this.status,
  });

  final String fingerprint;
  final String name;

  /// android | windows | ios; '' when unknown.
  final String platform;
  final DeviceRowStatus status;

  @override
  bool operator ==(Object other) =>
      other is DeviceRow &&
      other.fingerprint == fingerprint &&
      other.name == name &&
      other.platform == platform &&
      other.status == status;

  @override
  int get hashCode => Object.hash(fingerprint, name, platform, status);
}

String _str(Map<String, Object?> json, String key) {
  final v = json[key];
  if (v is String) return v;
  throw FormatException('missing or non-string "$key"');
}

/// `POST /v1/link` (the scanning device A → B, authenticated): "connect
/// back to me at [port] with [invite]". [perms] is what A lets B do with
/// A's files; B only shows it (each side enforces its own choice).
@immutable
final class LinkRequestDto {
  const new({required this.port, required this.invite, required this.perms});

  factory fromJson(Map<String, Object?> json) {
    final port = json['port'];
    if (port is! int || port < 1 || port > 65535) {
      throw const FormatException('bad port');
    }
    return LinkRequestDto(
      port: port,
      invite: _str(json, 'invite'),
      perms: LinkPerms.fromJson(json['perms']),
    );
  }

  final int port;

  /// 32 bytes base64url, single use, 60 s.
  final String invite;
  final LinkPerms perms;

  Map<String, Object?> toJson() => {
    'port': port,
    'invite': invite,
    'perms': perms.toJson(),
  };
}

/// `POST /v1/link` answer: whether B reached A's server (the reverse
/// half); false = one-way link. [perms]: what B lets A do (shown only).
@immutable
final class LinkResponseDto {
  const new({required this.reverse, this.perms});

  factory fromJson(Map<String, Object?> json) => LinkResponseDto(
    reverse: json['reverse'] == true,
    perms: json['perms'] == null ? null : LinkPerms.fromJson(json['perms']),
  );

  final bool reverse;
  final LinkPerms? perms;

  Map<String, Object?> toJson() => {
    'reverse': reverse,
    if (perms case final p?) 'perms': p.toJson(),
  };
}

/// `POST /v1/take` (TASK-E1): the file ids a job is about to read in full
/// ([move]: N11 download-move, the originals are trashed afterwards).
@immutable
final class TakeRequestDto {
  const new({required this.ids, this.move = false});

  factory fromJson(Map<String, Object?> json) {
    final ids = json['ids'];
    if (ids is! List<Object?> || ids.isEmpty) {
      throw const FormatException('missing ids');
    }
    return TakeRequestDto(
      ids: [
        for (final id in ids)
          if (id is String && id.isNotEmpty)
            id
          else
            throw const FormatException('bad id'),
      ],
      move: json['move'] == true,
    );
  }

  final List<String> ids;
  final bool move;

  Map<String, Object?> toJson() => {'ids': ids, if (move) 'move': true};
}
