/// PL1: asks the user whether files on a drive without a Recycle Bin may be
/// deleted permanently (one question per delete batch, from D2's
/// `DeleteQueue`). The app shell's `NoTrashPrompter` attaches [handler];
/// with nobody attached the answer is No, so the files stay queued.
class NoTrashConfirmer {
  Future<bool> Function(int count)? handler;

  Future<bool> confirm(int count) async => await handler?.call(count) ?? false;
}
