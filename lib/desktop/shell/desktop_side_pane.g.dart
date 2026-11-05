// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'desktop_side_pane.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Alt+P / Alt+Shift+P (View ▾); remembered (`desktop.sidePane`). Off by
/// default (rule 5).

@ProviderFor(DesktopSidePaneMode)
final desktopSidePaneModeProvider = DesktopSidePaneModeProvider._();

/// Alt+P / Alt+Shift+P (View ▾); remembered (`desktop.sidePane`). Off by
/// default (rule 5).
final class DesktopSidePaneModeProvider
    extends $NotifierProvider<DesktopSidePaneMode, DesktopSidePane> {
  /// Alt+P / Alt+Shift+P (View ▾); remembered (`desktop.sidePane`). Off by
  /// default (rule 5).
  DesktopSidePaneModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'desktopSidePaneModeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$desktopSidePaneModeHash();

  @$internal
  @override
  DesktopSidePaneMode create() => DesktopSidePaneMode();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DesktopSidePane value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DesktopSidePane>(value),
    );
  }
}

String _$desktopSidePaneModeHash() =>
    r'ce37d9d854bf2be5327ec73158ec18200b63eabc';

/// Alt+P / Alt+Shift+P (View ▾); remembered (`desktop.sidePane`). Off by
/// default (rule 5).

abstract class _$DesktopSidePaneMode extends $Notifier<DesktopSidePane> {
  DesktopSidePane build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DesktopSidePane, DesktopSidePane>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DesktopSidePane, DesktopSidePane>,
              DesktopSidePane,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// A right pane (Preview or Details) is shown.

@ProviderFor(desktopDetailsPane)
final desktopDetailsPaneProvider = DesktopDetailsPaneProvider._();

/// A right pane (Preview or Details) is shown.

final class DesktopDetailsPaneProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// A right pane (Preview or Details) is shown.
  DesktopDetailsPaneProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'desktopDetailsPaneProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$desktopDetailsPaneHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return desktopDetailsPane(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$desktopDetailsPaneHash() =>
    r'86984947b61d4dd73a2dfea67e0362febc34434f';

/// The first 64 KB of a text file, for the Preview pane.

@ProviderFor(desktopTextPreview)
final desktopTextPreviewProvider = DesktopTextPreviewFamily._();

/// The first 64 KB of a text file, for the Preview pane.

final class DesktopTextPreviewProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// The first 64 KB of a text file, for the Preview pane.
  DesktopTextPreviewProvider._({
    required DesktopTextPreviewFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'desktopTextPreviewProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$desktopTextPreviewHash();

  @override
  String toString() {
    return r'desktopTextPreviewProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    final argument = this.argument as String;
    return desktopTextPreview(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DesktopTextPreviewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$desktopTextPreviewHash() =>
    r'248afbcd68d5ac15b66c4416fccb266045abe219';

/// The first 64 KB of a text file, for the Preview pane.

final class DesktopTextPreviewFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String>, String> {
  DesktopTextPreviewFamily._()
    : super(
        retry: null,
        name: r'desktopTextPreviewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The first 64 KB of a text file, for the Preview pane.

  DesktopTextPreviewProvider call(String path) =>
      DesktopTextPreviewProvider._(argument: path, from: this);

  @override
  String toString() => r'desktopTextPreviewProvider';
}
