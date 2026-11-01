import 'dart:async';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/db/app_database.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/source_rule.dart';
import 'package:kfm/features/browse/data/recent_searches.dart';
import 'package:kfm/features/browse/domain/browse_source_chip.dart';
import 'package:kfm/features/filters/data/filter_query.dart';
import 'package:kfm/features/filters/domain/file_filter.dart';
import 'package:kfm/features/search/data/builtin_keywords.dart';
import 'package:kfm/features/search/data/search_keywords.dart';
import 'package:kfm/features/search/data/search_vocabulary.dart';
import 'package:kfm/features/search/domain/search_keyword.dart';
import 'package:kfm/features/search/ui/search_controller.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

final AppLocalizations _l10n = lookupAppLocalizations(const Locale('en'));

SearchVocabulary _vocab() {
  const families = [typeKeywords, sourceKeywords, attributeKeywords];
  SearchKeyword kw(String id) => resolveKeywordId(id, families)!;
  return SearchVocabulary(
    phrases: {
      'whatsapp': kw('source:whatsapp'),
      'telegram': kw('source:telegram'),
      'video': kw('type:video'),
      'photo': kw('type:image'),
      'today': kw('attr:today'),
    },
  );
}

/// Counts what the controller records.
class _SpyRecents extends RecentSearchesRepository {
  new(super._settings);

  final List<RecentSearch> added = [];

  @override
  Future<void> add(
    String title,
    IndexQuery query, {
    String? text,
    Set<String> demoted = const {},
  }) {
    added.add(
      RecentSearch(
        title: title,
        query: query,
        at: DateTime.utc(2026),
        text: text,
        demoted: demoted,
      ),
    );
    return super.add(title, query, text: text, demoted: demoted);
  }
}

class _Harness {
  new(this.container, this.recents);

  final ProviderContainer container;
  final _SpyRecents recents;
  final Map<String?, ProviderSubscription<SearchState>> _subs = {};

  /// Opens (keeps alive) the search screen's controller for [folder].
  SearchScreenController open([String? folder]) {
    final provider = searchScreenControllerProvider(folder);
    _subs[folder] = container.listen(provider, (_, _) {});
    return container.read(provider.notifier)..attach(_l10n);
  }

  SearchState state([String? folder]) =>
      container.read(searchScreenControllerProvider(folder));

  /// Closes the screen (the controller is disposed).
  Future<void> close(WidgetTester tester, [String? folder]) async {
    _subs.remove(folder)!.close();
    await tester.pump(const Duration(milliseconds: 1));
  }

  /// Closes every screen and lets all timers run (end of a test).
  Future<void> closeAll(WidgetTester tester) async {
    for (final s in _subs.values) {
      s.close();
    }
    _subs.clear();
    await tester.pump(const Duration(seconds: 2));
  }
}

/// A test with a [_Harness] that is closed (timers drained) at its end.
void _testWidgets(
  String description,
  Future<void> Function(WidgetTester tester, _Harness h) body,
) => testWidgets(description, (tester) async {
  final h = await _harness(tester);
  await body(tester, h);
  await h.closeAll(tester);
});

Future<_Harness> _harness(WidgetTester tester) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final db = AppDatabase(NativeDatabase.memory());
  late _SpyRecents spy;
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      searchVocabularyProvider.overrideWith((ref) async => _vocab()),
      recentSearchesRepositoryProvider.overrideWith(
        (ref) => spy = _SpyRecents(ref.watch(settingsRepositoryProvider)),
      ),
    ],
  );
  addTearDown(() async {
    container.dispose();
    await db.close();
  });
  container.listen(searchVocabularyProvider, (_, _) {});
  await container.read(searchVocabularyProvider.future);
  container.read(recentSearchesRepositoryProvider);
  return _Harness(container, spy);
}

/// Past the parse debounce.
Future<void> _parsed(WidgetTester tester) =>
    tester.pump(const Duration(milliseconds: 200));

/// Past the record delay.
Future<void> _settled(WidgetTester tester) =>
    tester.pump(const Duration(seconds: 2));

IndexQuery _unsorted(IndexQuery q) => q.copyWith(sort: FileSort.newestFirst);

/// Records a search in a fresh screen, closes it, opens the recorded one in
/// another screen (opened from [openFrom]) and checks the query is the same.
Future<RecentSearch> _roundTrip(
  WidgetTester tester,
  _Harness h,
  FutureOr<void> Function(SearchScreenController c) setUp, {
  String? recordIn,
  String? openFrom = '/elsewhere',
}) async {
  final c = h.open(recordIn);
  await setUp(c);
  await _parsed(tester);
  c.submit();
  final recorded = h.recents.added.single;
  expect(_unsorted(recorded.query), _unsorted(h.state(recordIn).query));
  await h.close(tester, recordIn);

  h.open(openFrom).openRecent(recorded);
  await _parsed(tester);
  expect(_unsorted(h.state(openFrom).query), _unsorted(recorded.query));
  // Opening (and closing) records nothing new.
  await _settled(tester);
  await h.close(tester, openFrom);
  expect(h.recents.added, hasLength(1));
  return recorded;
}

