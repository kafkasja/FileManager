import 'dart:async';

import 'package:flutter/services.dart';
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
