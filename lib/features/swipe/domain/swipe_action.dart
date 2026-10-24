import 'dart:convert';
import 'dart:developer' as developer;

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

  /// Throws [FormatException] for unknown types or wrong field types.
  factory fromJson(Map<String, Object?> j) {
    final type = switch (j['type']) {
      final String name => SwipeActionType.values.asNameMap()[name],
      _ => null,
    };
    if (type == null) {
      throw FormatException('Unknown swipe action type: ${j['type']}');
    }
    return SwipeAction(
      type,
      targetFolder: _optional<String>(j, 'targetFolder'),
      tagId: _optional<int>(j, 'tagId'),
      deviceId: _optional<String>(j, 'deviceId'),
    );
  }

  final SwipeActionType type;

  /// moveTo / copyTo (P2).
  final String? targetFolder;

  /// addTag (P2).
  final int? tagId;

  /// sendToDevice (N6 remembered device).
  final String? deviceId;

  static T? _optional<T>(Map<String, Object?> j, String key) =>
      switch (j[key]) {
        null => null,
        final T value => value,
        final other => throw FormatException('Bad $key: $other'),
      };

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

/// Types the "Customize swipes" picker offers (P1–P3). `sendToDevice`
/// (Phase 5) is added by its task.
const assignableSwipeActionTypes = <SwipeActionType>[
  SwipeActionType.trash,
  SwipeActionType.keep,
  SwipeActionType.moveTo,
  SwipeActionType.copyTo,
  SwipeActionType.addTag,
  SwipeActionType.favorite,
  SwipeActionType.renameBatch,
];

extension SwipeActionTypeX on SwipeActionType {
  /// Picking this type opens a folder or tag picker.
  bool get needsTarget => switch (this) {
    SwipeActionType.moveTo ||
    SwipeActionType.copyTo ||
    SwipeActionType.addTag => true,
    _ => false,
  };
}

/// Why a mapped direction can't run right now (the card springs back).
enum SwipeActionProblem { unsupported, tagMissing }

/// What each direction (and the optional action bar, P4) does.
@immutable
class SwipeLayout {
  const new({required this.directions, this.actionBar = const []});

  /// Throws [FormatException] for corrupt data. Unknown direction names are
  /// skipped (a newer version may add some).
  factory fromJson(Map<String, Object?> j) {
    final dirs = switch (j['directions']) {
      null => const <String, Object?>{},
      final Map<Object?, Object?> m => m,
      final other => throw FormatException('Bad directions: $other'),
    };
    final bar = switch (j['actionBar']) {
      null => const <Object?>[],
      final List<Object?> l => l,
      final other => throw FormatException('Bad actionBar: $other'),
    };
    return SwipeLayout(
      directions: {
        for (final MapEntry(:key, :value) in dirs.entries)
          ?SwipeDirection.values.asNameMap()[key]: _action(value),
      },
      actionBar: [for (final a in bar) _action(a)],
    );
  }

  /// Parses stored layout JSON. '' = [basic]; corrupt data is logged and
  /// gives [basic], so a bad value never breaks swiping.
  static SwipeLayout decode(String raw) {
    if (raw.isEmpty) return basic;
    try {
      return switch (jsonDecode(raw)) {
        final Map<String, Object?> j => SwipeLayout.fromJson(j),
        final other => throw FormatException('Not a layout: $other'),
      };
    } on FormatException catch (e, st) {
      developer.log(
        'corrupt swipe layout, using basic',
        name: 'kfm.swipe',
        error: e,
        stackTrace: st,
      );
      return basic;
    }
  }

  static SwipeAction _action(Object? json) => switch (json) {
    final Map<String, Object?> m => SwipeAction.fromJson(m),
    _ => throw FormatException('Bad swipe action: $json'),
  };

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

  /// Up or down does something: only then are vertical swipes recognised
  /// strictly (P1 diagonal guard).
  bool get hasVertical =>
      directions.containsKey(SwipeDirection.up) ||
      directions.containsKey(SwipeDirection.down);

  /// A copy with a new action bar (P4).
  SwipeLayout withActionBar(List<SwipeAction> bar) =>
      SwipeLayout(directions: directions, actionBar: List.unmodifiable(bar));

  /// A copy with [direction] set to [action] (null = nothing).
  SwipeLayout withDirection(SwipeDirection direction, SwipeAction? action) =>
      SwipeLayout(
        directions: {
          for (final MapEntry(:key, :value) in directions.entries)
            if (key != direction) key: value,
          direction: ?action,
        },
        actionBar: actionBar,
      );

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
