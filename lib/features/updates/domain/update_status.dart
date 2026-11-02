import 'package:kfm/features/updates/domain/release_info.dart';
import 'package:meta/meta.dart';

/// Result of the GitHub release check (TASK-X7).
@immutable
sealed class UpdateStatus {
  const new();
}

final class UpdateChecking extends UpdateStatus {
  const new();
}

final class UpToDate extends UpdateStatus {
  const new({this.noReleases = false});

  /// GitHub answered 404: no release yet (or the repo is private).
  final bool noReleases;
}

final class UpdateAvailable extends UpdateStatus {
  const new(this.release);

  final ReleaseInfo release;
}

final class UpdateCheckFailed extends UpdateStatus {
  const new(this.error, {required this.manual});

  final Object error;
  final bool manual;
}

/// Why a check failed.
enum ReleaseCheckFailure {
  /// No connection, DNS, TLS or timeout.
  offline,

  /// 403/429: GitHub's limit (60 requests an hour per IP).
  busy,

  /// Unexpected status, bad JSON, or a page outside KFM's repository.
  badResponse,

  /// The tag isn't `vX.Y.Z`: treated as "no update".
  unparsableTag,
}

@immutable
class ReleaseCheckException implements Exception {
  const new(this.failure, this.message);

  final ReleaseCheckFailure failure;
  final String message;

  @override
  String toString() => 'ReleaseCheckException(${failure.name}): $message';
}
