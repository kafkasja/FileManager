import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/filters/domain/file_filter.dart';
import 'package:kfm/features/presets/domain/preset.dart';
import 'package:kfm/features/presets/ui/preset_modified_provider.dart';
import 'package:kfm/features/session/domain/session.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/trash/domain/delete_mode.dart';

final _now = DateTime.utc(2026);

Session _session({SwipeLayout layout = SwipeLayout.basic, String? filter}) =>
    Session(
      id: 1,
      layout: layout,
      deleteMode: DeleteMode.trash,
      cursor: 0,
      startedAt: _now,
      updatedAt: _now,
      filterJson: filter,
      presetId: 7,
    );

Preset _preset({String? filter, bool includeReviewed = false}) => Preset(
  id: 7,
  name: 'Screens',
  sortOrder: 0,
  layout: SwipeLayout.basic,
  filterJson: filter,
  includeReviewed: includeReviewed,
);

String _json(FileFilter f) => jsonEncode(f.toJson());

void main() {
  const screenshots = FileFilter(screenshotsOnly: true);

  test('same setup: not modified', () {
    expect(presetSetupModified(_session(), _preset()), isFalse);
    expect(
      presetSetupModified(
        _session(filter: _json(screenshots)),
        _preset(filter: _json(screenshots)),
      ),
      isFalse,
    );
  });

  test('a changed direction is modified', () {
    final layout = SwipeLayout.basic.withDirection(
      SwipeDirection.up,
      const SwipeAction(SwipeActionType.favorite),
    );
    expect(presetSetupModified(_session(layout: layout), _preset()), isTrue);
  });

  test('a filter added or removed is modified', () {
    expect(
      presetSetupModified(_session(filter: _json(screenshots)), _preset()),
      isTrue,
    );
    expect(
      presetSetupModified(_session(), _preset(filter: _json(screenshots))),
      isTrue,
    );
  });

  test('include reviewed: only a different value counts', () {
    final on = _json(const FileFilter(includeReviewed: true));
    expect(presetSetupModified(_session(filter: on), _preset()), isTrue);
    expect(
      presetSetupModified(_session(filter: on), _preset(includeReviewed: true)),
      isFalse,
    );
  });
}
