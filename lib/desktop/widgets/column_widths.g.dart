// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'column_widths.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Column widths the user dragged in the desktop Details lists (PL3),
/// remembered between runs. Kept per PC (not in X6 backups: they fit this
/// screen).

@ProviderFor(DesktopColumnWidths)
final desktopColumnWidthsProvider = DesktopColumnWidthsProvider._();

/// Column widths the user dragged in the desktop Details lists (PL3),
/// remembered between runs. Kept per PC (not in X6 backups: they fit this
/// screen).
final class DesktopColumnWidthsProvider
    extends
        $NotifierProvider<
          DesktopColumnWidths,
          Map<String, Map<String, double>>
        > {
  /// Column widths the user dragged in the desktop Details lists (PL3),
  /// remembered between runs. Kept per PC (not in X6 backups: they fit this
  /// screen).
  DesktopColumnWidthsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'desktopColumnWidthsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$desktopColumnWidthsHash();

  @$internal
  @override
  DesktopColumnWidths create() => DesktopColumnWidths();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, Map<String, double>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, Map<String, double>>>(
        value,
      ),
    );
  }
}

String _$desktopColumnWidthsHash() =>
    r'b6c5e697e61fe78c4948b2d540c208b20d99b93b';

/// Column widths the user dragged in the desktop Details lists (PL3),
/// remembered between runs. Kept per PC (not in X6 backups: they fit this
/// screen).

abstract class _$DesktopColumnWidths
    extends $Notifier<Map<String, Map<String, double>>> {
  Map<String, Map<String, double>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              Map<String, Map<String, double>>,
              Map<String, Map<String, double>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                Map<String, Map<String, double>>,
                Map<String, Map<String, double>>
              >,
              Map<String, Map<String, double>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
