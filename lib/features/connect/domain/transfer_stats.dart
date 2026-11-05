/// Where one file transfer's time went (TASK-E1 throughput): reading the
/// source, the network, writing + syncing, hashing, the `complete` step.
/// Logged when the file ends (`logTransferStats`), so a slow transfer shows
/// whether the network or the devices were the bottleneck.
class TransferStats {
  new() : _clock = Stopwatch()..start();

  final Stopwatch _clock;

  int bytes = 0;

  /// Waiting for source bytes (sender) / the network (receiver).
  int readMs = 0;

  /// Sending (sender: in `PUT`s; includes waiting for the receiver).
  int networkMs = 0;

  /// Writing to the partial (receiver).
  int writeMs = 0;

  /// fsync + `.json` checkpoints (receiver).
  int syncMs = 0;

  /// Hashing that wasn't overlapped with the transfer (a full read).
  int hashMs = 0;

  /// The `complete` round trip (sender) / publishing (receiver).
  int completeMs = 0;

  int get totalMs => _clock.elapsedMilliseconds;

  /// MB/s over the whole file.
  double get megabytesPerSecond =>
      totalMs <= 0 ? 0 : bytes / 1e6 / (totalMs / 1000);

  /// One line for the log (no names or paths).
  String summary(String side) =>
      '$side: ${(bytes / 1e6).toStringAsFixed(1)} MB in ${totalMs}ms '
      '(${megabytesPerSecond.toStringAsFixed(1)} MB/s): read ${readMs}ms, '
      'network ${networkMs}ms, write ${writeMs}ms, sync ${syncMs}ms, '
      'hash ${hashMs}ms, complete ${completeMs}ms';
}
