import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/db/db_providers.dart';

/// Non-blocking "Couldn't save your last change." shown for 5 s whenever a
/// queued DB write fails (F2). The queue keeps going with later writes.
class DbErrorBanner extends ConsumerStatefulWidget {
  const new({super.key});

  static const visibleFor = Duration(seconds: 5);

  @override
  ConsumerState<DbErrorBanner> createState() => _DbErrorBannerState();
}

class _DbErrorBannerState extends ConsumerState<DbErrorBanner> {
  Timer? _hide;
  bool _visible = false;

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  void _show() {
    _hide?.cancel();
    setState(() => _visible = true);
    _hide = Timer(DbErrorBanner.visibleFor, _dismiss);
  }

  void _dismiss() {
    _hide?.cancel();
    if (mounted) setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(dbWriteErrorsProvider, (_, next) {
      if (next is AsyncData) _show();
    });
    if (!_visible) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return MaterialBanner(
      backgroundColor: scheme.errorContainer,
      leading: Icon(Icons.error_outline, color: scheme.onErrorContainer),
      content: Text(
        context.l10n.dbWriteError,
        style: TextStyle(color: scheme.onErrorContainer),
      ),
      actions: [
        TextButton(onPressed: _dismiss, child: Text(context.l10n.dismiss)),
      ],
    );
  }
}
