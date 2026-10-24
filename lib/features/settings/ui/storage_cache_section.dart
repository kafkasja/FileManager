import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/utils/format.dart';

/// Settings → Storage: thumbnail cache size + clear (F5).
class StorageCacheSection extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<StorageCacheSection> createState() =>
      _StorageCacheSectionState();
}

class _StorageCacheSectionState extends ConsumerState<StorageCacheSection> {
  late Future<int> _size = _readSize();

  Future<int> _readSize() async {
    final cache = await ref.read(thumbnailCacheProvider.future);
    return await cache.diskSizeBytes();
  }

  Future<void> _clear() async {
    final cache = await ref.read(thumbnailCacheProvider.future);
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
        subtitle: Text(
          snapshot.hasError
              ? l10n.thumbCacheSizeUnknown
              : snapshot.hasData
              ? formatBytes(snapshot.data!, locale: locale)
              : '',
        ),
        trailing: TextButton(
          onPressed: snapshot.hasData ? _clear : null,
          child: Text(l10n.thumbCacheClear),
        ),
      ),
    );
  }
}
