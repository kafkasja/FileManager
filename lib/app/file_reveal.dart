import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kfm/core/platform/host_platform.dart';
import 'package:kfm/core/platform/windows/index_roots.dart';
import 'package:path/path.dart' as p;

/// Shows [path] in the system file manager with it selected (TASK-E3 /
/// E1 shared): Windows Explorer via `SHOpenFolderAndSelectItems`; macOS
/// Finder `open -R`; Linux opens the folder. Throws when it couldn't.
Future<void> revealInFolder(WidgetRef ref, String path) =>
    revealInFolderWith(ref.read(fileRevealerProvider), path);

/// Same as [revealInFolder] for code that holds a [Ref].
Future<void> revealInFolderWith(FileRevealer revealer, String path) =>
    revealer(path);

/// Reveals one path; replaced in tests.
typedef FileRevealer = Future<void> Function(String path);

final fileRevealerProvider = Provider<FileRevealer>((ref) {
  if (isWindowsHost) {
    final channel = ref.watch(windowsChannelProvider);
    return channel.revealInExplorer;
  }
  return (path) async {
    if (Platform.isMacOS) {
      await Process.run('open', ['-R', path]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [p.dirname(path)]);
    } else {
      throw UnsupportedError('reveal is desktop only');
    }
  };
});
