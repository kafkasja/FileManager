import 'dart:async';

import 'package:crypto/crypto.dart';
import 'package:kfm/features/cloud/data/cloud_destinations_repository.dart';
import 'package:kfm/features/cloud/domain/cloud_writer.dart';

/// A cloud app's folder in memory. [read] resolves a source (URI or path)
/// to its bytes.
class FakeCloudWriter implements CloudDestinationWriter {
  new(this.read);

  final List<int>? Function(String source) read;

  /// uri → bytes of documents in the "cloud".
  final Map<String, List<int>> docs = {};
  final List<String> calls = [];
  final StreamController<({String jobKey, int bytes})> _progress =
      StreamController.broadcast();

  /// Read-back answers other bytes (a virtual-file provider).
  bool corruptReadBack = false;

  /// Read-back throws.
  bool readBackFails = false;

  /// [sizeOf] answers "gone" (the copy vanished before the job end).
  bool reportGone = false;

  /// The next write fails with this.
  CloudWriteFailure? failWrite;

  /// When set, writes wait for it (cancel tests).
  Completer<void>? gate;
  final Set<String> _cancelled = {};
  int _next = 0;

  @override
  Stream<({String jobKey, int bytes})> get progress => _progress.stream;

  @override
  Future<String> create(String location, String name, String? mime) async {
    calls.add('create $name');
    final uri = '$location/doc/${_next++}-$name';
    docs[uri] = const [];
    return uri;
  }

  @override
  Future<CloudWriteResult> write({
    required String source,
    required String remoteUri,
    required String jobKey,
  }) async {
    calls.add('write $remoteUri');
    final g = gate;
    if (g != null) await g.future;
    if (_cancelled.remove(jobKey)) {
      docs.remove(remoteUri);
      throw const CloudWriteException(CloudWriteFailure.cancelled);
    }
    final f = failWrite;
    if (f != null) {
      failWrite = null;
      docs.remove(remoteUri);
      throw CloudWriteException(f);
    }
    final bytes = read(source);
    if (bytes == null) {
      docs.remove(remoteUri);
      throw const CloudWriteException(CloudWriteFailure.notFound);
    }
    docs[remoteUri] = List.of(bytes);
    _progress.add((jobKey: jobKey, bytes: bytes.length));
    return CloudWriteResult(
      sha256: sha256.convert(bytes).toString(),
      bytes: bytes.length,
    );
  }

  @override
  Future<CloudWriteResult> readBack(String remoteUri) async {
    calls.add('readBack $remoteUri');
    if (readBackFails) {
      throw const CloudWriteException(CloudWriteFailure.io);
    }
    final b = docs[remoteUri];
    if (b == null) throw const CloudWriteException(CloudWriteFailure.notFound);
    final bytes = corruptReadBack ? [...b, 0] : b;
    return CloudWriteResult(
      sha256: sha256.convert(bytes).toString(),
      bytes: bytes.length,
    );
  }

  @override
  Future<int?> sizeOf(String remoteUri) async =>
      reportGone ? null : docs[remoteUri]?.length;

  @override
  Future<void> deleteDocument(String remoteUri) async {
    calls.add('delete $remoteUri');
    docs.remove(remoteUri);
  }

  @override
  Future<void> cancel(String jobKey) async {
    calls.add('cancel $jobKey');
    _cancelled.add(jobKey);
  }
}

/// The system tree picker and grants in memory.
class FakeCloudTrees implements CloudTreePlatform {
  final Set<String> persisted = {};
  final List<String> calls = [];

  /// What the picker answers next (null = cancelled).
  String? nextPick;
  bool persistFails = false;
  String authority = 'com.google.android.apps.docs.storage';
  String folderName = 'Photos';

  @override
  Future<String?> pickTree() async {
    calls.add('pickTree');
    return nextPick;
  }

  @override
  Future<bool> persistTree(String uri) async {
    calls.add('persist $uri');
    if (persistFails) return false;
    persisted.add(uri);
    return true;
  }

  @override
  Future<bool> releaseTree(String uri) async {
    calls.add('release $uri');
    return persisted.remove(uri);
  }

  @override
  Future<List<String>> persistedTrees() async {
    calls.add('persistedTrees');
    return persisted.toList();
  }

  @override
  Future<({String? authority, String? name})> label(String uri) async {
    calls.add('label $uri');
    return (authority: authority, name: folderName);
  }
}
