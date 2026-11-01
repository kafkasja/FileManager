import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/app/theme/app_tokens.dart';
import 'package:kfm/core/platform/screen_awake.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/data/share_server.dart';
import 'package:kfm/features/connect/ui/share_server_controller.dart';

/// "Share this device" (TASK-N1). Sharing runs only while this screen is
/// open: it starts in `initState` and stops in `dispose`. The QR area is
/// filled by N2. The screen stays on while open.
class ShareScreen extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends ConsumerState<ShareScreen> {
  // Read once: `ref` can't be used in dispose.
  late final ShareServerController _controller;
  late final ScreenAwake _awake;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(shareServerControllerProvider.notifier);
    _awake = ref.read(screenAwakeProvider);
    _keepAwake(on: true);
    // After the first frame: providers may not be modified during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.startSharing().ignore();
    });
  }

  @override
  void dispose() {
    _controller.stopSharing().ignore();
    _keepAwake(on: false);
    super.dispose();
  }

  void _keepAwake({required bool on}) {
    // Best effort: a missing wakelock never blocks sharing.
    unawaited(_awake.keepOn(on: on).catchError((Object _) {}));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(shareServerControllerProvider);
    final spacing = context.tokens.spacing;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.shareTitle)),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsetsDirectional.all(spacing * 3),
          child: switch (state.status) {
            ShareServerStatus.starting => _Centered(
              icon: null,
              title: l10n.sharePreparing,
            ),
            ShareServerStatus.running => _Running(state: state),
            ShareServerStatus.error => _Centered(
              icon: Icons.wifi_off_outlined,
              title: state.error is NoLocalNetworkException
                  ? l10n.shareNoNetwork
                  : l10n.shareFailed,
              body: state.error is NoLocalNetworkException
                  ? l10n.shareNoNetworkHint
                  : null,
              action: FilledButton(
                onPressed: () => _controller.startSharing().ignore(),
                child: Text(l10n.shareRetry),
              ),
            ),
            ShareServerStatus.stopped => _Centered(
              icon: Icons.portable_wifi_off_outlined,
              title: l10n.shareStopped,
              action: FilledButton(
                onPressed: () => _controller.startSharing().ignore(),
                child: Text(l10n.shareStartAgain),
              ),
            ),
          },
        ),
      ),
    );
  }
}

class _Running extends ConsumerWidget {
  const new({required this.state});

  final ShareServerState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final spacing = context.tokens.spacing;
    final name = ref.watch(deviceIdentityProvider).value?.displayName ?? '';
    return ListView(
      children: [
        Icon(
          Icons.wifi_tethering,
          size: 64,
          color: theme.colorScheme.primary,
        ),
        SizedBox(height: spacing * 2),
        Text(
          l10n.shareSharing,
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: spacing),
        Text(
          l10n.shareSharingAs(name),
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: spacing),
        Text(
          l10n.shareKeepOpen,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        if (kDebugMode) ...[
          SizedBox(height: spacing * 3),
          for (final a in state.addresses)
            SelectableText(
              l10n.shareDebugAddress(a.address.address, state.port ?? 0),
              key: ValueKey('share-address-${a.address.address}'),
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          if (state.fingerprint case final fp?)
            SelectableText(
              l10n.shareDebugFingerprint(fp),
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
        ],
        SizedBox(height: spacing * 4),
        Center(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.stop_circle_outlined),
            label: Text(l10n.shareStop),
          ),
        ),
      ],
    );
  }
}

class _Centered extends StatelessWidget {
  const new({required this.icon, required this.title, this.body, this.action});

  /// Null shows a progress indicator.
  final IconData? icon;
  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.tokens.spacing;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon case final i?)
            Icon(i, size: 48, color: theme.colorScheme.onSurfaceVariant)
          else
            const CircularProgressIndicator(),
          SizedBox(height: spacing * 2),
          Text(
            title,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          if (body case final b?) ...[
            SizedBox(height: spacing),
            Text(b, textAlign: TextAlign.center),
          ],
          if (action case final a?) ...[SizedBox(height: spacing * 2), a],
        ],
      ),
    );
  }
}
