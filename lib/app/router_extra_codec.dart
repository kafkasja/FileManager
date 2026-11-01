import 'dart:convert';
import 'dart:developer' as developer;

import 'package:kfm/features/browse/data/recent_searches.dart';
import 'package:kfm/features/browse/domain/browse_source_chip.dart';
import 'package:kfm/features/tags/domain/tag.dart';

/// GoRouter's `extraCodec` (TASK-H6). A router refresh, a resume or process
/// death re-parses the route through its saved state, which keeps `extra`
/// only if it's JSON (or this codec turns it into JSON). Without it a
/// [BrowseCollection] came back as null and the collection page crashed.
///
/// Strings and null pass through (B8 search's folder). Anything else, or a
/// shape this version doesn't know, decodes to null: the route then falls
/// back on its own (the collection route goes back to Browse).
class KfmExtraCodec extends Codec<Object?, Object?> {
  const new();

  @override
  Converter<Object?, Object?> get encoder => const _Encoder();

  @override
  Converter<Object?, Object?> get decoder => const _Decoder();
}

class _Encoder extends Converter<Object?, Object?> {
  const new();

  @override
  Object? convert(Object? input) => switch (input) {
    null => null,
    final String s => s,
    SourceCollection(:final source) => {'t': 'source', 'v': source.name},
    RecentCollection(:final search) => {
      't': 'recent',
      'search': search.toJson(),
    },
    TagCollection(:final tag) => {
      't': 'tag',
      'id': tag.id,
      'name': tag.name,
      'color': tag.color,
    },
    FavoritesCollection() => const {'t': 'favorites'},
    // Not restorable: dropped like go_router does without a codec.
    _ => null,
  };
}

class _Decoder extends Converter<Object?, Object?> {
  const new();

  @override
  Object? convert(Object? input) {
    if (input == null || input is String) return input;
    if (input is! Map) return null;
    try {
      final j = input.cast<String, Object?>();
      return switch (j['t']) {
        'source' => switch (BrowseSourceChip.values.asNameMap()[j['v']]) {
          final BrowseSourceChip chip => SourceCollection(chip),
          null => null,
        },
        'recent' => switch (j['search']) {
          final Map<Object?, Object?> s => RecentCollection(
            RecentSearch.fromJson(s.cast<String, Object?>()),
          ),
          _ => null,
        },
        'tag' => switch ((j['id'], j['name'], j['color'])) {
          (final int id, final String name, final int color) => TagCollection(
            Tag(id: id, name: name, color: color),
          ),
          _ => null,
        },
        'favorites' => const FavoritesCollection(),
        _ => null,
      };
    } on Object catch (e) {
      // Old or broken saved state: the route falls back (never a crash).
      developer.log('route extra not restored: $e', name: 'kfm.router');
      return null;
    }
  }
}
