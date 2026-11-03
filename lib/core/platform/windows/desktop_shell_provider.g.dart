// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'desktop_shell_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The Windows window + tray (TASK-PL1); null elsewhere and in tests.
/// `main.dart` overrides it on Windows with an initialised
/// [WindowsDesktopShell].

@ProviderFor(desktopShell)
final desktopShellProvider = DesktopShellProvider._();

/// The Windows window + tray (TASK-PL1); null elsewhere and in tests.
/// `main.dart` overrides it on Windows with an initialised
/// [WindowsDesktopShell].

final class DesktopShellProvider
    extends $FunctionalProvider<DesktopShell?, DesktopShell?, DesktopShell?>
    with $Provider<DesktopShell?> {
  /// The Windows window + tray (TASK-PL1); null elsewhere and in tests.
  /// `main.dart` overrides it on Windows with an initialised
  /// [WindowsDesktopShell].
  DesktopShellProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'desktopShellProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$desktopShellHash();

  @$internal
  @override
  $ProviderElement<DesktopShell?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DesktopShell? create(Ref ref) {
    return desktopShell(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DesktopShell? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DesktopShell?>(value),
    );
  }
}

String _$desktopShellHash() => r'6706c2858e2890747b9bb317884846504df04324';
