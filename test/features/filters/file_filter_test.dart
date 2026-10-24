import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/filters/domain/file_filter.dart';

void main() {
  test('JSON round trip of every field; defaults are left out', () {
    final f = FileFilter(
      kinds: const {FileKind.video},
      screenshotsOnly: true,
      date: DateRange(DateTime(2026, 1, 2), DateTime(2026, 3, 4)),
      minSizeBytes: 50 << 20,
      maxSizeBytes: 900 << 20,
      folderPaths: const {'/s/DCIM/Camera', '/s/Pictures'},
      tagMode: TagFilterMode.hasTags,
      tagIds: const {3, 1},
      favoritesOnly: true,
      reviewed: ReviewedFilterMode.notReviewed,
    );
    expect(FileFilter.fromJson(f.toJson()), f);
    expect(FileFilter.decode(jsonEncode(f.toJson())), f);
    expect(FileFilter.none.toJson(), {'v': 1});
    for (final d in const [DateThisMonth(), DateLastDays(30)]) {
      final g = FileFilter(date: d);
      expect(FileFilter.fromJson(g.toJson()), g);
    }
  });

  test('a newer version or bad types throw; decode falls back to none', () {
    expect(() => FileFilter.fromJson(const {'v': 2}), throwsFormatException);
    expect(
      () => FileFilter.fromJson(const {
        'v': 1,
        'kinds': ['spaceship'],
      }),
      throwsFormatException,
    );
    expect(
      () => FileFilter.fromJson(const {'v': 1, 'minSize': 'big'}),
      throwsFormatException,
    );
    expect(FileFilter.decode(null), FileFilter.none);
    expect(FileFilter.decode(''), FileFilter.none);
    expect(FileFilter.decode('{"v": 1, "date": {"t": "?"}}'), FileFilter.none);
    expect(FileFilter.decode('not json'), FileFilter.none);
  });

  test('unknown keys are ignored', () {
    expect(
      FileFilter.fromJson(const {'v': 1, 'future': true, 'favorites': true}),
      const FileFilter(favoritesOnly: true),
    );
  });

  test('validity', () {
    expect(FileFilter.none.isValid, isTrue);
    expect(
      const FileFilter(minSizeBytes: 10, maxSizeBytes: 5).problem,
      FilterProblem.sizeRange,
    );
    expect(
      const FileFilter(tagMode: TagFilterMode.hasTags).problem,
      FilterProblem.noTagsChosen,
    );
    expect(
      FileFilter(date: DateRange(DateTime(2026, 2), DateTime(2026))).problem,
      FilterProblem.dateRange,
    );
    expect(
      const FileFilter(date: DateLastDays(0)).problem,
      FilterProblem.dateRange,
    );
  });

  test('copyWith can clear sizes', () {
    const f = FileFilter(minSizeBytes: 1, maxSizeBytes: 2);
    expect(f.copyWith(clearMinSize: true).minSizeBytes, isNull);
    expect(f.copyWith(clearMinSize: true).maxSizeBytes, 2);
  });
}
