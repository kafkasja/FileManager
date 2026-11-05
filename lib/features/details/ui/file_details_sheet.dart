import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kfm/app/form_factor.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/app/scroll_to_top.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/files/file_kind_resolver.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/source_rule.dart';
import 'package:kfm/core/thumbs/thumbnail.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/desktop/browse/desktop_browse_controller.dart';
import 'package:kfm/features/browse/domain/browse_source_chip.dart';
import 'package:kfm/features/browse/ui/browse_controller.dart';
import 'package:kfm/features/details/data/file_details_repository.dart';
import 'package:kfm/features/details/domain/file_details.dart';
import 'package:kfm/features/details/domain/known_files.dart';
import 'package:kfm/features/reviewed/data/reviewed_repository.dart';
import 'package:kfm/features/search/data/builtin_keywords.dart';
import 'package:kfm/features/tags/data/tag_providers.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// Opens the details sheet for [file] (TASK-B10): ⋮ menu, viewer ⓘ and
/// the selection bar. Over everything (root navigator), so it also works
/// from the fullscreen viewer.
Future<void> showFileDetails(BuildContext context, FileRef file) =>
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.3,
        builder: (context, scroll) =>
            FileDetailsView(file: file, scrollController: scroll),
      ),
    );

/// The sheet's content. The FileRef's own fields show at once; the rest
/// (MediaStore, EXIF, owner app) loads under a small spinner.
class FileDetailsView extends ConsumerWidget {
  const new({required this.file, this.scrollController, super.key});

  final FileRef file;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(fileDetailsProvider(file));
    final d = async.value;
    final gone = d?.exists == false;
    final spacing = context.tokens.spacing;
    return Semantics(
      label: l10n.detailsSheetLabel,
      explicitChildNodes: true,
      child: ListView(
        controller: scrollController,
        padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, spacing * 3),
        children: [
          _Header(file: file),
          if (async.isLoading)
            Padding(
              padding: EdgeInsetsDirectional.all(spacing),
              child: Center(
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    semanticsLabel: l10n.detailsLoading,
                  ),
                ),
              ),
            ),
          if (gone) _Notice(text: l10n.detailsGone, error: true),
          if (async.hasError || (d?.partial ?? false))
            _Notice(text: l10n.detailsPartial),
          if (d?.explanation case final k?) _WhatIsThis(kind: k),
          if (d != null) _CameFrom(details: d),
          _Where(file: file, details: d, gone: gone),
          _FileFacts(file: file, details: d),
          _InKfm(file: file),
          if (d?.owner case final OwnerApp owner when owner.installed && !gone)
            Padding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: spacing * 2,
                vertical: spacing,
              ),
              child: OutlinedButton.icon(
                icon: const Icon(Icons.info_outline),
                label: Text(l10n.detailsAppInfo),
                onPressed: () => unawaited(_openAppInfo(context, ref, owner)),
              ),
            ),
        ],
      ),
    );
  }

  static Future<void> _openAppInfo(
    BuildContext context,
    WidgetRef ref,
    OwnerApp owner,
  ) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final failed = context.l10n.detailsAppInfoFailed;
    var ok = false;
    try {
      ok = await ref
          .read(fileDetailsRepositoryProvider)
          .openAppDetails(owner.packageName);
    } on Object {
      ok = false;
    }
    if (!ok) messenger?.showSnackBar(SnackBar(content: Text(failed)));
  }
}

/// Thumbnail (or type icon) and the full name, wrapping anywhere.
class _Header extends StatelessWidget {
  const new({required this.file});

  final FileRef file;

