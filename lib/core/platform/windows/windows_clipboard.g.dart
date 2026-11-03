// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'windows_clipboard.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The system file clipboard (Windows only; tests override it).

@ProviderFor(systemFileClipboard)
final systemFileClipboardProvider = SystemFileClipboardProvider._();

/// The system file clipboard (Windows only; tests override it).

final class SystemFileClipboardProvider
    extends
        $FunctionalProvider<
          SystemFileClipboard?,
          SystemFileClipboard?,
          SystemFileClipboard?
        >
    with $Provider<SystemFileClipboard?> {
  /// The system file clipboard (Windows only; tests override it).
  SystemFileClipboardProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'systemFileClipboardProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$systemFileClipboardHash();

  @$internal
  @override
  $ProviderElement<SystemFileClipboard?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SystemFileClipboard? create(Ref ref) {
    return systemFileClipboard(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SystemFileClipboard? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SystemFileClipboard?>(value),
    );
  }
}

String _$systemFileClipboardHash() =>
    r'37ba6c8d89555e6a1c99ffea584ea4bb021c863b';
