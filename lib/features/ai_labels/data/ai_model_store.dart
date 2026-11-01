import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:kfm/features/ai_labels/data/ai_model_manifest.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

/// Where the downloaded models stand (TASK-C3 §8).
@immutable
sealed class AiModelState {
  const new();
}

/// Reading `installed.json` (first moments after start).
final class AiModelsChecking extends AiModelState {
  const new();

  @override
  bool operator ==(Object other) => other is AiModelsChecking;

  @override
  int get hashCode => 1;
}

/// Not downloaded. [partialBytes] > 0: a cancelled/interrupted download
/// resumes from there. [needsUpdate]: an outdated or corrupt set was found
/// ("AI models need an update — download again"; never automatic).
final class AiModelsNotInstalled extends AiModelState {
  const new({this.partialBytes = 0, this.needsUpdate = false});

  final int partialBytes;
  final bool needsUpdate;

  @override
  bool operator ==(Object other) =>
      other is AiModelsNotInstalled &&
      other.partialBytes == partialBytes &&
      other.needsUpdate == needsUpdate;

  @override
  int get hashCode => Object.hash(partialBytes, needsUpdate);
}

/// Wi-Fi only is on and the phone is on mobile data (or offline).
final class AiModelsWaitingForWifi extends AiModelState {
  const new(this.doneBytes, this.totalBytes);

  final int doneBytes;
  final int totalBytes;

  @override
  bool operator ==(Object other) =>
      other is AiModelsWaitingForWifi &&
      other.doneBytes == doneBytes &&
      other.totalBytes == totalBytes;

  @override
  int get hashCode => Object.hash(2, doneBytes, totalBytes);
}

final class AiModelsDownloading extends AiModelState {
  const new(this.doneBytes, this.totalBytes);

  final int doneBytes;
  final int totalBytes;

  @override
  bool operator ==(Object other) =>
      other is AiModelsDownloading &&
      other.doneBytes == doneBytes &&
      other.totalBytes == totalBytes;

  @override
  int get hashCode => Object.hash(3, doneBytes, totalBytes);
}

final class AiModelsVerifying extends AiModelState {
  const new();

  @override
  bool operator ==(Object other) => other is AiModelsVerifying;

  @override
  int get hashCode => 4;
}

final class AiModelsInstalled extends AiModelState {
  const new(this.totalBytes);

  final int totalBytes;

  @override
  bool operator ==(Object other) =>
      other is AiModelsInstalled && other.totalBytes == totalBytes;

  @override
  int get hashCode => Object.hash(5, totalBytes);
}

enum AiModelFailure { network, http, checksum, diskFull, other }

/// The last download failed (shown with Retry, rule 8).
final class AiModelsFailed extends AiModelState {
  const new(this.reason, {this.detail, this.partialBytes = 0});

  final AiModelFailure reason;
  final String? detail;
  final int partialBytes;

  @override
  bool operator ==(Object other) =>
      other is AiModelsFailed &&
      other.reason == reason &&
      other.detail == detail &&
      other.partialBytes == partialBytes;

  @override
  int get hashCode => Object.hash(reason, detail, partialBytes);
}

/// Verified model bytes for the label worker.
@immutable
class AiModelBytes {
  const new({required this.classifier, required this.detector});

  final Uint8List classifier;
  final Uint8List detector;
}

/// Runs [fn] off the UI isolate (default [Isolate.run]).
typedef StoreCompute = Future<R> Function<R>(FutureOr<R> Function() fn);

/// Downloads, verifies, loads and removes the two models in app-private
/// storage (`<support>/ai_models/`). `dart:io` [HttpClient], HTTPS only,
/// plain GET (Range for resume); nothing about the user is sent. The only
/// network use in C3, and only after the user taps Download (rule 7).
class AiModelStore {
  new({
    required this.manifest,
    required this._baseDir,
    required this._wifiOnly,
    required this._isOnWifi,
    required this._wifiChanges,
    HttpClient Function()? httpClient,
    this._compute = Isolate.run,
    @visibleForTesting this.allowInsecureForTests = false,
  }) : _httpClient = httpClient ?? HttpClient.new;

  final AiModelManifest manifest;
  final Future<Directory> Function() _baseDir;
  final Future<bool> Function() _wifiOnly;
  final Future<bool> Function() _isOnWifi;
  final Stream<bool> _wifiChanges;
  final HttpClient Function() _httpClient;
  final StoreCompute _compute;