  @override
  Widget build(BuildContext context) {
    final spacing = context.tokens.spacing;
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        spacing * 2,
        0,
        spacing * 2,
        spacing,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(context.tokens.radius / 2),
            child: SizedBox.square(dimension: 64, child: Thumbnail(file: file)),
          ),
          SizedBox(width: spacing * 2),
          Expanded(
            child: SelectableText(
              file.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const new({required this.text, this.error = false});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final spacing = context.tokens.spacing;
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: spacing * 2,
        vertical: spacing / 2,
      ),
      child: Row(
        children: [
          Icon(
            error ? Icons.error_outline : Icons.info_outline,
            size: 18,
            color: error ? scheme.error : scheme.onSurfaceVariant,
          ),
          SizedBox(width: spacing),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: error ? scheme.error : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final spacing = context.tokens.spacing;
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(
        spacing * 2,
        spacing * 2,
        spacing * 2,
        spacing / 2,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}

/// A "label: value" line; hidden by the callers when there's no value.
class _Fact extends StatelessWidget {
  const new({
    required this.label,
    required this.value,
    this.tooltip,
    this.trailing,
  });

  final String label;
  final String value;
  final String? tooltip;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.tokens.spacing;
    Widget valueText = SelectableText(value, style: theme.textTheme.bodyMedium);
    if (tooltip case final t?) {
      valueText = Tooltip(message: t, child: valueText);
    }
    return Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: spacing * 2,
        vertical: spacing / 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: valueText),
          ?trailing,
        ],
      ),
    );
  }
}

class _WhatIsThis extends StatelessWidget {
  const new({required this.kind});

