// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_drag.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The running drag (null = none). B6's `SelectableFile` starts it with a
/// long-press on an already-selected tile in Select mode; folder rows
/// ([FolderDropTarget]) highlight while hovered.

@ProviderFor(FileDrag)
final fileDragProvider = FileDragProvider._();

/// The running drag (null = none). B6's `SelectableFile` starts it with a
/// long-press on an already-selected tile in Select mode; folder rows
/// ([FolderDropTarget]) highlight while hovered.
final class FileDragProvider
    extends $NotifierProvider<FileDrag, FileDragState?> {
  /// The running drag (null = none). B6's `SelectableFile` starts it with a
  /// long-press on an already-selected tile in Select mode; folder rows
  /// ([FolderDropTarget]) highlight while hovered.
  FileDragProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fileDragProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fileDragHash();

  @$internal
  @override
  FileDrag create() => FileDrag();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FileDragState? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FileDragState?>(value),
    );
  }
}

String _$fileDragHash() => r'e45c2f9376f4be0cde9a469c10bd49561009cfc8';

/// The running drag (null = none). B6's `SelectableFile` starts it with a
/// long-press on an already-selected tile in Select mode; folder rows
/// ([FolderDropTarget]) highlight while hovered.

abstract class _$FileDrag extends $Notifier<FileDragState?> {
  FileDragState? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<FileDragState?, FileDragState?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FileDragState?, FileDragState?>,
              FileDragState?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
