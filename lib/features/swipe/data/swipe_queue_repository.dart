import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/media_index_dao.dart';
import 'package:meta/meta.dart';

/// Photos and videos, newest first (P5 adds filters).
const swipeQuery = IndexQuery(kinds: {FileKind.image, FileKind.video});

@immutable
class SwipeWindow {
  const new(this.files, this.next);

  final List<FileRef> files;

  /// Null = no more files.
  final IndexCursor? next;
}

/// Windowed reads of the swipe queue from the media index (F5), skipping
/// files already acted on in this session.
class SwipeQueueRepository {
  new(this._dao);

  final MediaIndexDao _dao;

  /// Up to [size] files after [after], skipping [skip]. Keyset paging keeps
  /// the order stable when new photos are added.
  Future<SwipeWindow> window({
    required Set<String> skip,
    IndexCursor? after,
    int size = 200,
  }) async {
    final files = <FileRef>[];
    var cursor = after;
    var first = true;
    while (files.length < size && (first || cursor != null)) {
      first = false;
      final page = await _dao.page(swipeQuery, after: cursor, limit: size);
      files.addAll(page.items.where((f) => !skip.contains(f.id)));
      cursor = page.next;
    }
    return SwipeWindow(files, cursor);
  }

  Future<int> count() => _dao.count(swipeQuery);
}