  final KnownFileKind kind;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final spacing = context.tokens.spacing;
    final hint = switch (kind.deletable) {
      DeletableHint.usually => l10n.detailsHintUsually,
      DeletableHint.careful => l10n.detailsHintCareful,
      DeletableHint.unknown => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(l10n.detailsWhatIsThis),
        Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: spacing * 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: spacing / 2,
            children: [
              Text(kind.title, style: theme.textTheme.titleMedium),
              Text(kind.body),
              if (hint != null)
                Text(
                  hint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CameFrom extends StatefulWidget {
  const new({required this.details});

  final FileDetails details;

  @override
  State<_CameFrom> createState() => _CameFromState();
}

class _CameFromState extends State<_CameFrom> {
  bool _fullUrl = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final d = widget.details;
    final owner = d.owner;
    final bucket = d.pathApp?.bucket ?? SourceBucket.none;
    final download = d.downloadUri;
    final downloadHost = hostOf(download);
    final refererHost = hostOf(d.refererUri);
    final camera = d.exif?.camera;
    final editor = d.exif?.editor;
    final rows = <Widget>[
      if (owner != null)
        ListTile(
          leading: switch (owner.icon) {
            final icon? => Image.memory(
              icon,
              width: 32,
              height: 32,
              gaplessPlayback: true,
            ),
            null => const Icon(Icons.apps),
          },
          title: Text(
            l10n.detailsSavedBy(
              owner.label ?? l10n.detailsNotInstalled(owner.packageName),
            ),
          ),
          subtitle: switch ((owner.label, owner.installed)) {
            (null, _) => null,
            (_, false) => Text(l10n.detailsNotInstalled(owner.packageName)),
            (_, true) => Text(owner.packageName),
          },
        )
      else if (bucket != SourceBucket.none)
        ListTile(
          leading: const Icon(Icons.folder_special_outlined),
          title: Text(
            l10n.detailsInSourceFolder(sourceBucketName(l10n, bucket)),
          ),
        ),
      if (downloadHost != null)
        ListTile(
          leading: const Icon(Icons.download_outlined),
          title: Text(l10n.detailsDownloadedFrom(downloadHost)),
          subtitle: _fullUrl
              ? SelectableText(download!)
              : Text(l10n.detailsShowFullAddress),
          onTap: () => setState(() => _fullUrl = !_fullUrl),
        ),
      if (refererHost != null && refererHost != downloadHost)
        ListTile(
          leading: const Icon(Icons.link),
          title: Text(l10n.detailsLinkedFrom(refererHost)),
          subtitle: _fullUrl ? SelectableText(d.refererUri!) : null,
          onTap: () => setState(() => _fullUrl = !_fullUrl),
        ),
      if (camera != null)
        ListTile(
          leading: const Icon(Icons.photo_camera_outlined),
          title: Text(l10n.detailsTakenWith(camera)),
        ),
      if (editor != null)
        ListTile(
          leading: const Icon(Icons.auto_fix_high_outlined),
          title: Text(l10n.detailsEditedWith(editor)),
        ),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_SectionTitle(l10n.detailsCameFrom), ...rows],
    );
  }
}

class _Where extends ConsumerWidget {
  const new({required this.file, required this.details, required this.gone});

  final FileRef file;
  final FileDetails? details;
  final bool gone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final remote = file.origin == FileOrigin.remote;
    final storage = switch (details?.volumeKind) {
      VolumeKind.internal => l10n.detailsStorageInternal,
      VolumeKind.removable =>
        details?.volumeLabel ?? l10n.detailsStorageRemovable,
      _ => null,
    };
    final spacing = context.tokens.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(l10n.detailsWhere),
        if (!remote)
          _Fact(
            label: l10n.detailsPath,
            value: file.path,
            trailing: IconButton(
              tooltip: l10n.detailsCopyPath,
              icon: const Icon(Icons.copy_outlined),
              onPressed: () => unawaited(_copy(context)),
            ),
          ),
        if (storage != null) _Fact(label: l10n.detailsStorage, value: storage),
        Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: spacing * 2),
          child: Wrap(
            spacing: spacing,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (file.hidden)
                Chip(
                  avatar: const Icon(Icons.visibility_off_outlined),
                  label: Text(l10n.detailsHidden),
                ),
              if (!remote)
                TextButton.icon(
                  icon: const Icon(Icons.folder_open_outlined),
                  label: Text(l10n.detailsOpenFolder),
                  onPressed: gone
                      ? null
                      : () => openFolderInBrowse(
                          context,
                          file.folderPath,
                          highlightId: file.id,
                        ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _copy(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final copied = context.l10n.detailsPathCopied;
    await Clipboard.setData(ClipboardData(text: file.path));
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(copied)));
  }
}

/// Closes the sheet (and a viewer under it), switches to Browse and opens
/// [folder] in folder mode (B1). E4: [highlightId] = scroll to that file
/// and flash it once.
void openFolderInBrowse(
  BuildContext context,
  String folder, {
  String? highlightId,
}) {
  final container = ProviderScope.containerOf(context, listen: false);
  final router = GoRouter.of(context);
  Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
  // PL3: the desktop app opens the folder in its Explorer-like Browse.
  if (container.read(formFactorProvider).isDesktop) {
    container.read(desktopBrowseControllerProvider.notifier).open(folder);
    router.go(AppRoutes.browse);
    return;
  }
  router.go(AppRoutes.browse);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    container.read(browseViewControllerProvider.notifier)
      ..setLayout(BrowseLayout.folders)
      ..openFolder(folder);
    container.read(browseHighlightProvider.notifier).show(highlightId);
  });
}

class _FileFacts extends StatelessWidget {
  const new({required this.file, required this.details});