void main() {
  group('recording', () {
    _testWidgets('a ✕-demoted word is recorded as a name, not a keyword', (
      tester,
      h,
    ) async {
      final c = h.open()..edit('video');
      await _parsed(tester);
      c
        ..demote(h.state().chipTokens.single)
        ..submit();
      final r = h.recents.added.single;
      expect(r.query.nameContains, 'video');
      expect(r.query.kinds, isEmpty);
      expect(r.text, 'video');
      expect(r.demoted, {'video'});
    });

    _testWidgets('typing after a chip cancels its pending record', (
      tester,
      h,
    ) async {
      final c = h.open()..setKinds({FileKind.image});
      await tester.pump(const Duration(milliseconds: 500));
      c.edit('bea');
      await _settled(tester);
      expect(h.recents.added, isEmpty);
      c
        ..edit('beach')
        ..submit();
      expect(h.recents.added.single.query.nameContains, 'beach');
    });

    _testWidgets('a chip change records after 1.5 s of no changes; each '
        'change restarts the wait', (tester, h) async {
      final c = h.open()..setKinds({FileKind.image});
      await tester.pump(const Duration(milliseconds: 1000));
      c.setHidden(HiddenFilter.include);
      await tester.pump(const Duration(milliseconds: 1000));
      expect(h.recents.added, isEmpty);
      await tester.pump(const Duration(milliseconds: 600));
      final r = h.recents.added.single;
      expect(r.query.kinds, {FileKind.image});
      expect(r.query.hidden, HiddenFilter.include);
    });

    _testWidgets('empty searches and the same query twice in a row are not '
        'recorded', (tester, h) async {
      final c = h.open()
        ..edit('   ')
        ..submit();
      expect(h.recents.added, isEmpty);
      c
        ..setKinds({FileKind.image})
        ..setKinds(const {});
      await _settled(tester);
      expect(h.recents.added, isEmpty);

      c
        ..edit('beach')
        ..submit()
        ..submit();
      await _settled(tester);
      expect(h.recents.added, hasLength(1));
      // Closing with nothing new records nothing either.
      await h.close(tester);
      expect(h.recents.added, hasLength(1));
    });

    _testWidgets('closing the screen records the half-parsed text', (
      tester,
      h,
    ) async {
      h.open().edit('beach');
      await h.close(tester);
      expect(h.recents.added.single.query.nameContains, 'beach');
    });

    _testWidgets('a search that can match nothing is not recorded', (
      tester,
      h,
    ) async {
      h.open()
        ..setKinds({FileKind.audio})
        ..edit('video')
        ..submit();
      expect(h.state().matchesNothing, isTrue);
      expect(h.recents.added, isEmpty);
    });
  });

  group('opening a recent reproduces its query', () {
    _testWidgets('whatsapp telegram', (tester, h) async {
      final r = await _roundTrip(tester, h, (c) => c.edit('whatsapp telegram'));
      expect(r.query.sources, {SourceBucket.whatsapp, SourceBucket.telegram});
    });

    _testWidgets('a chip + a keyword + a name word', (tester, h) async {
      final r = await _roundTrip(tester, h, (c) {
        c
          ..setKinds({FileKind.image, FileKind.video})
          ..setSize(min: 1024)
          ..edit('whatsapp beach');
      });
      expect(r.query.kinds, {FileKind.image, FileKind.video});
      expect(r.query.sources, {SourceBucket.whatsapp});
      expect(r.query.nameContains, 'beach');
    });

    _testWidgets('a Source chip narrowed by typed sources', (tester, h) async {
      final r = await _roundTrip(tester, h, (c) {
        c
          ..setSource(BrowseSourceChip.telegram)
          ..edit('whatsapp telegram');
      });
      expect(r.query.sources, {SourceBucket.telegram});
    });

    _testWidgets('"Only in" a folder other than the one it is opened from', (
      tester,
      h,
    ) async {
      final r = await _roundTrip(
        tester,
        h,
        (c) => c
          ..setOnlyInFolder(only: true)
          ..edit('beach'),
        recordIn: '/sdcard/DCIM',
        openFrom: '/sdcard/Music',
      );
      expect(r.query.folderPath, '/sdcard/DCIM');
      expect(r.query.includeSubfolders, isTrue);
      expect(h.recents.added, hasLength(1));
    });

    _testWidgets('"Only in" opened from the top level', (tester, h) async {
      await _roundTrip(
        tester,
        h,
        (c) => c.setOnlyInFolder(only: true),
        recordIn: '/sdcard/DCIM',
        openFrom: null,
      );
    });

    _testWidgets('a demoted word stays a name word', (tester, h) async {
      final r = await _roundTrip(tester, h, (c) async {
        c.edit('video beach');
        await _parsed(tester);
        c.demote(h.state().chipTokens.single);
      });
      expect(r.query.kinds, isEmpty);
      expect(r.query.nameContains, 'video beach');
      expect(r.text, 'video beach');
      expect(r.demoted, {'video'});
    });

    _testWidgets("a chip-only search (title is the chips' labels)", (
      tester,
      h,
    ) async {
      final r = await _roundTrip(tester, h, (c) {
        c
          ..setKinds({FileKind.video})
          ..setHidden(HiddenFilter.only)
          ..setDate(const DateLastDays(7));
      });
      expect(r.text, '');
      expect(r.title, isNot(isEmpty));
    });

    _testWidgets('a recent from elsewhere (no text)', (tester, h) async {
      final q = IndexQuery(
        kinds: const {FileKind.document},
        extensions: const {'pdf'},
        nameContains: 'video report',
        minSizeBytes: 10,
        to: DateTime.utc(2026, 3),
      );
      h.open().openRecent(
        RecentSearch(title: 'x', query: q, at: DateTime.utc(0)),
      );
      await _parsed(tester);
      expect(_unsorted(h.state().query), q);
      expect(h.state().text, '.pdf video report');
    });
  });

  group('typed words and chips of one family', () {
    _testWidgets('typed words OR, a chip ANDs with them', (tester, h) async {
      final c = h.open()..edit('video photo');
      await _parsed(tester);
      expect(h.state().query.kinds, {FileKind.video, FileKind.image});
      c.setKinds({FileKind.image, FileKind.audio});
      expect(h.state().query.kinds, {FileKind.image});
      expect(h.state().matchesNothing, isFalse);
      c.setKinds({FileKind.audio});
      expect(h.state().matchesNothing, isTrue);
      expect(h.state().isEmpty, isFalse);
    });

    _testWidgets('sources: typed OR, the Source chip ANDs', (tester, h) async {
      final c = h.open()..edit('whatsapp telegram');
      await _parsed(tester);
      expect(h.state().query.sources, {
        SourceBucket.whatsapp,
        SourceBucket.telegram,
      });
      c.setSource(BrowseSourceChip.whatsapp);
      expect(h.state().query.sources, {SourceBucket.whatsapp});
      c.setSource(BrowseSourceChip.camera);
      expect(h.state().matchesNothing, isTrue);
      c.setSource(null);
      expect(h.state().matchesNothing, isFalse);
    });
  });

  group('debounce', () {
    _testWidgets('✕ during the debounce keeps the newest keystrokes', (
      tester,
      h,
    ) async {
      final c = h.open()..edit('video');
      await _parsed(tester);
      final video = h.state().chipTokens.single;
      c
        ..edit('video beach')
        ..demote(video);
      final s = h.state();
      expect(s.text, 'video beach');
      expect(s.chipTokens, isEmpty);
      expect(s.query.nameContains, 'video beach');
    });

    _testWidgets('the first keystroke does not show the whole library', (
      tester,
      h,
    ) async {
      final c = h.open()..edit('b');
      expect(h.state().isEmpty, isTrue);
      await _parsed(tester);
      expect(h.state().isEmpty, isFalse);
      final before = h.state().query;
      c.edit('be');
      // The previous results stay until the parse.
      expect(h.state().query, before);
      expect(h.state().isEmpty, isFalse);
    });
  });

  test('dayBefore is calendar arithmetic (DST days, year start)', () {
    for (final (end, day) in [
      // EU DST starts 2026-03-29, ends 2026-10-25.
      (DateTime(2026, 3, 30), DateTime(2026, 3, 29)),
      (DateTime(2026, 3, 29), DateTime(2026, 3, 28)),
      (DateTime(2026, 10, 26), DateTime(2026, 10, 25)),
      // US DST starts 2026-03-08, ends 2026-11-01.
      (DateTime(2026, 3, 9), DateTime(2026, 3, 8)),
      (DateTime(2026, 11, 2), DateTime(2026, 11)),
      (DateTime(2026), DateTime(2025, 12, 31)),
    ]) {
      expect(dayBefore(end), day, reason: '$end');
      // Stored bounds are UTC instants of local midnights.
      expect(dayBefore(end.toUtc()), day, reason: '$end (utc)');
    }
  });

  test('a date range chip survives dateBounds → dayBefore on DST days', () {
    for (final day in [
      DateTime(2026, 3, 28),
      DateTime(2026, 3, 29),
      DateTime(2026, 10, 25),
      DateTime(2026, 3, 8),
      DateTime(2026, 11),
    ]) {
      final (from: _, :to) = dateBounds(DateRange(day, day), day);
      expect(dayBefore(to!), day, reason: '$day');
    }
  });
}