  /// Lets tests serve from a loopback `http://` server.
  final bool allowInsecureForTests;

  static const String dirName = 'ai_models';
  static const String installedFile = 'installed.json';

  final StreamController<AiModelState> _states = StreamController.broadcast();
  AiModelState _state = const AiModelsChecking();
  Future<bool>? _download;
  HttpClient? _client;
  Completer<void>? _wake;
  bool _cancelled = false;
  bool _wifiLost = false;
  bool _disposed = false;

  AiModelState get state => _state;
  Stream<AiModelState> get states => _states.stream;
  bool get isInstalled => _state is AiModelsInstalled;

  Future<Directory> _dir() async =>
      Directory(p.join((await _baseDir()).path, dirName));

  // ------------------------------------------------------------- startup

  /// Cheap start-up check: `installed.json` against the manifest (set
  /// version, hashes) and the file sizes. The full re-hash happens in
  /// [loadVerified] before the models are used.
  Future<AiModelState> verifyInstalled() async {
    if (_download != null) return _state;
    try {
      final dir = await _dir();
      final info = File(p.join(dir.path, installedFile));
      if (!info.existsSync()) {
        emit(AiModelsNotInstalled(partialBytes: await _bytesOnDisk(dir)));
        return _state;
      }
      final ok = await _matchesManifest(dir, info);
      emit(
        ok
            ? AiModelsInstalled(manifest.totalBytes)
            : const AiModelsNotInstalled(needsUpdate: true),
      );
    } on Object catch (e) {
      emit(AiModelsFailed(AiModelFailure.other, detail: '$e'));
    }
    return _state;
  }

  Future<bool> _matchesManifest(Directory dir, File info) async {
    try {
      final j = jsonDecode(await info.readAsString()) as Map<String, Object?>;
      if (j['modelSetVersion'] != manifest.modelSetVersion) return false;
      final hashes = j['hashes']! as Map<String, Object?>;
      for (final m in manifest.models) {
        if (hashes[m.file] != m.sha256) return false;
        final f = File(p.join(dir.path, m.file));
        if (!f.existsSync() || f.lengthSync() != m.sizeBytes) return false;
      }
      return true;
      // A hand-edited or truncated file (bad JSON, wrong types).
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return false;
    }
  }

  /// Bytes already on disk (finished files + `.part`s), for resume.
  Future<int> _bytesOnDisk(Directory dir) async {
    var total = 0;
    for (final m in manifest.models) {
      final done = File(p.join(dir.path, m.file));
      final part = File('${done.path}.part');
      if (done.existsSync()) {
        total += done.lengthSync();
      } else if (part.existsSync()) {
        total += part.lengthSync();
      }
    }
    return total;
  }

  // ------------------------------------------------------------ download

  /// Downloads what's missing, verifies each file (size + SHA-256) and
  /// installs the set. Waits for Wi-Fi when Wi-Fi only is on, unless
  /// [useMobileData]. True when installed. Calling it again while running
  /// returns the same run.
  Future<bool> download({bool useMobileData = false}) =>
      _download ??= _runDownload(useMobileData).whenComplete(() {
        _download = null;
        _client = null;
      });

