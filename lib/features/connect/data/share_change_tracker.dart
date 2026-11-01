import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:crypto/crypto.dart' as crypto;
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/media_change_source.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/data/share_scope_store.dart';
import 'package:kfm/features/connect/domain/share_scope.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'share_change_tracker.g.dart';

/// The live-sync tracker of the sharing runs (keepAlive: its token cache
/// and observers outlive any one screen). The share screen calls
/// [ShareChangeTracker.start] when the server runs and
/// [ShareChangeTracker.stop] when it stops.
@Riverpod(keepAlive: true)
ShareChangeTracker shareChangeTracker(Ref ref) {
  final tracker = ShareChangeTracker(
    dao: () => ref.read(mediaIndexDaoProvider),
    scopes: ref.watch(shareScopeStoreProvider),
    canSeeAllFiles: () =>
        ref.read(storageAccessControllerProvider).value?.canSeeAllFiles ??
        false,
    indexChanges: () => ref.read(mediaIndexDaoProvider).watchChanges(),
    filesChanges: () => ref.read(filesTableChangesProvider),
    onFileChange: (change, roots) => ref
        .read(mediaIndexerProvider)
        .onFileChange(change, reconcileRoots: roots),
  );
  ref.onDispose(() => unawaited(tracker.stop()));
  return tracker;
}

/// Live sync on the sharing device (TASK-N7): the `changeToken` each
/// client gets from `GET /v1/session`. A token covers only that client's
/// roots: it is a hash of [MediaIndexDao.scopeDigest] over them (count,
/// bytes, newest `indexed_at_ms` per root) plus the roots themselves, so a
/// change outside them keeps it, and any change inside or a scope edit
/// changes it.
///
/// While [start]ed (the share server runs), tokens are cached and only
/// recomputed after an index change (`indexChanges`) or a scope edit
/// ([ShareScopeStore.changes]); the Files-table observer feeds
/// `onFileChange` (non-media files: `MediaIndexer.onFileChange`), with the
/// shared folders to reconcile. Stopped, every call computes afresh and
/// nothing is observed.
class ShareChangeTracker {
  new({
    required this._dao,
    required this._scopes,
    required this._canSeeAllFiles,
    required this._indexChanges,
    required this._filesChanges,
    required this._onFileChange,
  });

  final MediaIndexDao Function() _dao;
  final ShareScopeStore _scopes;
  final bool Function() _canSeeAllFiles;
  final Stream<int> Function() _indexChanges;
  final Stream<FilesTableChange> Function() _filesChanges;
  final void Function(FilesTableChange change, List<String> reconcileRoots)
  _onFileChange;

  final List<StreamSubscription<Object?>> _subs = [];
  int _indexVersion = 0;
  final Map<String, int> _scopeVersions = {};

  /// Clients seen through [ShareScopeStore.changes] (for the reconcile
  /// roots).
  final Set<String> _clients = {};
  final Map<String, _Cached> _cache = {};

  bool get isRunning => _subs.isNotEmpty;

  /// Share server started: observe the index, scope edits and (Android) the
  /// Files table. Idempotent.
  void start() {
    if (isRunning) return;
    _cache.clear();
    _subs
      ..add(_indexChanges().listen((_) => _indexVersion++))
      ..add(
        _scopes.changes.listen((fp) {
          _clients.add(fp);
          _scopeVersions[fp] = (_scopeVersions[fp] ?? 0) + 1;
        }),
      )
      ..add(
        _filesChanges().listen(
          (c) => _onFileChange(c, reconcileRoots),
          onError: (Object e) =>
              developer.log('files observer failed: $e', name: 'kfm.connect'),
        ),
      );
  }

  /// Share server stopped: no observers left.
  Future<void> stop() async {
    final subs = List.of(_subs);
    _subs.clear();
    _cache.clear();
    _clients.clear();
    for (final s in subs) {
      await s.cancel();
    }
  }

  /// The shared folders of every known client worth a reconcile: never a
  /// whole volume (`/storage/emulated/0`, `/storage/XXXX-XXXX`), which
  /// would walk all storage.
  List<String> get reconcileRoots => {
    for (final fp in _clients)
      for (final r in _scopes.scopeOf(fp).roots)
        if (!_volumeRoot.hasMatch(r.path)) r.path,
  }.toList();

  static final _volumeRoot = RegExp(r'^/storage/(emulated/\d+|[^/]+)$|^/$');

  /// The current token of [clientFingerprint]. A failed index read keeps
  /// the previous token (null if none): the heartbeat must not fail.
  Future<String?> tokenFor(String clientFingerprint) async {
    final scope = _scopes.scopeOf(clientFingerprint);
    if (!isRunning) {
      try {
        return await _compute(scope);
      } on Object catch (e) {
        developer.log(
          'scope digest failed: ${e.runtimeType}',
          name: 'kfm.connect',
        );
        return null;
      }
    }
    final index = _indexVersion;
    final scopeV = _scopeVersions[clientFingerprint] ?? 0;
    final cached = _cache[clientFingerprint];
    if (cached != null &&
        cached.indexVersion == index &&
        cached.scopeVersion == scopeV) {
      return await cached.token;
    }
    var failed = false;
    final token = _compute(scope).then<String?>(
      (t) => t,
      onError: (Object e) {
        failed = true;
        developer.log(
          'scope digest failed: ${e.runtimeType}',
          name: 'kfm.connect',
        );
        return cached?.last;
      },
    );
    final entry = _Cached(index, scopeV, token, cached?.last);
    _cache[clientFingerprint] = entry;
    final value = await token;
    entry.last = value;
    // Retry on the next heartbeat instead of caching the failure.
    if (failed && identical(_cache[clientFingerprint], entry)) {
      _cache.remove(clientFingerprint);
    }
    return value;
  }

  Future<String> _compute(ShareScope scope) async {
    final canSeeAll = _canSeeAllFiles();
    final kinds = canSeeAll ? const <FileKind>{} : mediaKinds;
    final rows = await _dao().scopeDigest([
      for (final r in scope.roots) r.path,
    ], kinds: kinds);
    final parts = [
      if (canSeeAll) 'all' else 'media',
      for (final (i, r) in scope.roots.indexed) ...[
        '${r.id}|${r.readOnly}',
        '${rows[i].count}|${rows[i].bytes}|${rows[i].newestIndexedAtMs}',
      ],
    ];
    final digest = crypto.sha1.convert(utf8.encode(parts.join('\n')));
    return base64Url.encode(digest.bytes.sublist(0, 12));
  }
}

class _Cached {
  new(this.indexVersion, this.scopeVersion, this.token, this.last);

  final int indexVersion;
  final int scopeVersion;
  final Future<String?> token;

  /// The last good token.
  String? last;
}
