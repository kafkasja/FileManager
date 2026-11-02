import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/router.dart';
import 'package:kfm/features/share_in/data/share_in_service.dart';

/// TASK-X1, mounted once in the app shell (so only after the router's
/// storage gate allowed a shell route: a first launch via a share shows the
/// permission gate first). Draws nothing: pushes the Shared screen once per
/// share, or says that only files can be shared.
class ShareInPrompter extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<ShareInPrompter> createState() => _ShareInPrompterState();
}

class _ShareInPrompterState extends ConsumerState<ShareInPrompter> {
  String? _pushedFor;

  @override
  void initState() {
    super.initState();
    // A share that arrived before the shell existed (cold start, gate).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _react(ref.read(pendingSharedBatchProvider));
    });
  }

  void _react(ShareInState s) {
    final id = s.batchId;
    if (id == null || id == _pushedFor) return;
    final batch = s.batch.value;
    if (batch != null && batch.files.isEmpty && batch.skippedNotFiles) {
      _pushedFor = id;
      ref.read(pendingSharedBatchProvider.notifier).dismissIf(id);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(context.l10n.shareInOnlyFiles)));
      return;
    }
    _pushedFor = id;
    final router = GoRouter.of(context);
    // The open Shared screen just shows the newer batch.
    if (router.state.uri.path == AppRoutes.shared) return;
    unawaited(router.push<void>(AppRoutes.shared));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(pendingSharedBatchProvider, (_, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _react(ref.read(pendingSharedBatchProvider));
      });
    });
    return const SizedBox.shrink();
  }
}
