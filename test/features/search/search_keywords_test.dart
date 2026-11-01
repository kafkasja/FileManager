import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/source_rule.dart';
import 'package:kfm/features/filters/data/filter_query.dart';
import 'package:kfm/features/filters/domain/file_filter.dart';
import 'package:kfm/features/search/data/search_keywords.dart';
import 'package:kfm/features/search/domain/search_keyword.dart';
import 'package:kfm/l10n/generated/app_localizations_en.dart';

void main() {
  late List<SearchKeywordFamily> families;

  setUp(() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    families = container.read(searchKeywordFamiliesProvider);
  });

  SearchKeyword kw(String id) => resolveKeywordId(id, families)!;
  IndexQuery apply(String id, [IndexQuery q = IndexQuery.all]) =>
      kw(id).apply(q);

  test('B8 registers type, source and attr', () {
    expect(families.map((f) => f.prefix), ['type', 'source', 'attr']);
  });

  test('unknown prefixes, args and malformed ids resolve to null', () {
    for (final id in [
      'cloud:on',
      'label:cat',
      'type:banana',
      'source:created',
      'attr:',
      'video',
      ':video',
      '',
    ]) {
      expect(resolveKeywordId(id, families), isNull, reason: id);
    }
  });

  test("type ids → kinds (OR'ed)", () {
    for (final (arg, kind) in [
      ('image', FileKind.image),
      ('video', FileKind.video),
      ('audio', FileKind.audio),
      ('document', FileKind.document),
      ('archive', FileKind.archive),
      ('other', FileKind.other),
    ]) {
      expect(apply('type:$arg').kinds, {kind});
      expect(kw('type:$arg').id, 'type:$arg');
    }
    expect(apply('type:video', apply('type:image')).kinds, {
      FileKind.image,
      FileKind.video,
    });
  });

  test('source ids → every SourceBucket, other = none', () {
    final buckets = <SourceBucket>{};
    for (final arg in [
      'camera',
      'screenshots',
      'screenrecordings',
      'whatsapp',
      'snapchat',
      'telegram',
      'instagram',
      'downloads',
      'expertraw',
      'gifs',
      'collages',
      'clippedimages',
      'livemessages',
      'videocaptures',
      'other',
    ]) {
      final s = apply('source:$arg').sources;
      expect(s, hasLength(1), reason: arg);
      buckets.addAll(s);
    }
    expect(buckets, SourceBucket.values.toSet());
    expect(apply('source:other').sources, {SourceBucket.none});
    expect(apply('source:panorama').panoramaOnly, isTrue);
  });

  test('attr ids', () {
    expect(apply('attr:hidden').hidden, HiddenFilter.only);
    expect(apply('attr:tiny').maxSizeBytes, 10 * 1024);
    expect(apply('attr:large').minSizeBytes, 100 * 1024 * 1024);
    final now = DateTime.now();
    expect(
      apply('attr:today').from,
      dateBounds(const DateLastDays(1), now).from,
    );
    expect(
      apply('attr:week').from,
      dateBounds(const DateLastDays(7), now).from,
    );
    expect(apply('attr:week').to, isNull);
  });

  test('every keyword has a chip label', () {
    final l10n = AppLocalizationsEn();
    expect(kw('type:video').chipLabel(l10n), 'Type: Videos');
    expect(kw('source:whatsapp').chipLabel(l10n), 'Source: WhatsApp');
    expect(kw('source:panorama').chipLabel(l10n), 'Source: Panoramas');
    for (final id in [
      'attr:hidden',
      'attr:tiny',
      'attr:large',
      'attr:today',
      'attr:week',
      'source:other',
      'type:other',
    ]) {
      expect(kw(id).chipLabel(l10n), isNotEmpty, reason: id);
    }
  });

  test('keywords are equal by id', () {
    expect(kw('type:video'), kw('type:video'));
    expect(kw('type:video'), isNot(kw('type:image')));
  });
}
