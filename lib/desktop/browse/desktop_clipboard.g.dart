// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'desktop_clipboard.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// KFM's own clipboard for files (TASK-PL3: Ctrl+C/X/V within KFM; the
/// Windows clipboard comes with drag & drop in step 4).

@ProviderFor(DesktopClipboard)
final desktopClipboardProvider = DesktopClipboardProvider._();

/// KFM's own clipboard for files (TASK-PL3: Ctrl+C/X/V within KFM; the
/// Windows clipboard comes with drag & drop in step 4).
final class DesktopClipboardProvider
    extends $NotifierProvider<DesktopClipboard, DesktopClip?> {
  /// KFM's own clipboard for files (TASK-PL3: Ctrl+C/X/V within KFM; the
  /// Windows clipboard comes with drag & drop in step 4).
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

String _$desktopClipboardHash() => r'84b2ed1a3e8cc5cd530a8aad626060bdc69c478a';

/// KFM's own clipboard for files (TASK-PL3: Ctrl+C/X/V within KFM; the
/// Windows clipboard comes with drag & drop in step 4).

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
