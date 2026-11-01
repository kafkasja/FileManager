import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/app/router_extra_codec.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/features/browse/data/recent_searches.dart';
import 'package:kfm/features/browse/domain/browse_source_chip.dart';
import 'package:kfm/features/tags/domain/tag.dart';

/// Encode, through real JSON (like the saved route state), then decode.
Object? _roundTrip(Object? extra) {
  const codec = KfmExtraCodec();
  final json = jsonDecode(jsonEncode(codec.encode(extra)));
  return codec.decode(json);
}

void main() {
  test('every source collection round-trips', () {
    for (final chip in BrowseSourceChip.values) {
      expect(_roundTrip(SourceCollection(chip)), SourceCollection(chip));
    }
  });

  test('a recent search round-trips with its query, title and text', () {
    final search = RecentSearch(
      title: 'PDF > 10 MB',
      query: IndexQuery(
        kinds: const {FileKind.document},
        minSizeBytes: 10 << 20,
        from: DateTime.utc(2025),
        nameContains: 'tax',
      ),
      at: DateTime.utc(2026, 11),
      text: 'tax pdf',
      demoted: const {'pdf'},
    );
    final back = _roundTrip(RecentCollection(search))! as RecentCollection;
    expect(back, RecentCollection(search));
    expect(back.search.text, 'tax pdf');
    expect(back.search.demoted, {'pdf'});
    expect(back.query, search.query);
  });

  test('a tag and Favorites round-trip', () {
    const tag = Tag(id: 7, name: 'Trip', color: 0xFF43A047);
    final back = _roundTrip(const TagCollection(tag))! as TagCollection;
    expect(back.tag, tag);
    expect(
      _roundTrip(const FavoritesCollection()),
      const FavoritesCollection(),
    );
  });

  test('Strings and null pass through (B8 search folder)', () {
    expect(_roundTrip('/storage/emulated/0/DCIM'), '/storage/emulated/0/DCIM');
    expect(_roundTrip(null), isNull);
  });

  test('garbage and unknown shapes decode to null', () {
    const codec = KfmExtraCodec();
    for (final bad in <Object?>[
      42,
      const ['a'],
      const {'t': 'nope'},
      const {'t': 'source', 'v': 'gone'},
      const {'t': 'tag', 'id': 'x'},
      const {
        't': 'recent',
        'search': {'title': 1},
      },
      const {
        't': 'recent',
        'search': {
          'title': 't',
          'query': {'v': 99},
          'at': 0,
        },
      },
    ]) {
      expect(codec.decode(bad), isNull, reason: '$bad');
    }
    // Something that isn't restorable isn't saved either.
    expect(codec.encode(Object()), isNull);
  });
}
