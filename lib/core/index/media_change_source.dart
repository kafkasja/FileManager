import 'dart:async';

import 'package:flutter/services.dart';
import 'package:kfm/core/files/android/files_channel.dart';
import 'package:meta/meta.dart';
import 'package:photo_manager/photo_manager.dart';

/// A MediaStore change reported while the app runs.
@immutable
class MediaChange {
  const new({required this.type, this.id});

  /// 'insert', 'update' or 'delete'.
  final String type;

  /// MediaStore id when known (deletes sometimes come without one).
  final int? id;
}

/// Live media changes (Android: photo_manager's ContentObserver; only while
/// the app is in the foreground; anything else is caught by the next scan).
Stream<MediaChange> photoManagerChanges() {
  late final StreamController<MediaChange> controller;
  void onChange(MethodCall call) {
    final args = call.arguments;
    if (args is! Map) return;
    controller.add(
      MediaChange(
        type: args['type'] as String? ?? 'update',
        id: (args['id'] as num?)?.toInt(),
      ),
    );
  }

  controller = StreamController<MediaChange>(
    onListen: () {
      PhotoManager.addChangeCallback(onChange);
      unawaited(PhotoManager.startChangeNotify());
    },
    onCancel: () async {
      PhotoManager.removeChangeCallback(onChange);
      await PhotoManager.stopChangeNotify();
    },
  );
  return controller.stream;
}

/// N7 live sync: one change of Android's `MediaStore.Files` table (the
/// native observer in FilesChannel.kt). Pending rows never arrive.
@immutable
class FilesTableChange {
  const new({required this.type, this.path, this.mediaType, this.id});

  /// 'insert', 'update' or 'delete'.
  final String type;

  /// Absolute path; null for deletes and rows the observer couldn't find.
  final String? path;

  /// `MediaStore.Files.FileColumns.MEDIA_TYPE` (0 none, 1 image, 2 audio,
  /// 3 video, …); null when unknown.
  final int? mediaType;

  /// The MediaStore row id from the change uri, when it has one.
  final int? id;

  /// Image, audio or video: photo_manager's observer already covers it.
  bool get isMedia => mediaType == 1 || mediaType == 2 || mediaType == 3;

  @override
  String toString() => 'FilesTableChange($type, $id, $path, $mediaType)';
}

/// N7: live non-media changes (PDFs, downloads…) from the Files-table
/// observer. Android only; the observer runs only while this is listened.
Stream<FilesTableChange> filesTableChangeStream([EventChannel? channel]) =>
    FilesChannel.filesTableEvents(channel).map(
      (e) => FilesTableChange(
        type: e['type'] is String ? e['type']! as String : 'update',
        path: e['path'] is String ? e['path']! as String : null,
        mediaType: (e['mediaType'] as num?)?.toInt(),
        id: (e['id'] as num?)?.toInt(),
      ),
    );
