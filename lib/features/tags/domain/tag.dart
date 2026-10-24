import 'package:meta/meta.dart';

/// A user tag (TASK-P2).
@immutable
class Tag {
  const new({required this.id, required this.name, required this.color});

  final int id;
  final String name;

  /// ARGB, one of [kTagColors].
  final int color;

  @override
  bool operator ==(Object other) =>
      other is Tag &&
      other.id == id &&
      other.name == name &&
      other.color == color;

  @override
  int get hashCode => Object.hash(id, name, color);
}

/// The tag colours offered when creating a tag.
const kTagColors = <int>[
  0xFFE53935, // red
  0xFFFB8C00, // orange
  0xFFFDD835, // yellow
  0xFF43A047, // green
  0xFF00ACC1, // cyan
  0xFF1E88E5, // blue
  0xFF8E24AA, // purple
  0xFF6D4C41, // brown
];

/// Tag names are 1–40 characters after trimming.
const kTagNameMax = 40;

/// A tag with the same name (ignoring case) already exists.
class TagNameTaken implements Exception {
  const new(this.name);

  final String name;

  @override
  String toString() => 'TagNameTaken($name)';
}
