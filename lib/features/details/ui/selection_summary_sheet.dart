import 'package:flutter/material.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/features/browse/ui/widgets/sources_row.dart';
import 'package:kfm/features/details/ui/file_details_sheet.dart';
import 'package:kfm/features/selection/ui/selection_actions.dart';

/// Totals of a multi-selection (TASK-B10). Pure: from the FileRefs only.
@immutable
class SelectionSummary {
  const new({
    required this.count,
    required this.totalBytes,
    required this.kinds,
    required this.folderCount,
    this.oldest,
    this.newest,
  });

  factory of(List<FileRef> files) {
    final kinds = <FileKind, int>{};
    final folders = <String>{};
    var total = 0;
    DateTime? oldest;
    DateTime? newest;
    for (final f in files) {
      kinds[f.kind] = (kinds[f.kind] ?? 0) + 1;
      folders.add(f.folderPath);
      total += f.sizeBytes;
      final d = f.sortDate;
      if (d.millisecondsSinceEpoch > 0) {
        if (oldest == null || d.isBefore(oldest)) oldest = d;
        if (newest == null || d.isAfter(newest)) newest = d;
      }
    }
    return SelectionSummary(
      count: files.length,
      totalBytes: total,
      kinds: kinds,
      folderCount: folders.length,
      oldest: oldest,
      newest: newest,
    );
  }

  final int count;
  final int totalBytes;
  final Map<FileKind, int> kinds;
  final int folderCount;
  final DateTime? oldest;
  final DateTime? newest;
}

/// B10's "Details" in the selection bar's More menu: one file → the full
/// details sheet, more → [showSelectionSummary]. Index rows only: needs no
/// All files access and no native call.
final SelectionAction detailsSelectionAction = SelectionAction(
  id: 'b10.details',
  order: 90,
  label: (c) => c.l10n.selectionActionDetails,
  icon: Icons.info_outline,
  run: (context, ref, ids) async {
    final files = await ref.read(mediaIndexDaoProvider).byIds(ids);
    if (!context.mounted || files.isEmpty) return;
    if (files.length == 1) {
      await showFileDetails(context, files.single);
    } else {
      await showSelectionSummary(
        context,
        files,
        missing: ids.length - files.length,
      );
    }
  },
);

Future<void> showSelectionSummary(
  BuildContext context,
  List<FileRef> files, {
  int missing = 0,
}) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  useSafeArea: true,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => SelectionSummaryView(
    summary: SelectionSummary.of(files),
    missing: missing,
  ),
);

class SelectionSummaryView extends StatelessWidget {
  const new({required this.summary, this.missing = 0, super.key});

  final SelectionSummary summary;
  final int missing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final spacing = context.tokens.spacing;
    final s = summary;
    Widget fact(String label, String value) => Padding(
      padding: EdgeInsetsDirectional.symmetric(vertical: spacing / 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
    final kinds = [
      for (final k in FileKind.values)
        if (s.kinds[k] case final n?)
          l10n.detailsSummaryKindCount(kindLabel(l10n, k), n),
    ];
    return SingleChildScrollView(
      padding: EdgeInsetsDirectional.fromSTEB(
        spacing * 2,
        0,
        spacing * 2,
        spacing * 3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.detailsSummaryTitle(s.count),
            style: theme.textTheme.titleLarge,
          ),
          SizedBox(height: spacing),
          fact(
            l10n.detailsSummaryTotal,
            formatBytes(s.totalBytes, locale: locale),
          ),
          fact(l10n.detailsSummaryKinds, kinds.join('\n')),
          if (s.oldest case final d?)
            fact(l10n.detailsSummaryOldest, formatDate(d, locale: locale)),
          if (s.newest case final d?)
            fact(l10n.detailsSummaryNewest, formatDate(d, locale: locale)),
          fact(
            l10n.detailsSummaryFolders,
            l10n.detailsSummaryFolderCount(s.folderCount),
          ),
          if (missing > 0)
            Padding(
              padding: EdgeInsetsDirectional.only(top: spacing),
              child: Text(
                l10n.detailsSummaryMissing(missing),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
