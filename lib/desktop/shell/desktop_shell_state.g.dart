// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'desktop_shell_state.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Right details pane shown (Ctrl+I). Off by default (rule 5).

@ProviderFor(DesktopDetailsPane)
final desktopDetailsPaneProvider = DesktopDetailsPaneProvider._();

/// Right details pane shown (Ctrl+I). Off by default (rule 5).
final class DesktopDetailsPaneProvider
    extends $NotifierProvider<DesktopDetailsPane, bool> {
  /// Right details pane shown (Ctrl+I). Off by default (rule 5).
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
  DesktopDetailsPane create() => DesktopDetailsPane();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$desktopDetailsPaneHash() =>
    r'997d8251006373004fb159295311336a8f465bf0';

/// Right details pane shown (Ctrl+I). Off by default (rule 5).

abstract class _$DesktopDetailsPane extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Sidebar collapsed to icons.

@ProviderFor(DesktopSidebarCollapsed)
final desktopSidebarCollapsedProvider = DesktopSidebarCollapsedProvider._();

/// Sidebar collapsed to icons.
final class DesktopSidebarCollapsedProvider
    extends $NotifierProvider<DesktopSidebarCollapsed, bool> {
  /// Sidebar collapsed to icons.
  DesktopSidebarCollapsedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'desktopSidebarCollapsedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$desktopSidebarCollapsedHash();

  @$internal
  @override
  DesktopSidebarCollapsed create() => DesktopSidebarCollapsed();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$desktopSidebarCollapsedHash() =>
    r'58c218d249e89586caa0d66aa6d5f868f88812da';

/// Sidebar collapsed to icons.

abstract class _$DesktopSidebarCollapsed extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The focused file of a desktop screen (the details pane shows it).

@ProviderFor(DesktopFocusedFile)
final desktopFocusedFileProvider = DesktopFocusedFileFamily._();

/// The focused file of a desktop screen (the details pane shows it).
final class DesktopFocusedFileProvider
    extends $NotifierProvider<DesktopFocusedFile, FileRef?> {
  /// The focused file of a desktop screen (the details pane shows it).
  DesktopFocusedFileProvider._({
    required DesktopFocusedFileFamily super.from,
    required DesktopSection super.argument,
  }) : super(
         retry: null,
         name: r'desktopFocusedFileProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$desktopFocusedFileHash();

  @override
  String toString() {
    return r'desktopFocusedFileProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DesktopFocusedFile create() => DesktopFocusedFile();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FileRef? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FileRef?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DesktopFocusedFileProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$desktopFocusedFileHash() =>
    r'06d14c95b55f29ace82c8373b01c9926e7a6d7b4';

/// The focused file of a desktop screen (the details pane shows it).

final class DesktopFocusedFileFamily extends $Family
    with
        $ClassFamilyOverride<
          DesktopFocusedFile,
          FileRef?,
          FileRef?,
          FileRef?,
          DesktopSection
        > {
  DesktopFocusedFileFamily._()
    : super(
        retry: null,
        name: r'desktopFocusedFileProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// The focused file of a desktop screen (the details pane shows it).

  DesktopFocusedFileProvider call(DesktopSection section) =>
      DesktopFocusedFileProvider._(argument: section, from: this);

  @override
  String toString() => r'desktopFocusedFileProvider';
}

/// The focused file of a desktop screen (the details pane shows it).

abstract class _$DesktopFocusedFile extends $Notifier<FileRef?> {
  late final _$args = ref.$arg as DesktopSection;
  DesktopSection get section => _$args;

  FileRef? build(DesktopSection section);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<FileRef?, FileRef?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FileRef?, FileRef?>,
              FileRef?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Each desktop screen reports its counts here; the status bar shows the
/// current section's.

@ProviderFor(DesktopStatusLine)
final desktopStatusLineProvider = DesktopStatusLineFamily._();

/// Each desktop screen reports its counts here; the status bar shows the
/// current section's.
final class DesktopStatusLineProvider
    extends $NotifierProvider<DesktopStatusLine, DesktopStatus> {
  /// Each desktop screen reports its counts here; the status bar shows the
  /// current section's.
  DesktopStatusLineProvider._({
    required DesktopStatusLineFamily super.from,
    required DesktopSection super.argument,
  }) : super(
         retry: null,
         name: r'desktopStatusLineProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$desktopStatusLineHash();

  @override
  String toString() {
    return r'desktopStatusLineProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DesktopStatusLine create() => DesktopStatusLine();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DesktopStatus value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DesktopStatus>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DesktopStatusLineProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$desktopStatusLineHash() => r'aabb59e094d6d8584709df68a5c38689af01f940';

/// Each desktop screen reports its counts here; the status bar shows the
/// current section's.

final class DesktopStatusLineFamily extends $Family
    with
        $ClassFamilyOverride<
          DesktopStatusLine,
          DesktopStatus,
          DesktopStatus,
          DesktopStatus,
          DesktopSection
        > {
  DesktopStatusLineFamily._()
    : super(
        retry: null,
        name: r'desktopStatusLineProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Each desktop screen reports its counts here; the status bar shows the
  /// current section's.

  DesktopStatusLineProvider call(DesktopSection section) =>
      DesktopStatusLineProvider._(argument: section, from: this);

  @override
  String toString() => r'desktopStatusLineProvider';
}

/// Each desktop screen reports its counts here; the status bar shows the
/// current section's.

abstract class _$DesktopStatusLine extends $Notifier<DesktopStatus> {
  late final _$args = ref.$arg as DesktopSection;
  DesktopSection get section => _$args;

  DesktopStatus build(DesktopSection section);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DesktopStatus, DesktopStatus>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DesktopStatus, DesktopStatus>,
              DesktopStatus,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Places in the sidebar: on Windows the folders KFM scans (PL1 index
/// roots: Pictures, Videos, Downloads, Documents by default), elsewhere the
/// index's top folders. Drives and devices come later (TASK-PL3 step 5).

@ProviderFor(desktopPlaces)
final desktopPlacesProvider = DesktopPlacesProvider._();

/// Places in the sidebar: on Windows the folders KFM scans (PL1 index
/// roots: Pictures, Videos, Downloads, Documents by default), elsewhere the
/// index's top folders. Drives and devices come later (TASK-PL3 step 5).

final class DesktopPlacesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DesktopPlace>>,
          List<DesktopPlace>,
          FutureOr<List<DesktopPlace>>
        >
    with
        $FutureModifier<List<DesktopPlace>>,
        $FutureProvider<List<DesktopPlace>> {
  /// Places in the sidebar: on Windows the folders KFM scans (PL1 index
  /// roots: Pictures, Videos, Downloads, Documents by default), elsewhere the
  /// index's top folders. Drives and devices come later (TASK-PL3 step 5).
  DesktopPlacesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'desktopPlacesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$desktopPlacesHash();

  @$internal
  @override
  $FutureProviderElement<List<DesktopPlace>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<DesktopPlace>> create(Ref ref) {
    return desktopPlaces(ref);
  }
}

String _$desktopPlacesHash() => r'4eab5f211e50137e78112782ab2f905082401f2c';
