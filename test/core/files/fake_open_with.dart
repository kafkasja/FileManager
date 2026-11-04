import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/open_with.dart';

/// Records "Open with" calls; [noApp] makes every call fail like a device
/// without a matching app.
class FakeOpenWith implements OpenWithService {
  final List<FileRef> opened = [];

  /// [OpenWithService.open] calls (the default app).
  final List<FileRef> openedDefault = [];
  bool noApp = false;

  @override
  Future<void> open(FileRef f) async {
    if (noApp) {
      throw FileOpException(FileOpFailure.unsupported, 'no app', fileId: f.id);
    }
    openedDefault.add(f);
  }

  @override
  Future<void> openWith(FileRef f) async {
    if (noApp) {
      throw FileOpException(FileOpFailure.unsupported, 'no app', fileId: f.id);
    }
    opened.add(f);
  }
}
