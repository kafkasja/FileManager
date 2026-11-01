import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/index/source_rule.dart';
import 'package:kfm/features/filters/data/filter_query.dart';
import 'package:kfm/features/filters/domain/file_filter.dart';
import 'package:kfm/features/search/domain/search_keyword.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// B8's keyword families. Typed words come only from term files
/// (`assets/search/terms_<lang>.json`); these just turn concept ids into
/// filters.

/// `type:image|video|audio|document|archive|other` → that kind (several
/// type words are OR'ed).
const typeKeywords = SearchKeywordFamily(prefix: 'type', resolve: _type);

/// `source:<bucket>` (B1's [SourceBucket], `other` = none) and
/// `source:panorama`.
const sourceKeywords = SearchKeywordFamily(prefix: 'source', resolve: _source);

/// `attr:hidden|tiny|large|today|week`.
const attributeKeywords = SearchKeywordFamily(
  prefix: 'attr',
  resolve: _attribute,
);

/// Size bounds of `attr:tiny` / `attr:large`.
const int kTinyMaxBytes = 10 * 1024;
const int kLargeMinBytes = 100 * 1024 * 1024;

SearchKeyword? _type(String arg) {
  final kind = switch (arg) {
    'image' => FileKind.image,
    'video' => FileKind.video,
    'audio' => FileKind.audio,
    'document' => FileKind.document,
    'archive' => FileKind.archive,
    'other' => FileKind.other,
    _ => null,
  };
  if (kind == null) return null;
  return SearchKeyword(
    id: 'type:$arg',
    chipLabel: (l10n) => l10n.searchKwType(_kindName(l10n, kind)),
    apply: (q) => q.copyWith(kinds: {...q.kinds, kind}),
  );
}

String _kindName(AppLocalizations l10n, FileKind k) => switch (k) {
  FileKind.image => l10n.browseKindImages,
  FileKind.video => l10n.browseKindVideos,
  FileKind.audio => l10n.browseKindAudio,
  FileKind.document => l10n.browseKindDocuments,
  FileKind.archive => l10n.browseKindArchives,
  FileKind.other => l10n.browseKindOther,
};

SearchKeyword? _source(String arg) {
  if (arg == 'panorama') {
    return SearchKeyword(
      id: 'source:panorama',
      chipLabel: (l10n) => l10n.searchKwSource(l10n.browseSourcePanoramas),
      apply: (q) => q.copyWith(panoramaOnly: true),
    );
  }
  final bucket = switch (arg) {
    'camera' => SourceBucket.camera,
    'screenshots' => SourceBucket.screenshots,
    'screenrecordings' => SourceBucket.screenRecordings,
    'whatsapp' => SourceBucket.whatsapp,
    'snapchat' => SourceBucket.snapchat,
    'telegram' => SourceBucket.telegram,
    'instagram' => SourceBucket.instagram,
    'downloads' => SourceBucket.downloads,
    'expertraw' => SourceBucket.expertRaw,
    'gifs' => SourceBucket.gifs,
    'collages' => SourceBucket.collages,
    'clippedimages' => SourceBucket.clippedImages,
    'livemessages' => SourceBucket.liveMessages,
    'videocaptures' => SourceBucket.videoCaptures,
    'other' => SourceBucket.none,
    _ => null,
  };
  if (bucket == null) return null;
  return SearchKeyword(
    id: 'source:$arg',
    chipLabel: (l10n) => l10n.searchKwSource(_sourceName(l10n, bucket)),
    apply: (q) => q.copyWith(sources: {...q.sources, bucket}),
  );
}

String _sourceName(AppLocalizations l10n, SourceBucket b) => switch (b) {
  SourceBucket.none => l10n.browseSourceOther,
  SourceBucket.camera => l10n.browseSourceCamera,
  SourceBucket.screenshots => l10n.browseSourceScreenshots,
  SourceBucket.screenRecordings => l10n.browseSourceScreenRecordings,
  SourceBucket.whatsapp => l10n.browseSourceWhatsapp,
  SourceBucket.snapchat => l10n.browseSourceSnapchat,
  SourceBucket.telegram => l10n.browseSourceTelegram,
  SourceBucket.instagram => l10n.browseSourceInstagram,
  SourceBucket.downloads => l10n.browseSourceDownloads,
  SourceBucket.expertRaw => l10n.browseSourceExpertRaw,
  SourceBucket.gifs => l10n.browseSourceGifs,
  SourceBucket.collages => l10n.browseSourceCollages,
  SourceBucket.clippedImages => l10n.browseSourceClippedImages,
  SourceBucket.liveMessages => l10n.browseSourceLiveMessages,
  SourceBucket.videoCaptures => l10n.browseSourceVideoCaptures,
};

SearchKeyword? _attribute(String arg) => switch (arg) {
  'hidden' => SearchKeyword(
    id: 'attr:hidden',
    chipLabel: (l10n) => l10n.searchKwHidden,
    apply: (q) => q.copyWith(hidden: HiddenFilter.only),
  ),
  'tiny' => SearchKeyword(
    id: 'attr:tiny',
    chipLabel: (l10n) => l10n.searchKwTiny,
    apply: (q) => q.copyWith(maxSizeBytes: () => kTinyMaxBytes),
  ),
  'large' => SearchKeyword(
    id: 'attr:large',
    chipLabel: (l10n) => l10n.searchKwLarge,
    apply: (q) => q.copyWith(minSizeBytes: () => kLargeMinBytes),
  ),
  'today' => SearchKeyword(
    id: 'attr:today',
    chipLabel: (l10n) => l10n.searchKwToday,
    apply: (q) => _lastDays(q, 1),
  ),
  'week' => SearchKeyword(
    id: 'attr:week',
    chipLabel: (l10n) => l10n.searchKwWeek,
    apply: (q) => _lastDays(q, 7),
  ),
  _ => null,
};

/// Evaluated when the query is built, so "today" follows the clock.
IndexQuery _lastDays(IndexQuery q, int days) {
  final (:from, to: _) = dateBounds(DateLastDays(days), DateTime.now());
  return q.copyWith(from: () => from);
}
