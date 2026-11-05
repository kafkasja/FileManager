import 'dart:async';

import 'package:kfm/features/connect/domain/link.dart';

/// What THIS device lets each linked peer do with its files (TASK-E1), by
/// the peer's fingerprint: the user's own choice in the link dialog (or
/// the remembered row). Never what a peer claims. Memory only; a peer
/// without an entry is not a link peer (N3/N6 connections keep their old
/// rules: no take prompt).
class LinkPermsStore {
  final Map<String, LinkPerms> _byFp = {};
  final StreamController<String> _changes = StreamController.broadcast();

  /// Emits the fingerprint whose perms changed.
  Stream<String> get changes => _changes.stream;

  LinkPerms? of(String fingerprint) => _byFp[fingerprint];

  void set(String fingerprint, LinkPerms perms) {
    if (_byFp[fingerprint] == perms) return;
    _byFp[fingerprint] = perms;
    _changes.add(fingerprint);
  }

  void remove(String fingerprint) {
    if (_byFp.remove(fingerprint) != null) _changes.add(fingerprint);
  }

  /// Stop sharing.
  void clear() {
    final had = _byFp.keys.toList();
    _byFp.clear();
    had.forEach(_changes.add);
  }
}
