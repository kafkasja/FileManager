import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/app/l10n_ext.dart';
import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/diagnostics/error_log.dart';
import 'package:kfm/core/diagnostics/error_log_providers.dart';
import 'package:kfm/core/index/index_providers.dart';
import 'package:kfm/core/platform/host_platform.dart';
import 'package:kfm/core/platform/windows/desktop_shell_provider.dart';
import 'package:kfm/core/platform/windows/index_roots.dart';
import 'package:kfm/core/platform/windows/windows_channel.dart';
import 'package:kfm/features/connect/data/accept_gate.dart';
import 'package:kfm/features/connect/data/connect_providers.dart';
import 'package:kfm/features/connect/data/share_server.dart';
import 'package:kfm/features/connect/data/windows_close_flow.dart';
import 'package:kfm/features/connect/data/windows_power_flow.dart';
import 'package:kfm/features/connect/ui/share_server_controller.dart';
import 'package:kfm/features/session/data/session_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'windows_close_host.g.dart';

bool _isSharing(Ref ref) =>
    switch (ref.read(shareServerControllerProvider).status) {
      ShareServerStatus.running || ShareServerStatus.starting => true,
      ShareServerStatus.stopped || ShareServerStatus.error => false,
    };

Future<void> _flushWrites(Ref ref) async {
  await ref.read(sessionRepositoryProvider).flush();
  await ref.read(dbWriteQueueProvider).flush();
}

/// PL1: the Windows close/tray flow, started by `App` (null off Windows).
@Riverpod(keepAlive: true)
WindowsCloseFlow? windowsCloseFlow(Ref ref) {
  final shell = ref.watch(desktopShellProvider);
  if (shell == null) return null;
  final settings = ref.watch(settingsRepositoryProvider);
  final flow = WindowsCloseFlow(
    shell: shell,
    isSharing: () => _isSharing(ref),
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
    beforeQuit: () => _flushWrites(ref),
  )..start();
  ref.onDispose(() => flow.dispose().ignore());
  return flow;
}

/// PL1: sleep stops sharing and flushes; wake-up rescans (started by
/// `App`; null off Windows).
@Riverpod(keepAlive: true)
WindowsPowerFlow? windowsPowerFlow(Ref ref) {
  if (!isWindowsHost) return null;
  final log = ref.watch(errorLogProvider);
  final flow = WindowsPowerFlow(
    events: ref
        .watch(windowsChannelProvider)
        .events
        .where((e) => e is PowerChanged)
        .cast<PowerChanged>()
        .map((e) => e.state),
    isSharing: () => _isSharing(ref),
    stopSharing: () =>
        ref.read(shareServerControllerProvider.notifier).stopSharing(),
    flushWrites: () => _flushWrites(ref),
    onResume: () => ref.read(mediaIndexerProvider).incremental(),
    onError: (what, e, st) => log
        .record(
          ErrorLogEntry(
            at: DateTime.now().toUtc(),
            source: ErrorSource.platform,
            error: 'power: $what: $e',
            stack: st,
          ),
        )
        .ignore(),
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
