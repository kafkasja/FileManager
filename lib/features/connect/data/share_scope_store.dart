import 'dart:async';

import 'package:kfm/features/connect/data/client_session_store.dart';
import 'package:kfm/features/connect/data/path_guard.dart';
import 'package:kfm/features/connect/domain/share_scope.dart';

/// The folder allow-list per client fingerprint for the current sharing run
/// (TASK-N4). Memory only: [clear] (stop sharing) empties it; N6 seeds it
/// for remembered devices. An edit applies to the next request, and the
/// client's in-flight streams outside the new scope are cancelled.
class ShareScopeStore {
  new({required this._sessions});

  final ClientSessionStore _sessions;
  final Map<String, ShareScope> _scopes = {};
  final StreamController<String> _changes = StreamController.broadcast();

  /// The scope of [clientFingerprint]; empty when nothing was shared.
  ShareScope scopeOf(String clientFingerprint) =>
      _scopes[clientFingerprint] ?? ShareScope.empty;

  /// Emits the fingerprint whose scope changed.
  Stream<String> get changes => _changes.stream;

  void set(String clientFingerprint, ShareScope scope) {
    _scopes[clientFingerprint] = scope;
    _sessions.cancelStreamsWhere(clientFingerprint, (path, {required write}) {
      if (PathGuard.isExcluded(path)) return false;
      final root = scope.rootFor(path);
      return root != null && !(write && root.readOnly);
    });
    _changes.add(clientFingerprint);
  }

  /// Stop sharing.
  void clear() {
    final had = _scopes.keys.toList();
    _scopes.clear();
    had.forEach(_changes.add);
  }
}
