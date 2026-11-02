import 'package:kfm/core/files/file_ref.dart';

/// The MIME type Android's installer opens.
const apkMimeType = 'application/vnd.android.package-archive';

/// TASK-X5: a plain `.apk` on this device (by MIME or name). Files on a
/// connected device can't be inspected or installed from here.
bool isApk(FileRef f) =>
    f.origin != FileOrigin.remote &&
    (f.mimeType == apkMimeType || f.name.toLowerCase().endsWith('.apk'));
