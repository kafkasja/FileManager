import 'dart:async';
import 'dart:io';

import 'package:kfm/core/files/file_ids.dart';
import 'package:kfm/core/files/file_op_exception.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/files/file_source_provider.dart';
import 'package:kfm/features/share_in/data/share_in_channel.dart';
import 'package:kfm/features/share_in/domain/shared_batch.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'share_in_service.g.dart';

/// Every item of a share failed (access revoked, no space): rule 8.
class ShareInFailedException implements Exception {
  const new(this.count, {this.noSpace = false});

  final int count;
  final bool noSpace;

  @override
  String toString() => 'ShareInFailedException($count, noSpace: $noSpace)';
}

/// Turns Android's raw batch into [FileRef]s (TASK-X1): `media` items by
/// MediaStore id (`ms:<id>`; one KFM can't see is copied instead), `copy`
/// items as `path:` refs. Never by name + size.
class ShareInResolver {
  const new(this._platform, this._files);

  final ShareInPlatform _platform;
  final FileSource _files;

  Future<SharedBatch> resolve(Map<Object?, Object?> raw) async {
    final id = raw['id'] as String? ?? '';
    final receivedMs = raw['receivedAtMs'] is int
        ? raw['receivedAtMs']! as int
        : DateTime.now().millisecondsSinceEpoch;
    final items = [
      for (final i in raw['items'] is List ? raw['items']! as List : const [])
        if (i is Map) i,
    ];
    final files = <FileRef>[];
    final copied = <String>{};
    var failed = 0;
    var noSpace = 0;
    final seen = <String>{};
    for (final item in items) {
      var current = item;
      if (current['kind'] == 'media') {
        final ref = await _statOrNull('ms:${current['id']}');
        if (ref != null) {
          if (seen.add(ref.id)) files.add(ref);
          continue;
        }
        final uri = current['uri'];
        current = uri is String
            ? await _platform.copyItem(
                batchId: id,
                receivedAtMs: receivedMs,
                uri: uri,
              )
            : const {'kind': 'failed', 'error': 'noAccess'};
      }
      if (current['kind'] == 'copy' && current['path'] is String) {
        final ref = await _statOrNull('path:${current['path']}');
        if (ref != null) {
          if (seen.add(ref.id)) files.add(ref);
          copied.add(ref.id);
          continue;
        }
      }
      failed++;
      if (current['error'] == 'noSpace') noSpace++;
    }
    final notFiles = raw['notFiles'] == true;
    if (files.isEmpty && failed > 0) {
      throw ShareInFailedException(failed, noSpace: noSpace > 0);
    }
    return SharedBatch(
      id: id,
      receivedAt: DateTime.fromMillisecondsSinceEpoch(receivedMs, isUtc: true),
      files: List.unmodifiable(files),
      copiedIds: Set.unmodifiable(copied),
      failedCount: failed,
      skippedNotFiles: notFiles,
    );
  }

  Future<FileRef?> _statOrNull(String id) async {
    try {
      return await _files.stat(id);
    } on FileOpException {
      return null; // treated like "can't see it" (copied or failed)
    }
  }
}

/// Null off Android (and in tests unless overridden).
@Riverpod(keepAlive: true)
ShareInPlatform? shareInPlatform(Ref ref) =>
    Platform.isAndroid ? ShareInChannel() : null;

/// The share being resolved or shown. [batchId] is set as soon as Android
/// hands KFM a share (with files); [batch] is loading until resolved.
@immutable
class ShareInState {
  const new({this.batchId, this.batch = const AsyncData(null)});

  final String? batchId;
  final AsyncValue<SharedBatch?> batch;

  @override
  bool operator ==(Object other) =>
      other is ShareInState && other.batchId == batchId && other.batch == batch;

  @override
  int get hashCode => Object.hash(batchId, batch);
}

/// TASK-X1: the latest share into KFM. Takes Android's pending batch on
/// start (cold start) and whenever one is ready. Errors propagate.
@Riverpod(keepAlive: true)
class PendingSharedBatch extends _$PendingSharedBatch {
  /// The batch [take] is resolving (a newer share or [dismiss] wins).
  String? _taking;

  @override
  ShareInState build() {
    final platform = ref.watch(shareInPlatformProvider);
    if (platform == null) return const ShareInState();
    final sub = platform.events().listen(_onEvent, onError: _onError);
    // A moved/renamed file keeps its place in the batch under its new id.
    final ids = ref
        .read(fileSourceProvider)
        .idChanges
        .listen((c) => replaceFile(c.oldId, c.newRef));
    ref.onDispose(() {
      unawaited(sub.cancel());
      unawaited(ids.cancel());
    });
    // Cold start: the share may already be resolved on the Kotlin side.
    unawaited(Future<void>.microtask(take));
    return const ShareInState();
  }

