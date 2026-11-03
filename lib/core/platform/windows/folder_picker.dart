import 'package:file_selector/file_selector.dart' as fs;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'folder_picker.g.dart';

/// Opens the system folder picker (TASK-PL1: Windows' "Select folder"
/// dialog via `file_selector`). Null = cancelled. Platform errors propagate.
typedef PickFolder = Future<String?> Function({String? confirmLabel});

/// Tests override it.
@Riverpod(keepAlive: true)
PickFolder pickFolder(Ref ref) =>
    ({confirmLabel}) => fs.getDirectoryPath(confirmButtonText: confirmLabel);
