import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/platform/permissions/storage_access_provider.dart';
import 'package:kfm/features/browse/domain/browse_source_chip.dart';
import 'package:kfm/features/browse/ui/browse_controller.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

extension BrowseSourceLabel on BrowseSourceChip {
  String label(AppLocalizations l10n) => switch (this) {
    BrowseSourceChip.camera => l10n.browseSourceCamera,
    BrowseSourceChip.screenshots => l10n.browseSourceScreenshots,
    BrowseSourceChip.whatsapp => l10n.browseSourceWhatsapp,
    BrowseSourceChip.snapchat => l10n.browseSourceSnapchat,
    BrowseSourceChip.downloads => l10n.browseSourceDownloads,
    BrowseSourceChip.videos => l10n.browseSourceVideos,
    BrowseSourceChip.panoramas => l10n.browseSourcePanoramas,
    BrowseSourceChip.screenRecordings => l10n.browseSourceScreenRecordings,
    BrowseSourceChip.expertRaw => l10n.browseSourceExpertRaw,
    BrowseSourceChip.gifs => l10n.browseSourceGifs,
    BrowseSourceChip.collages => l10n.browseSourceCollages,
    BrowseSourceChip.clippedImages => l10n.browseSourceClippedImages,
    BrowseSourceChip.liveMessages => l10n.browseSourceLiveMessages,
    BrowseSourceChip.videoCaptures => l10n.browseSourceVideoCaptures,
    BrowseSourceChip.telegram => l10n.browseSourceTelegram,
    BrowseSourceChip.instagram => l10n.browseSourceInstagram,
    BrowseSourceChip.other => l10n.browseSourceOther,
    BrowseSourceChip.hidden => l10n.browseSourceHidden,
  };
}

extension BrowseCollectionTitle on BrowseCollection {
  String title(AppLocalizations l10n) => switch (this) {
    SourceCollection(:final source) => source.label(l10n),
    RecentCollection(:final search) => search.title,
  };
}

/// Type chips in display order.
const List<FileKind> browseKinds = [
  FileKind.image,
  FileKind.video,
  FileKind.audio,
  FileKind.document,
  FileKind.archive,
  FileKind.other,
];

String kindLabel(AppLocalizations l10n, FileKind kind) => switch (kind) {
  FileKind.image => l10n.browseKindImages,
  FileKind.video => l10n.browseKindVideos,
  FileKind.audio => l10n.browseKindAudio,
  FileKind.document => l10n.browseKindDocuments,
  FileKind.archive => l10n.browseKindArchives,
  FileKind.other => l10n.browseKindOther,
};

/// Type chips over [scope] (a page's files without a type): single-select,
/// long-press adds a second kind, "All" clears. Kinds without visible files
/// are hidden (iOS: images/videos only); without All files access the
/// non-media ones stay, so tapping them explains why.
class KindChipsRow extends ConsumerWidget {
  const new({
    required this.scope,
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final IndexQuery scope;
  final Set<FileKind> selected;
  final void Function(FileKind? kind, {bool add}) onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canSeeAll =
        ref.watch(storageAccessControllerProvider).value?.canSeeAllFiles ??
        false;
    final l10n = context.l10n;
    final spacing = context.tokens.spacing;
    final chips = <Widget>[
      Padding(
        padding: EdgeInsetsDirectional.only(end: spacing),
        child: ChoiceChip(
          label: Text(l10n.browseKindAll),
          selected: selected.isEmpty,
          onSelected: (_) => onSelect(null),
        ),
      ),
    ];
    for (final kind in browseKinds) {
      final isSelected = selected.contains(kind);
      final count = ref.watch(
        browseCountProvider(scope.copyWith(kinds: {kind})),
      );
      final shown =
          isSelected ||
          (count.value ?? 0) > 0 ||
          (!canSeeAll && !mediaKinds.contains(kind));
      if (!shown) continue;
      chips.add(
        Padding(
          padding: EdgeInsetsDirectional.only(end: spacing),
          child: GestureDetector(
            onLongPress: () => onSelect(kind, add: true),
            child: ChoiceChip(
              label: Text(kindLabel(l10n, kind)),
              selected: isSelected,
              onSelected: (_) => onSelect(kind),
            ),
          ),
        ),
      );
    }
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsetsDirectional.symmetric(horizontal: spacing * 2),
        children: chips,
      ),
    );
  }
}
