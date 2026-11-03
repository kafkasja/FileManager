// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'desktop_clipboard.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// KFM's own clipboard for files and folders (TASK-PL3: Ctrl+C/X/V). The
/// Windows clipboard mirrors it ([copyToClipboard] / [pasteClipboard]).

@ProviderFor(DesktopClipboard)
final desktopClipboardProvider = DesktopClipboardProvider._();

/// KFM's own clipboard for files and folders (TASK-PL3: Ctrl+C/X/V). The
/// Windows clipboard mirrors it ([copyToClipboard] / [pasteClipboard]).
final class DesktopClipboardProvider
    extends $NotifierProvider<DesktopClipboard, DesktopClip?> {
  /// KFM's own clipboard for files and folders (TASK-PL3: Ctrl+C/X/V). The
  /// Windows clipboard mirrors it ([copyToClipboard] / [pasteClipboard]).
  DesktopClipboardProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'desktopClipboardProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$desktopClipboardHash();

  @$internal
  @override
  DesktopClipboard create() => DesktopClipboard();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DesktopClip? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DesktopClip?>(value),
    );
  }
}

String _$desktopClipboardHash() => r'15bfeadaea68edd5c89130e9ebee874838bd5a65';

/// KFM's own clipboard for files and folders (TASK-PL3: Ctrl+C/X/V). The
/// Windows clipboard mirrors it ([copyToClipboard] / [pasteClipboard]).

abstract class _$DesktopClipboard extends $Notifier<DesktopClip?> {
  DesktopClip? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DesktopClip?, DesktopClip?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DesktopClip?, DesktopClip?>,
              DesktopClip?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
