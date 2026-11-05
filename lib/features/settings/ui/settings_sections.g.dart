// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_sections.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The 9 Settings sections (TASK-E2 §2), sorted by [SettingsSection.order].
/// Features own their [SettingsEntry]s; add an entry to its section here.
/// Rules (`settings_structure_test.dart`, per form factor): ≥ 2 entries per
/// shown section, unique ids, a description unless self-explanatory, no
/// phone-only rows on desktop.

@ProviderFor(settingsSections)
final settingsSectionsProvider = SettingsSectionsProvider._();

/// The 9 Settings sections (TASK-E2 §2), sorted by [SettingsSection.order].
/// Features own their [SettingsEntry]s; add an entry to its section here.
/// Rules (`settings_structure_test.dart`, per form factor): ≥ 2 entries per
/// shown section, unique ids, a description unless self-explanatory, no
/// phone-only rows on desktop.

final class SettingsSectionsProvider
    extends
        $FunctionalProvider<
          List<SettingsSection>,
          List<SettingsSection>,
          List<SettingsSection>
        >
    with $Provider<List<SettingsSection>> {
  /// The 9 Settings sections (TASK-E2 §2), sorted by [SettingsSection.order].
  /// Features own their [SettingsEntry]s; add an entry to its section here.
  /// Rules (`settings_structure_test.dart`, per form factor): ≥ 2 entries per
  /// shown section, unique ids, a description unless self-explanatory, no
  /// phone-only rows on desktop.
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

String _$settingsSectionsHash() => r'87eb30de49fe22b6c4d58fcf82394c9b8878f482';