  final FileRef file;
  final FileDetails? details;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    String date(DateTime d) =>
        DateFormat.yMMMd(locale).add_jm().format(d.toLocal());
    final ext = extensionOf(file.name);
    final mime = details?.mimeType ?? file.mimeType;
    final type = switch ((mime, ext)) {
      (final String m, '') => m,
      (final String m, final e) => l10n.detailsTypeValue(m, e),
      (null, '') => l10n.detailsTypeUnknownNoExt,
      (null, final e) => l10n.detailsTypeUnknown(e),
    };
    final (w, h, ms) = (file.width, file.height, file.durationMs);
    final exif = details?.exif;
    final added = details?.addedAt;
    final taken = file.takenAt;
    final settings = exif == null ? null : _settingsLine(l10n, exif, locale);
    final place = details?.placeName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(l10n.detailsFileSection),
        _Fact(label: l10n.detailsType, value: type),
        _Fact(
          label: l10n.detailsSize,
          value: formatBytes(file.sizeBytes, locale: locale),
          tooltip: l10n.detailsBytes(file.sizeBytes),
        ),
        if (file.modifiedAt.millisecondsSinceEpoch > 0)
          _Fact(label: l10n.detailsModified, value: date(file.modifiedAt)),
        if (added != null) _Fact(label: l10n.detailsAdded, value: date(added)),
        if (taken != null && taken.millisecondsSinceEpoch > 0)
          _Fact(label: l10n.detailsTaken, value: date(taken)),
        if (w != null && h != null && w > 0 && h > 0)
          _Fact(
            label: l10n.detailsDimensions,
            value: l10n.previewDimensions(w, h),
          ),
        if (ms != null && ms > 0)
          _Fact(
            label: l10n.detailsDuration,
            value: formatDuration(Duration(milliseconds: ms)),
          ),
        if (settings != null)
          _Fact(label: l10n.detailsCameraSettings, value: settings),
        if (exif?.lens case final lens?)
          _Fact(label: l10n.detailsLens, value: lens),
        if (exif?.description ?? exif?.userComment case final text?)
          _Fact(label: l10n.detailsDescription, value: text),
        if (exif != null && exif.hasLocation)
          _Fact(
            label: l10n.detailsLocation,
            value: [
              ?place,
              l10n.detailsLatLng(
                exif.lat!.toStringAsFixed(5),
                exif.lng!.toStringAsFixed(5),
              ),
            ].join('\n'),
          ),
      ],
    );
  }

  static String? _settingsLine(
    AppLocalizations l10n,
    ExifDetails e,
    String locale,
  ) {
    if (!e.hasSettings) return null;
    final number = NumberFormat('0.#', locale);
    final exposure = e.exposureSeconds;
    return [
      if (e.iso case final iso?) l10n.detailsIso(iso),
      if (exposure != null)
        l10n.detailsExposure(
          exposure < 1 && exposure > 0
              ? '1/${(1 / exposure).round()}'
              : number.format(exposure),
        ),
      if (e.fNumber case final f?) l10n.detailsFNumber(number.format(f)),
      if (e.focalLengthMm case final mm?)
        l10n.detailsFocalLength(number.format(mm)),
    ].join(' · ');
  }
}

/// Tags, favorite and reviewed state (P2/B9/P7), when present.
class _InKfm extends ConsumerWidget {
  const new({required this.file});

  final FileRef file;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final tagIds = ref.watch(fileTagIdsProvider(file.id)).value ?? const {};
    final tags = ref.watch(tagsByIdProvider).value ?? const {};
    final favorite =
        ref.watch(favoriteIdsProvider).value?.contains(file.id) ?? false;
    final labels = ref.watch(reviewedLabelsForProvider(file)).value ?? const [];
    final names = [
      for (final id in tagIds)
        if (tags[id] case final t?) t.name,
    ]..sort();
    final reviewed = labels.isEmpty
        ? null
        : labels
              .map((l) => l.reviewedAt)
              .reduce((a, b) => a.isAfter(b) ? a : b);
    if (names.isEmpty && !favorite && reviewed == null) {
      return const SizedBox.shrink();
    }
    final spacing = context.tokens.spacing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(l10n.detailsInKfm),
        if (names.isNotEmpty)
          _Fact(label: l10n.detailsTags, value: names.join(', ')),
        Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: spacing * 2),
          child: Wrap(
            spacing: spacing,
            children: [
              if (favorite)
                Chip(
                  avatar: const Icon(Icons.star),
                  label: Text(l10n.detailsFavorite),
                ),
              if (reviewed != null)
                Chip(
                  avatar: const Icon(Icons.check_circle_outline),
                  label: Text(
                    l10n.detailsReviewed(formatDate(reviewed, locale: locale)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
