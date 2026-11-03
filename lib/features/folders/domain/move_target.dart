import 'package:meta/meta.dart';

/// Where Move/Copy sends files (B4 + X3): a folder on this device, or one
/// of the user's cloud destinations.
@immutable
sealed class MoveTarget {
  const new();
}

final class FolderTarget extends MoveTarget {
  const new(this.path);

  /// Absolute folder path.
  final String path;
}

final class CloudTarget extends MoveTarget {
  const new(this.destinationId);

  final int destinationId;
}
