import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:kfm/features/trash/data/no_trash_confirmer.dart';

/// PL1, mounted once in the app shell. Draws nothing: answers
/// [NoTrashConfirmer] with "This drive has no Recycle Bin. Delete these N
/// files permanently?". Cancel keeps the files queued.
class NoTrashPrompter extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<NoTrashPrompter> createState() => _NoTrashPrompterState();
}

class _NoTrashPrompterState extends ConsumerState<NoTrashPrompter> {
  late final NoTrashConfirmer _confirmer;

  @override
  void initState() {
    super.initState();
    _confirmer = ref.read(noTrashConfirmerProvider)..handler = _ask;
  }

  @override
  void dispose() {
    if (_confirmer.handler == _ask) _confirmer.handler = null;
    super.dispose();
  }

  Future<bool> _ask(int count) async {
    if (!mounted) return false;
    final l = context.l10n;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.fileOpNoTrash),
        content: Text(l.deleteNoRecycleBin(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.permanentConfirmYes),
          ),
        ],
      ),
    );
    return yes ?? false;
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
