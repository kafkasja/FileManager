import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/platform/windows/desktop_shell_provider.dart';
import 'package:kfm/features/connect/data/accept_gate.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/data/share_server.dart';
import 'package:kfm/features/connect/data/windows_close_flow.dart';
import 'package:kfm/features/connect/ui/share_server_controller.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'windows_close_host.g.dart';

/// PL1: the Windows close/tray flow, started by `App` (null off Windows).
@Riverpod(keepAlive: true)
WindowsCloseFlow? windowsCloseFlow(Ref ref) {
  final shell = ref.watch(desktopShellProvider);
  if (shell == null) return null;
  final settings = ref.watch(settingsRepositoryProvider);
  final flow = WindowsCloseFlow(
    shell: shell,
    isSharing: () => switch (ref.read(shareServerControllerProvider).status) {
      ShareServerStatus.running || ShareServerStatus.starting => true,
      ShareServerStatus.stopped || ShareServerStatus.error => false,
    },
    stopSharing: () =>
        ref.read(shareServerControllerProvider.notifier).stopSharing(),
    stopOnClose: () => settings.read(AppSettings.windowsStopSharingOnClose),
    noticeShown: () => settings.read(AppSettings.windowsTrayNoticeShown),
    markNoticeShown: () =>
        settings.write(AppSettings.windowsTrayNoticeShown, true),
    attentionRequests: ref
        .watch(acceptGateProvider)
        .events
        .where((e) => e is AcceptRequested),
    beforeQuit: () async {
      await ref.read(sessionRepositoryProvider).flush();
      await ref.read(dbWriteQueueProvider).flush();
    },
  )..start();
  ref.onDispose(() => flow.dispose().ignore());
  return flow;
}

/// PL1, mounted once in the app shell on Windows. Draws nothing: shows the
/// one-time "KFM is still sharing this PC" notice before the window first
/// hides to the tray.
class WindowsCloseHost extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<WindowsCloseHost> createState() => _WindowsCloseHostState();
}

class _WindowsCloseHostState extends ConsumerState<WindowsCloseHost> {
  WindowsCloseFlow? _flow;

  @override
  void initState() {
    super.initState();
    _flow = ref.read(windowsCloseFlowProvider)?..firstHideNotice = _notice;
  }

  @override
  void dispose() {
    if (_flow?.firstHideNotice == _notice) _flow?.firstHideNotice = null;
    super.dispose();
  }

  Future<void> _notice() async {
    if (!mounted) return;
    final l = context.l10n;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.trayNoticeTitle),
        content: Text(l.trayNoticeBody),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// PL1: Settings → Connect switch "Stop sharing when the window closes".
@Riverpod(keepAlive: true)
Stream<bool> windowsStopSharingOnClose(Ref ref) => ref
    .watch(settingsRepositoryProvider)
    .watch(AppSettings.windowsStopSharingOnClose);
