// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'archive_undo.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(archiveUndo)
final archiveUndoProvider = ArchiveUndoProvider._();

final class ArchiveUndoProvider
    extends $FunctionalProvider<ArchiveUndo, ArchiveUndo, ArchiveUndo>
    with $Provider<ArchiveUndo> {
  ArchiveUndoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'archiveUndoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$archiveUndoHash();

  @$internal
  @override
  $ProviderElement<ArchiveUndo> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ArchiveUndo create(Ref ref) {
    return archiveUndo(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ArchiveUndo value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ArchiveUndo>(value),
    );
  }
}

String _$archiveUndoHash() => r'ca19c782e736d9443c42ca6cbe4cbb9a4f686be4';
