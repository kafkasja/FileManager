import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/features/browse/domain/browse_source_chip.dart';
import 'package:kfm/features/browse/ui/collection_screen.dart';
import 'package:kfm/features/tags/data/tag_providers.dart';

/// One tag's files (TASK-B9): Browse's collection page with a fixed tag
/// query. Follows renames; pops with a message if the tag is deleted.
class TagFilesScreen extends ConsumerStatefulWidget {
  const new({required this.tagId, super.key});

  final int tagId;

  @override
  ConsumerState<TagFilesScreen> createState() => _TagFilesScreenState();
}

class _TagFilesScreenState extends ConsumerState<TagFilesScreen> {
  bool _popped = false;

  @override
  Widget build(BuildContext context) {
    final tags = ref.watch(tagsByIdProvider);
    final tag = tags.value?[widget.tagId];
    if (tag == null) {
      if (tags.hasValue && !_popped) {
        _popped = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(context.l10n.tagGone)));
          Navigator.of(context).maybePop();
        });
      }
      return const Scaffold(body: SizedBox.shrink());
    }
    return CollectionScreen(collection: TagCollection(tag));
  }
}
