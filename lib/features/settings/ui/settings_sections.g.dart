// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_sections.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every Settings section, sorted by [SettingsSection.order]. Add one line
/// per feature.

@ProviderFor(settingsSections)
final settingsSectionsProvider = SettingsSectionsProvider._();

/// Every Settings section, sorted by [SettingsSection.order]. Add one line
/// per feature.

final class SettingsSectionsProvider
    extends
        $FunctionalProvider<
          List<SettingsSection>,
          List<SettingsSection>,
          List<SettingsSection>
        >
    with $Provider<List<SettingsSection>> {
  /// Every Settings section, sorted by [SettingsSection.order]. Add one line
  /// per feature.
  SettingsSectionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsSectionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsSectionsHash();

  @$internal
  @override
  $ProviderElement<List<SettingsSection>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<SettingsSection> create(Ref ref) {
    return settingsSections(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<SettingsSection> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<SettingsSection>>(value),
    );
  }
}

String _$settingsSectionsHash() => r'714bc7ad1187eb56389a879438fdbdae8718b0eb';