  void _onEvent(ShareInEvent e) {
    switch (e) {
      case ShareInStarted(:final batchId, :final count) when count > 0:
        state = ShareInState(batchId: batchId, batch: const AsyncLoading());
        ref.read(shareInProgressSinkProvider.notifier).report(null);
      case ShareInStarted():
        break;
      case ShareInCopyProgress(:final batchId, :final index, :final bytes):
        ref
            .read(shareInProgressSinkProvider.notifier)
            .report(
              ShareInProgress(
                batchId: batchId,
                index: index,
                bytes: bytes,
                total: e.total,
              ),
            );
      case ShareInReady():
        unawaited(take());
    }
  }

  void _onError(Object error, StackTrace st) {
    state = ShareInState(batchId: state.batchId, batch: AsyncError(error, st));
  }

  /// Takes and resolves Android's pending batch (if any).
  Future<void> take() async {
    final platform = ref.read(shareInPlatformProvider);
    if (platform == null) return;
    final Map<Object?, Object?>? raw;
    try {
      raw = await platform.takePending();
    } on Object catch (e, st) {
      if (!ref.mounted) return;
      _onError(e, st);
      return;
    }
    if (raw == null || !ref.mounted) return;
    final id = raw['id'] as String?;
    _taking = id;
    final items = raw['items'];
    // Text only: no screen, just the "only files" hint (no loading state).
    if (items is List && items.isNotEmpty) {
      state = ShareInState(batchId: id, batch: const AsyncLoading());
    }
    try {
      final batch = await ShareInResolver(
        platform,
        ref.read(fileSourceProvider),
      ).resolve(raw);
      if (!ref.mounted || _taking != id) return;
      state = ShareInState(batchId: id, batch: AsyncData(batch));
    } on Object catch (e, st) {
      if (!ref.mounted || _taking != id) return;
      state = ShareInState(batchId: id, batch: AsyncError(e, st));
    } finally {
      if (ref.mounted) {
        ref.read(shareInProgressSinkProvider.notifier).report(null);
      }
    }
  }

  /// Stops the copy of the batch being resolved.
  Future<void> cancel() async {
    final id = state.batchId;
    final platform = ref.read(shareInPlatformProvider);
    if (id == null || platform == null) return;
    await platform.cancel(id);
  }

  /// After a move/copy/rename: follows id changes, drops files that are gone.
  void replaceFile(String oldId, FileRef? next) {
    final batch = state.batch.value;
    if (batch == null) return;
    final files = <FileRef>[];
    final copied = {...batch.copiedIds};
    for (final f in batch.files) {
      if (f.id != oldId) {
        files.add(f);
        continue;
      }
      copied.remove(oldId);
      if (next != null) {
        files.add(next);
        if (isSharedInCopyPath(next.path)) copied.add(next.id);
      }
    }
    state = ShareInState(
      batchId: state.batchId,
      batch: AsyncData(batch.copyWith(files: files, copiedIds: copied)),
    );
  }

  /// The Shared screen closed: forget the batch (copies stay until cleanup).
  void dismiss() {
    _taking = null;
    state = const ShareInState();
  }

  /// [dismiss] if [batchId] is still the current batch (a newer share stays).
  void dismissIf(String? batchId) {
    if (ref.mounted && state.batchId == batchId) dismiss();
  }

  @visibleForTesting
  // A test hook, not a property.
  // ignore: use_setters_to_change_properties
  void debugSet(ShareInState s) => state = s;
}

/// Copy progress of a big item while a batch resolves.
@Riverpod(keepAlive: true)
class ShareInProgressSink extends _$ShareInProgressSink {
  @override
  ShareInProgress? build() => null;

  // Called from event handlers; a method reads better there.
  // ignore: use_setters_to_change_properties
  void report(ShareInProgress? p) => state = p;
}

/// How long app-owned copies of shared files are kept.
const sharedInCopyRetention = Duration(days: 7);

/// Deletes `<root>/<receivedAtMs>/` folders older than [retention] before
/// [now]. Returns how many folders were removed.
Future<int> purgeSharedInCopies(
  Directory root, {
  required DateTime now,
  Duration retention = sharedInCopyRetention,
}) async {
  if (!root.existsSync()) return 0;
  final cutoff = now.subtract(retention).millisecondsSinceEpoch;
  var removed = 0;
  await for (final e in root.list(followLinks: false)) {
    if (e is! Directory) continue;
    final ms = int.tryParse(e.uri.pathSegments.where((s) => s.isNotEmpty).last);
    if (ms == null || ms >= cutoff) continue;
    await e.delete(recursive: true);
    removed++;
  }
  return removed;
}

/// App start: removes shared-in copies older than 7 days (X1).
@Riverpod(keepAlive: true)
Future<int> shareInCleanup(Ref ref) async {
  final platform = ref.read(shareInPlatformProvider);
  if (platform == null) return 0;
  return await purgeSharedInCopies(
    Directory(await platform.root()),
    now: DateTime.now(),
  );
}