  Future<bool> _runDownload(bool useMobileData) async {
    _cancelled = false;
    final dir = await _dir();
    final total = manifest.totalBytes;
    while (true) {
      _wifiLost = false;
      var done = await _bytesOnDisk(dir);
      try {
        if (!useMobileData && await _wifiOnly() && !await _isOnWifi()) {
          emit(AiModelsWaitingForWifi(done, total));
          await _waitForWifi();
          if (_cancelled) throw const _Cancelled();
          continue;
        }
        await dir.create(recursive: true);
        emit(AiModelsDownloading(done, total));
        final hashes = <String, String>{};
        done = 0;
        for (final m in manifest.models) {
          final dest = File(p.join(dir.path, m.file));
          if (!dest.existsSync() || dest.lengthSync() != m.sizeBytes) {
            await _fetchVerified(m, dest, done, total, useMobileData);
          }
          hashes[m.file] = m.sha256;
          done += m.sizeBytes;
        }
        emit(const AiModelsVerifying());
        await _writeInstalled(dir, hashes);
        emit(AiModelsInstalled(total));
        return true;
      } on _WifiLost {
        if (_cancelled) return await _stopped(dir);
        continue;
      } on _Cancelled {
        return await _stopped(dir);
      } on _ChecksumMismatch catch (e) {
        emit(AiModelsFailed(AiModelFailure.checksum, detail: e.file));
        return false;
      } on _HttpStatus catch (e) {
        emit(
          AiModelsFailed(
            AiModelFailure.http,
            detail: '${e.code}',
            partialBytes: await _bytesOnDisk(dir),
          ),
        );
        return false;
      } on FileSystemException catch (e) {
        final full = e.osError?.errorCode == 28 || e.osError?.errorCode == 112;
        emit(
          AiModelsFailed(
            full ? AiModelFailure.diskFull : AiModelFailure.other,
            detail: e.message,
            partialBytes: await _bytesOnDisk(dir),
          ),
        );
        return false;
      } on Object catch (e) {
        if (_cancelled) return await _stopped(dir);
        emit(
          AiModelsFailed(
            AiModelFailure.network,
            detail: '${e.runtimeType}',
            partialBytes: await _bytesOnDisk(dir),
          ),
        );
        return false;
      }
    }
  }

  Future<bool> _stopped(Directory dir) async {
    if (!_disposed) {
      emit(AiModelsNotInstalled(partialBytes: await _bytesOnDisk(dir)));
    }
    return false;
  }

  Future<void> _waitForWifi() async {
    final wake = _wake = Completer<void>();
    final sub = _wifiChanges.listen((on) {
      if (on && !wake.isCompleted) wake.complete();
    });
    try {
      // The change may have happened before listening.
      if (await _isOnWifi()) return;
      await wake.future;
    } finally {
      await sub.cancel();
      _wake = null;
    }
  }

  /// Primary URL, then the fallback (if any) only when the primary fails;
  /// either is accepted only with the pinned SHA-256.
  Future<void> _fetchVerified(
    AiModelEntry m,
    File dest,
    int doneBefore,
    int total,
    bool useMobileData,
  ) async {
    final part = File('${dest.path}.part');
    final urls = [m.url, ?m.fallbackUrl];
    for (final (i, url) in urls.indexed) {
      final last = i == urls.length - 1;
      try {
        await _get(url, m, part, doneBefore, total, useMobileData);
      } on _Cancelled {
        rethrow;
      } on _WifiLost {
        rethrow;
      } on FileSystemException {
        rethrow;
      } on Object {
        if (_cancelled) rethrow;
        if (last) rethrow;
        // The other source starts from 0 (never mixes bytes).
        if (part.existsSync()) part.deleteSync();
        continue;
      }
      emit(const AiModelsVerifying());
      final ok =
          part.lengthSync() == m.sizeBytes &&
          await _compute(_sha256Task(part.path)) == m.sha256;
      if (ok) {
        await part.rename(dest.path);
        emit(AiModelsDownloading(doneBefore + m.sizeBytes, total));
        return;
      }
      part.deleteSync();
      if (last) throw _ChecksumMismatch(m.file);
    }
  }

  Future<void> _get(
    String url,
    AiModelEntry m,
    File part,
    int doneBefore,
    int total,
    bool useMobileData,
  ) async {
    final uri = Uri.parse(url);
    if (uri.scheme != 'https' && !allowInsecureForTests) {
      throw ArgumentError.value(url, 'url', 'HTTPS only');
    }
    var have = part.existsSync() ? part.lengthSync() : 0;
    if (have > m.sizeBytes) {
      part.deleteSync();
      have = 0;
    }
    if (have == m.sizeBytes) return;
    if (_cancelled) throw const _Cancelled();
    final client = _client = _httpClient();
    StreamSubscription<bool>? wifiSub;
    if (!useMobileData && await _wifiOnly()) {
      wifiSub = _wifiChanges.listen((on) {
        if (on) return;
        _wifiLost = true;
        client.close(force: true);
      });
    }
    IOSink? sink;
    try {
      final req = await client.getUrl(uri);
      if (have > 0) req.headers.set(HttpHeaders.rangeHeader, 'bytes=$have-');
      final res = await req.close();
      final append =
          res.statusCode == HttpStatus.partialContent &&
          have > 0 &&
          (res.headers.value(HttpHeaders.contentRangeHeader) ?? '').startsWith(
            'bytes $have-',
          );
      if (!append && res.statusCode != HttpStatus.ok) {
        await res.drain<void>().catchError((_) {});
        // 416 / a 206 for another range: start over next time.
        if (res.statusCode == HttpStatus.requestedRangeNotSatisfiable ||
            res.statusCode == HttpStatus.partialContent) {
          part.deleteSync();
        }
        throw _HttpStatus(res.statusCode);
      }
      if (!append) have = 0;
      sink = part.openWrite(mode: append ? FileMode.append : FileMode.write);
      await for (final chunk in res) {
        if (_cancelled) throw const _Cancelled();
        sink.add(chunk);
        have += chunk.length;
        if (have > m.sizeBytes) throw _ChecksumMismatch(m.file);
        emit(AiModelsDownloading(doneBefore + have, total));
      }
      await sink.flush();
    } on Object {
      if (_cancelled) throw const _Cancelled();
      if (_wifiLost) throw const _WifiLost();
      rethrow;
    } finally {
      await sink?.close();
      await wifiSub?.cancel();
      client.close(force: true);
    }
  }

