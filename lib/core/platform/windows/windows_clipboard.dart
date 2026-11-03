import 'package:flutter/services.dart';
import 'package:kfm/core/platform/host_platform.dart';
import 'package:kfm/core/platform/windows/windows_channel.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'windows_clipboard.g.dart';

/// Files on the system clipboard.
@immutable
class SystemClip {
  const new({required this.paths, required this.cut, required this.sequence});

  /// '/'-separated; empty when the clipboard holds no files.
  final List<String> paths;

  /// Explorer's Cut (Preferred DropEffect = move).
  final bool cut;

  /// Changes whenever anything writes the clipboard.
  final int sequence;
}

/// The system clipboard for files (TASK-PL3: Ctrl+C / Ctrl+X / Ctrl+V
/// between KFM and Explorer). Null where there is none (Android, tests).
abstract interface class SystemFileClipboard {
  /// Puts [paths] on the clipboard (CF_HDROP + Preferred DropEffect).
  /// Returns its sequence number, or null when that failed.
  Future<int?> write(List<String> paths, {required bool cut});

  Future<SystemClip?> read();

  /// Empties it (after a cut was pasted, like Explorer).
  Future<void> clear();
}

/// Windows: methods of the `com.kaf.kfm/windows` channel, answered on the
/// window thread by `windows/runner/clipboard_files.cpp`:
/// - `clipboardSetFiles {paths: [String], cut: bool}` → int sequence (0 =
///   failed): CF_HDROP (`DROPFILES`, wide paths) + `Preferred DropEffect`
///   (cut = `DROPEFFECT_MOVE`, copy = `COPY | LINK`, Explorer's values).
/// - `clipboardFiles` → `{paths: [String], cut: bool, sequence: int}`.
/// - `clipboardClear` → null.
class WindowsFileClipboard implements SystemFileClipboard {
  new({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('com.kaf.kfm/windows');

  final MethodChannel _channel;

  @override
  Future<int?> write(List<String> paths, {required bool cut}) async {
    try {
      final seq = await _channel.invokeMethod<int>('clipboardSetFiles', {
        'paths': [for (final p in paths) WindowsChannel.toNative(p)],
        'cut': cut,
      });
      return seq == null || seq == 0 ? null : seq;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<SystemClip?> read() async {
    try {
      final raw = await _channel.invokeMethod<Map<Object?, Object?>>(
        'clipboardFiles',
      );
      if (raw == null) return null;
      return SystemClip(
        paths: [
          for (final p in (raw['paths'] as List<Object?>?) ?? const [])
            if (p is String && p.isNotEmpty) WindowsChannel.fromNative(p),
        ],
        cut: raw['cut'] == true,
        sequence: (raw['sequence'] as int?) ?? 0,
      );
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _channel.invokeMethod<void>('clipboardClear');
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }
}

/// The system file clipboard (Windows only; tests override it).
@Riverpod(keepAlive: true)
SystemFileClipboard? systemFileClipboard(Ref ref) =>
    isWindowsHost ? WindowsFileClipboard() : null;
