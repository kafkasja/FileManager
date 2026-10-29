import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/files/file_query.dart';
import 'package:kfm/features/browse/ui/browse_controller.dart';
import 'package:kfm/l10n/generated/app_localizations.dart';

/// "Largest first", "A–Z"… for the label under the toolbar (TASK-B2).
String sortLabel(AppLocalizations l10n, FileSort sort) =>
    switch ((sort.field, sort.descending)) {
      (FileSortField.date, true) => l10n.browseSortNewestFirst,
      (FileSortField.date, false) => l10n.browseSortOldestFirst,
      (FileSortField.size, true) => l10n.browseSortLargestFirst,
      (FileSortField.size, false) => l10n.browseSortSmallestFirst,
      (FileSortField.name, false) => l10n.browseSortNameAsc,
      (FileSortField.name, true) => l10n.browseSortNameDesc,
    };

/// Picking a field uses its natural direction: newest, largest, A–Z.
FileSort naturalSort(FileSortField field) =>
    FileSort(field, descending: field != FileSortField.name);

Future<void> showSortSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (_) => const SortSheet(),
);

/// Date / Size / Name. Tapping the active row flips the direction.
class SortSheet extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sort = ref.watch(browseViewControllerProvider.select((v) => v.sort));
    final controller = ref.read(browseViewControllerProvider.notifier);
    Widget row(FileSortField field, String label) {
      final active = sort.field == field;
      return ListTile(
        title: Text(label),
        subtitle: active ? Text(sortLabel(l10n, sort)) : null,
        selected: active,
        trailing: active
            ? Icon(sort.descending ? Icons.arrow_downward : Icons.arrow_upward)
            : null,
        onTap: () => controller.setSort(
          active
              ? FileSort(field, descending: !sort.descending)
              : naturalSort(field),
        ),
      );
    }

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text(
              l10n.browseSortTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          row(FileSortField.date, l10n.browseSortDate),
          row(FileSortField.size, l10n.browseSortSize),
          row(FileSortField.name, l10n.browseSortName),
        ],
      ),
    );
  }
}
