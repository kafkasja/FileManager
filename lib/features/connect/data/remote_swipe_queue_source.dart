import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/features/connect/data/remote_file_source.dart';
import 'package:kfm/features/connect/domain/files_protocol.dart';
import 'package:kfm/features/session/domain/remote_deck_root.dart';
import 'package:kfm/features/swipe/data/swipe_queue_repository.dart';
import 'package:kfm/features/swipe/data/swipe_queue_source.dart';
import 'package:kfm/features/swipe/domain/swipe_source.dart';

/// One page of the other device's listing (`RemoteFileSource.page`).
typedef RemotePager = Future<RemotePage> Function(
  RemoteQueryDto q, {
  String? cursor,
  int limit,
});

/// The images and videos of a folder on a connected device (TASK-N8):
/// subfolders included, newest first. The cursor is
/// `IndexCursor(<server cursor>, <last file id>)`. Files the `exclude`
/// check picks (P7 labels, which live on this device) are dropped on
/// arrival, and pages are fetched until the window is full or the listing
/// ends. Every call throws `FileOpFailure.unavailable` while the device
/// isn't connected.
class RemoteQueueSource implements SwipeQueueSource {
  new(this._page, this.root, {this._exclude, this.pageSize = 100});

  final RemotePager _page;
  final RemoteDeckRoot root;
  final Future<Set<String>> Function(List<FileRef> files)? _exclude;
  final int pageSize;

  /// The first page's total (files matching the query on the device).
  int? _total;

  /// Ids the device listed so far, and those [_exclude] dropped.
  final Set<String> _seen = {};
  final Set<String> _excluded = {};

  /// Safety stop: a fully excluded listing is paged at most this far per
  /// window.
  static const _maxPagesPerWindow = 50;

  RemoteQueryDto get query => RemoteQueryDto(
    rootId: root.rootId,
    path: root.path,
    includeSubfolders: true,
    kinds: const {FileKind.image, FileKind.video},
  );

  @override
  bool get offersNewFiles => false;

  @override
  SwipeGroupPosition? groupPositionOf(String fileId) => null;

  @override
  Future<SwipeWindow> window({
    required Set<String> skip,
    IndexCursor? after,
    int size = 200,
  }) async {
    var cursor = switch (after?.sortValue) {
      final String c => c,
      _ => null,
    };
    final q = query;
    final files = <FileRef>[];
    var pages = 0;
    do {
      final first = cursor == null;
      final page = await _page(q, cursor: cursor, limit: pageSize);
      pages++;
      if (first && page.total != null) _total = page.total;
      final media = [
        for (final f in page.items)
          if (f.isMedia) f,
      ];
      _seen.addAll(media.map((f) => f.id));
      final excluded = media.isEmpty
          ? const <String>{}
          : await _exclude?.call(media) ?? const <String>{};
      _excluded.addAll(excluded);
      for (final f in media) {
        if (!skip.contains(f.id) && !excluded.contains(f.id)) files.add(f);
      }
      cursor = page.truncated ? null : page.nextCursor;
    } while (cursor != null &&
        files.length < size &&
        pages < _maxPagesPerWindow);
    return SwipeWindow(
      files,
      cursor == null ? null : IndexCursor(cursor, files.lastOrNull?.id ?? ''),
    );
  }

  /// Approximate: the device's total minus the acted-on and excluded files
  /// seen so far (acted files on pages not loaded yet still count).
  @override
  Future<int> remaining(Set<String> acted) async {
    final total = _total ?? 0;
    final gone = _seen
        .where((id) => acted.contains(id) || _excluded.contains(id))
        .length;
    final left = total - gone;
    return left < 0 ? 0 : left;
  }
}
