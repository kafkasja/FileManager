import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:kfm/features/ai_labels/domain/label_map.dart';
import 'package:kfm/features/ai_labels/domain/label_pipeline.dart';

/// Labels one thumbnail at a time off the UI isolate.
abstract interface class LabelWorker {
  /// KFM labels of [jpeg]. Throws [LabelWorkerCrashed] when the worker
  /// died; other errors (an undecodable thumbnail) fail only that file.
  Future<List<LabelScore>> label(Uint8List jpeg);

  Future<void> close();
}

/// Creates the models inside the worker isolate. Must be a top-level or
/// static function (sent to the isolate).
typedef ImageModelsFactory = ImageModels Function(
  Uint8List classifier,
  Uint8List detector,
);

/// The worker's isolate died (crash, OOM) or was closed mid-request.
class LabelWorkerCrashed implements Exception {
  const new(this.reason);

  final String reason;

  @override
  String toString() => 'LabelWorkerCrashed: $reason';
}

/// The worker couldn't load the models or the native library.
class LabelWorkerStartFailed implements Exception {
  const new(this.reason);

  final String reason;

  @override
  String toString() => 'LabelWorkerStartFailed: $reason';
}

/// One long-lived isolate holding both interpreters (TASK-C3 §5). Models
/// arrive as bytes at spawn; each request sends the JPEG as
/// [TransferableTypedData].
class IsolateLabelWorker implements LabelWorker {
  new _(this._isolate, this._requests, this._events);

  final Isolate _isolate;
  final SendPort _requests;
  final ReceivePort _events;
  final Map<int, Completer<List<LabelScore>>> _pending = {};
  int _nextId = 0;
  bool _dead = false;

  static Future<IsolateLabelWorker> spawn({
    required Uint8List classifier,
    required Uint8List detector,
    required String labelMapJson,
    required ImageModelsFactory createModels,
  }) async {
    final events = ReceivePort();
    final first = Completer<Object?>();
    late final IsolateLabelWorker worker;
    var ready = false;
    events.listen((msg) {
      if (!ready) {
        if (!first.isCompleted) first.complete(msg);
        return;
      }
      worker._onEvent(msg);
    });
    final Isolate isolate;
    try {
      isolate = await Isolate.spawn(
        _main,
        _Init(
          events.sendPort,
          TransferableTypedData.fromList([classifier]),
          TransferableTypedData.fromList([detector]),
          labelMapJson,
          createModels,
        ),
        onError: events.sendPort,
        onExit: events.sendPort,
        debugName: 'kfm-label-worker',
      );
    } on Object catch (e) {
      events.close();
      throw LabelWorkerStartFailed('$e');
    }
    final msg = await first.future;
    if (msg is! SendPort) {
      isolate.kill(priority: Isolate.immediate);
      events.close();
      throw LabelWorkerStartFailed(
        msg is List && msg.isNotEmpty ? '${msg.first}' : '$msg',
      );
    }
    worker = IsolateLabelWorker._(isolate, msg, events);
    ready = true;
    return worker;
  }

  void _onEvent(Object? msg) {
    if (msg is _Reply) {
      final c = _pending.remove(msg.id);
      if (c == null) return;
      if (msg.error case final error?) {
        c.completeError(LabelFailed(error));
      } else {
        c.complete(msg.labels);
      }
      return;
    }
    // onError ([error, stack]) or onExit (null): the isolate is gone.
    _die(msg is List && msg.isNotEmpty ? '${msg.first}' : 'worker exited');
  }

  void _die(String reason) {
    if (_dead) return;
    _dead = true;
    _events.close();
    for (final c in _pending.values) {
      c.completeError(LabelWorkerCrashed(reason));
    }
    _pending.clear();
  }

  @override
  Future<List<LabelScore>> label(Uint8List jpeg) {
    if (_dead) {
      return Future.error(const LabelWorkerCrashed('worker is not running'));
    }
    final id = _nextId++;
    final c = _pending[id] = Completer<List<LabelScore>>();
    _requests.send(_Request(id, TransferableTypedData.fromList([jpeg])));
    return c.future;
  }

  @override
  Future<void> close() async {
    if (_dead) return;
    _requests.send(null);
    _isolate.kill();
    _die('closed');
  }

  static void _main(_Init init) {
    final ImageModels models;
    final LabelMap map;
    try {
      map = LabelMap.parse(init.labelMapJson);
      models = init.createModels(
        init.classifier.materialize().asUint8List(),
        init.detector.materialize().asUint8List(),
      );
      // Native load failures (dlopen) surface as ArgumentError/Error.
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      init.events.send(['$e']);
      return;
    }
    final requests = ReceivePort();
    init.events.send(requests.sendPort);
    requests.listen((msg) {
      if (msg is! _Request) {
        models.close();
        requests.close();
        return;
      }
      try {
        final labels = labelImage(
          msg.jpeg.materialize().asUint8List(),
          models,
          map,
        );
        init.events.send(_Reply(msg.id, labels, null));
      } on Exception catch (e) {
        init.events.send(_Reply(msg.id, const [], '${e.runtimeType}: $e'));
      }
    });
  }
}

/// One file failed inside the worker (the worker keeps running).
class LabelFailed implements Exception {
  const new(this.reason);

  final String reason;

  @override
  String toString() => reason;
}

class _Init {
  const new(
    this.events,
    this.classifier,
    this.detector,
    this.labelMapJson,
    this.createModels,
  );

  final SendPort events;
  final TransferableTypedData classifier;
  final TransferableTypedData detector;
  final String labelMapJson;
  final ImageModelsFactory createModels;
}

class _Request {
  const new(this.id, this.jpeg);

  final int id;
  final TransferableTypedData jpeg;
}

class _Reply {
  const new(this.id, this.labels, this.error);

  final int id;
  final List<LabelScore> labels;
  final String? error;
}
