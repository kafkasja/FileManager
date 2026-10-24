import 'package:meta/meta.dart';

enum SwipeDirection { left, right, up, down }

enum SwipeActionType {
  trash,
  keep,
  moveTo,
  copyTo,
  addTag,
  favorite,
  renameBatch,
  sendToDevice,
}

/// What a swipe does. Basic version owned by S1, extended by P2.
@immutable
class SwipeAction {
  const new(this.type, {this.targetFolder, this.tagId, this.deviceId});

  factory fromJson(Map<String, Object?> j) => SwipeAction(
    SwipeActionType.values.byName(j['type']! as String),
    targetFolder: j['targetFolder'] as String?,
    tagId: j['tagId'] as int?,
    deviceId: j['deviceId'] as String?,
  );

  final SwipeActionType type;

  /// moveTo / copyTo (P2).
  final String? targetFolder;

  /// addTag (P2).
  final int? tagId;

  /// sendToDevice (N6 remembered device).
  final String? deviceId;

  static const trash = SwipeAction(SwipeActionType.trash);
  static const keep = SwipeAction(SwipeActionType.keep);

  Map<String, Object?> toJson() => {
    'type': type.name,
    if (targetFolder != null) 'targetFolder': targetFolder,
    if (tagId != null) 'tagId': tagId,
    if (deviceId != null) 'deviceId': deviceId,
  };

  @override
  bool operator ==(Object other) =>
      other is SwipeAction &&
      other.type == type &&
      other.targetFolder == targetFolder &&
      other.tagId == tagId &&
      other.deviceId == deviceId;

  @override
  int get hashCode => Object.hash(type, targetFolder, tagId, deviceId);

  @override
  String toString() => 'SwipeAction(${type.name})';
}

/// What each direction (and the optional action bar, P4) does.
@immutable
class SwipeLayout {
  const new({required this.directions, this.actionBar = const []});

  factory fromJson(Map<String, Object?> j) {
    final dirs = (j['directions'] as Map?)?.cast<String, Object?>() ?? {};
    final bar = (j['actionBar'] as List?) ?? const [];
    return SwipeLayout(
      directions: {
        for (final MapEntry(:key, :value) in dirs.entries)
          ?SwipeDirection.values.asNameMap()[key]: SwipeAction.fromJson(
            (value! as Map).cast<String, Object?>(),
          ),
      },
      actionBar: [
        for (final a in bar)
          SwipeAction.fromJson((a! as Map).cast<String, Object?>()),
      ],
    );
  }

  final Map<SwipeDirection, SwipeAction> directions;
  final List<SwipeAction> actionBar;

  /// Left = trash, right = keep.
  static const basic = SwipeLayout(
    directions: {
      SwipeDirection.left: SwipeAction.trash,
      SwipeDirection.right: SwipeAction.keep,
    },
  );

  /// Null = unmapped: the card snaps back and nothing is recorded.
  SwipeAction? actionFor(SwipeDirection d) => directions[d];

  Map<String, Object?> toJson() => {
    'directions': {
      for (final MapEntry(:key, :value) in directions.entries)
        key.name: value.toJson(),
    },
    'actionBar': [for (final a in actionBar) a.toJson()],
  };

  @override
  bool operator ==(Object other) =>
      other is SwipeLayout &&
      other.directions.length == directions.length &&
      directions.entries.every((e) => other.directions[e.key] == e.value) &&
      other.actionBar.length == actionBar.length &&
      Iterable<int>.generate(actionBar.length)
          .every((i) => other.actionBar[i] == actionBar[i]);

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(
      directions.entries.map((e) => Object.hash(e.key, e.value)),
    ),
    Object.hashAll(actionBar),
  );
}
