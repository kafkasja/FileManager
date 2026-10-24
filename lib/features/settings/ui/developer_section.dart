import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/index/index_query.dart';
import 'package:kfm/core/thumbs/thumbnail.dart';
import 'package:kfm/core/utils/format.dart';

/// Debug builds only: index size, full rescan, and the first 200 indexed
/// files, to check F3/F5 on a real device.
class DeveloperSection extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final count = ref.watch(_indexCountProvider).value ?? 0;
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.storage_outlined),
          title: Text(l10n.devIndexedFiles(count)),
          trailing: TextButton(
            onPressed: () => ref.read(mediaIndexerProvider).fullScan().ignore(),
            child: Text(l10n.devRescan),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.list_alt_outlined),
          title: Text(l10n.devIndexList),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const _IndexListScreen()),
          ),
        ),
      ],
    );
  }
}

final StreamProvider<int> _indexCountProvider = StreamProvider.autoDispose<int>(
  (ref) => ref.watch(mediaIndexDaoProvider).watchCount(IndexQuery.all),
);

class _IndexListScreen extends ConsumerWidget {
  const new();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(indexPageProvider(IndexQuery.all));
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.devIndexList)),
      body: switch (page) {
        AsyncData(:final value) => ListView.builder(
          itemCount: value.items.length,
          itemBuilder: (context, i) {
            final f = value.items[i];
            return ListTile(
              leading: SizedBox.square(
                dimension: 48,
                child: Thumbnail(file: f),
              ),
              title: Text(f.name),
              subtitle: Text(
                [
                  f.kind.name,
                  formatBytes(f.sizeBytes, locale: locale),
                  formatDate(f.sortDate, locale: locale),
                  f.folderPath,
                ].join(' · '),
              ),
              isThreeLine: true,
            );
          },
        ),
        AsyncError(:final error) => Center(child: Text(error.toString())),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
