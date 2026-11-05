// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'desktop_status_bar.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// E1 hook: "Connected to `phone`" in the status bar (a link widget);
/// null until E1c fills it.

@ProviderFor(desktopStatusConnection)
final desktopStatusConnectionProvider = DesktopStatusConnectionProvider._();

/// E1 hook: "Connected to `phone`" in the status bar (a link widget);
/// null until E1c fills it.

final class DesktopStatusConnectionProvider
    extends $FunctionalProvider<Widget?, Widget?, Widget?>
    with $Provider<Widget?> {
  /// E1 hook: "Connected to `phone`" in the status bar (a link widget);
  /// null until E1c fills it.
  DesktopStatusConnectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'desktopStatusConnectionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$desktopStatusConnectionHash();

  @$internal
  @override
  $ProviderElement<Widget?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Widget? create(Ref ref) {
    return desktopStatusConnection(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Widget? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Widget?>(value),
    );
  }
}

String _$desktopStatusConnectionHash() =>
    r'59996086740efb74c0311046a0423e7e5921b5a5';

@ProviderFor(DesktopViewToggles)
final desktopViewTogglesProvider = DesktopViewTogglesFamily._();

final class DesktopViewTogglesProvider
    extends $NotifierProvider<DesktopViewToggles, DesktopViewToggle?> {
  DesktopViewTogglesProvider._({
    required DesktopViewTogglesFamily super.from,
    required DesktopSection super.argument,
  }) : super(
         retry: null,
         name: r'desktopViewTogglesProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$desktopViewTogglesHash();

  @override
  String toString() {
    return r'desktopViewTogglesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DesktopViewToggles create() => DesktopViewToggles();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DesktopViewToggle? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DesktopViewToggle?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DesktopViewTogglesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$desktopViewTogglesHash() =>
    r'99655ea2e0563fa15d5501505d7c1c06dd25c796';

final class DesktopViewTogglesFamily extends $Family
    with
        $ClassFamilyOverride<
          DesktopViewToggles,
          DesktopViewToggle?,
          DesktopViewToggle?,
          DesktopViewToggle?,
          DesktopSection
        > {
  DesktopViewTogglesFamily._()
    : super(
        retry: null,
        name: r'desktopViewTogglesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  DesktopViewTogglesProvider call(DesktopSection section) =>
      DesktopViewTogglesProvider._(argument: section, from: this);

  @override
  String toString() => r'desktopViewTogglesProvider';
}

abstract class _$DesktopViewToggles extends $Notifier<DesktopViewToggle?> {
  late final _$args = ref.$arg as DesktopSection;
  DesktopSection get section => _$args;

  DesktopViewToggle? build(DesktopSection section);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DesktopViewToggle?, DesktopViewToggle?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DesktopViewToggle?, DesktopViewToggle?>,
              DesktopViewToggle?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
