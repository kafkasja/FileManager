import 'dart:convert';

import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/features/ai_labels/data/ai_labels_providers.dart';
import 'package:kfm/features/search/data/search_vocabulary.dart';
import 'package:kfm/features/search/domain/search_keyword.dart';
import 'package:kfm/features/similar/ui/similar_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'label_keywords.g.dart';

/// The family prefix of content words (TASK-C4).
const String kLabelPrefix = 'label';

/// `label:blurry` (C2's blur score, not an AI label).
const String kBlurryArg = 'blurry';

/// Category words → the labels they also match (language-neutral ids).
const String kLabelExpansionsAsset = 'assets/search/label_expansions.json';

/// An AI label keyword (`label:cat`), not `label:blurry`: these depend on
/// C3's labeling, `blurry` only on C2.
bool isAiLabelKeyword(SearchKeyword k) =>
    k.id.startsWith('$kLabelPrefix:') && k.id != '$kLabelPrefix:$kBlurryArg';

/// `label:<vocabulary label>` → an AI label term (with its expansions, OR'ed),
/// `label:blurry` → C2's blurry photos. Typed words come from the term files
/// like every family (B8).
@Riverpod(keepAlive: true)
SearchKeywordFamily labelKeywordFamily(Ref ref) {
  final vocab = ref.watch(labelVocabularyProvider);
  final expand = ref.watch(labelExpansionsProvider).value ?? const {};
  final blurThreshold =
      ref.watch(similarBlurThresholdProvider).value ??
      AppSettings.similarBlurThreshold.defaultValue;
  return SearchKeywordFamily(
    prefix: kLabelPrefix,
    resolve: (arg) {
      if (arg == kBlurryArg) {
        return SearchKeyword(
          id: '$kLabelPrefix:$kBlurryArg',
          chipLabel: (l) => l.searchChipBlurry,
          apply: (q) =>
              q.copyWith(blurryOnly: true, blurThreshold: () => blurThreshold),
        );
      }
      if (!vocab.contains(arg)) return null;
      final term = Set<String>.unmodifiable(expand[arg] ?? {arg});
      return SearchKeyword(
        id: '$kLabelPrefix:$arg',
        chipLabel: (l) => l.searchChipLabel(labelDisplayWord(arg)),
        apply: (q) => q.copyWith(labelTerms: [...q.labelTerms, term]),
      );
    },
  );
}

/// The word a chip shows for a label id's arg (`color:blue` → `blue`).
/// English label words until L2 gives chips their own strings.
String labelDisplayWord(String arg) {
  final colon = arg.indexOf(':');
  return colon < 0 ? arg : arg.substring(colon + 1);
}

/// `assets/search/label_expansions.json`, loaded once. A parse error is an
/// AsyncError (rule 8); the family then works without expansions.
@Riverpod(keepAlive: true)
Future<Map<String, Set<String>>> labelExpansions(Ref ref) async =>
    parseLabelExpansions(
      await ref
          .watch(searchAssetBundleProvider)
          .loadString(kLabelExpansionsAsset, cache: false),
    );

/// `{"expansions": {"animal": ["animal", "cat", …], …}}`. Every set
/// contains its own key. Throws [FormatException] on another shape.
Map<String, Set<String>> parseLabelExpansions(String text) {
  final json = jsonDecode(text);
  if (json is! Map<String, Object?>) {
    throw const FormatException('expansions file is not an object');
  }
  final expansions = json['expansions'];
  if (expansions is! Map<String, Object?>) {
    throw const FormatException('missing "expansions" object');
  }
  return Map.unmodifiable({
    for (final MapEntry(:key, :value) in expansions.entries)
      key: switch (value) {
        final List<Object?> labels => Set<String>.unmodifiable({
          key,
          for (final l in labels)
            if (l is String)
              l
            else
              throw FormatException('label of "$key" is not a string'),
        }),
        _ => throw FormatException('"$key" is not a list'),
      },
  });
}