  Future<void> _writeInstalled(
    Directory dir,
    Map<String, String> hashes,
  ) async {
    final tmp = File(p.join(dir.path, '$installedFile.tmp'));
    await tmp.writeAsString(
      jsonEncode({
        'modelSetVersion': manifest.modelSetVersion,
        'hashes': hashes,
      }),
      flush: true,
    );
    await tmp.rename(p.join(dir.path, installedFile));
  }

  /// Stops a running download (or the Wi-Fi wait); the `.part` stays for
  /// resume.
  Future<void> cancel() async {
    final running = _download;
    if (running == null) return;
    _cancelled = true;
    _client?.close(force: true);
    final wake = _wake;
    if (wake != null && !wake.isCompleted) wake.complete();
    await running;
  }

  // ------------------------------------------------------------ use/remove

  /// Both models read and fully re-hashed (off the UI isolate). Null when
  /// a file is missing or changed: the set is marked "download again".
  Future<AiModelBytes?> loadVerified() async {
    if (_state is AiModelsChecking) await verifyInstalled();
    if (_state is! AiModelsInstalled) return null;
    final dir = await _dir();
    final entries = [
      for (final id in ['classifier', 'detector'])
        (p.join(dir.path, manifest.byId(id).file), manifest.byId(id).sha256),
    ];
    final bytes = await _compute(_readVerifiedTask(entries));
    if (bytes == null) {
      emit(const AiModelsNotInstalled(needsUpdate: true));
      return null;
    }
    return AiModelBytes(classifier: bytes[0], detector: bytes[1]);
  }

  /// Deletes `ai_models/` (files, `.part`s, `installed.json`).
  Future<void> remove() async {
    await cancel();
    final dir = await _dir();
    if (dir.existsSync()) await dir.delete(recursive: true);
    emit(const AiModelsNotInstalled());
  }

  /// Publishes [s] (subclasses: test fakes).
  @protected
  void emit(AiModelState s) {
    if (_disposed) return;
    _state = s;
    _states.add(s);
  }

  void dispose() {
    _disposed = true;
    _cancelled = true;
    _client?.close(force: true);
    final wake = _wake;
    if (wake != null && !wake.isCompleted) wake.complete();
    unawaited(_states.close());
  }
}

// Top-level so the isolate closures capture only their arguments.
Future<String> Function() _sha256Task(String path) =>
    () => _sha256Of(path);

List<Uint8List>? Function() _readVerifiedTask(List<(String, String)> entries) =>
    () => _readVerified(entries);

Future<String> _sha256Of(String path) async =>
    (await sha256.bind(File(path).openRead()).first).toString();

/// Null when a file is missing or its hash differs.
List<Uint8List>? _readVerified(List<(String, String)> entries) {
  final out = <Uint8List>[];
  for (final (path, hash) in entries) {
    final f = File(path);
    if (!f.existsSync()) return null;
    final bytes = f.readAsBytesSync();
    if (sha256.convert(bytes).toString() != hash) return null;
    out.add(bytes);
  }
  return out;
}

class _Cancelled implements Exception {
  const new();
}

class _WifiLost implements Exception {
  const new();
}

class _HttpStatus implements Exception {
  const new(this.code);

  final int code;
}

class _ChecksumMismatch implements Exception {
  const new(this.file);

  final String file;
}
