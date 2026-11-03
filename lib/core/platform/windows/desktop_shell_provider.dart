import 'package:kfm/core/platform/windows/desktop_shell.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'desktop_shell_provider.g.dart';

/// The Windows window + tray (TASK-PL1); null elsewhere and in tests.
/// `main.dart` overrides it on Windows with an initialised
/// [WindowsDesktopShell].
@Riverpod(keepAlive: true)
DesktopShell? desktopShell(Ref ref) => null;
