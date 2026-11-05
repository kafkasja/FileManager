import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/utils/format.dart';
import 'package:kfm/core/utils/read_future.dart';
import 'package:kfm/features/settings/ui/settings_section.dart';

/// Settings → Storage & cleanup: the thumbnail cache (F5) with what it is
/// and what Clear does (TASK-E2: "what does that do?").
final thumbCacheEntry = SettingsEntry(
  id: 'storage.thumbCache',
  titleBuilder: (c) => c.l10n.thumbCacheTitle,
  subtitleBuilder: (c) => c.l10n.thumbCacheHelp,
  keywordsBuilder: (c) => c.l10n.settingsKeywordsThumbCache,
  builder: (_) => const ThumbCacheRow(),
);

/// Size + Clear.
class ThumbCacheRow extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<ThumbCacheRow> createState() => _ThumbCacheRowState();
}

class _ThumbCacheRowState extends ConsumerState<ThumbCacheRow> {
  late Future<int> _size = _readSize();

  Future<int> _readSize() async {
    final cache = await ref.readFuture(thumbnailCacheProvider.future);
    return await cache.diskSizeBytes();
  }

  Future<void> _clear() async {
    final cache = await ref.readFuture(thumbnailCacheProvider.future);
    await cache.clear();
    if (mounted) setState(() => _size = _readSize());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return FutureBuilder<int>(
      future: _size,
      builder: (context, snapshot) => ListTile(
        leading: const Icon(Icons.photo_size_select_large_outlined),
        title: Text(l10n.thumbCacheTitle),
        isThreeLine: true,
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (snapshot.hasError)
              Text(l10n.thumbCacheSizeUnknown)
            else if (snapshot.hasData)
              Text(formatBytes(snapshot.data!, locale: locale)),
            Text(l10n.thumbCacheHelp),
          ],
        ),
        trailing: TextButton(
          onPressed: snapshot.hasData ? _clear : null,
          child: Text(l10n.thumbCacheClear),
        ),
      ),
    );
  }
}
