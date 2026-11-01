import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/features/tags/data/tag_providers.dart';

/// Picks one of the tags on [fileIds] (with how many of them have it) to
/// remove (TASK-B9). Null when dismissed.
Future<int?> showTagRemoveSheet(BuildContext context, List<String> fileIds) =>
    showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _TagRemoveSheet(fileIds: fileIds),
    );

class _TagRemoveSheet extends ConsumerStatefulWidget {
  const new({required this.fileIds});

  final List<String> fileIds;

  @override
  ConsumerState<_TagRemoveSheet> createState() => _TagRemoveSheetState();
}

class _TagRemoveSheetState extends ConsumerState<_TagRemoveSheet> {
  late final Future<Map<int, int>> _counts = ref
      .read(tagRepositoryProvider)
      .tagCountsAmong(widget.fileIds);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tags = ref.watch(tagsByIdProvider).value ?? const {};
    return FutureBuilder<Map<int, int>>(
      future: _counts,
      builder: (context, snap) {
        final counts = snap.data;
        final Widget body;
        if (snap.hasError) {
          body = Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.tagWriteError),
          );
        } else if (counts == null) {
          body = const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        } else {
          final present = [
            for (final t in tags.values)
              if ((counts[t.id] ?? 0) > 0) t,
          ];
          body = present.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.tagRemoveNone),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final t in present)
                      ListTile(
                        leading: Icon(Icons.label, color: Color(t.color)),
                        title: Text(t.name),
                        trailing: Text(
                          l10n.collectionsFileCount(counts[t.id] ?? 0),
                        ),
                        onTap: () => Navigator.of(context).pop(t.id),
                      ),
                  ],
                );
        }
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
                  child: Text(
                    l10n.tagRemoveTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                body,
              ],
            ),
          ),
        );
      },
    );
  }
}
