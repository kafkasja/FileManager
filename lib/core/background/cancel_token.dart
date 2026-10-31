/// Cooperative cancel for long batches (B4/B5): the worker checks
/// [isCancelled] between files and stops there.
class CancelToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;
}
