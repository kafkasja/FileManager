// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'last_operation_undo.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Undo of the last Browse file operation (TASK-B4 §8; not S2's swipe
/// `UndoService`). Memory only: lost on restart (Decision 1). A new
/// operation replaces the stored one; undoing clears it (but an undo that
/// was declined or cancelled before it changed anything keeps it).
///
/// Follows F3's `idChanges`: a stored `after` whose id changes (a MediaStore
/// re-key) is updated, so undo still finds it.

@ProviderFor(LastOperationUndo)
final lastOperationUndoProvider = LastOperationUndoProvider._();

/// Undo of the last Browse file operation (TASK-B4 §8; not S2's swipe
/// `UndoService`). Memory only: lost on restart (Decision 1). A new
/// operation replaces the stored one; undoing clears it (but an undo that
/// was declined or cancelled before it changed anything keeps it).
///
/// Follows F3's `idChanges`: a stored `after` whose id changes (a MediaStore
/// re-key) is updated, so undo still finds it.
final class LastOperationUndoProvider
    extends $NotifierProvider<LastOperationUndo, LastOperation?> {
  /// Undo of the last Browse file operation (TASK-B4 §8; not S2's swipe
  /// `UndoService`). Memory only: lost on restart (Decision 1). A new
  /// operation replaces the stored one; undoing clears it (but an undo that
  /// was declined or cancelled before it changed anything keeps it).
  ///
  /// Follows F3's `idChanges`: a stored `after` whose id changes (a MediaStore
  /// re-key) is updated, so undo still finds it.
  LastOperationUndoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'lastOperationUndoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$lastOperationUndoHash();

  @$internal
  @override
  LastOperationUndo create() => LastOperationUndo();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LastOperation? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LastOperation?>(value),
    );
  }
}

String _$lastOperationUndoHash() => r'969a8a60798644efd4acc8bb5c3c4c39849fe9a8';

/// Undo of the last Browse file operation (TASK-B4 §8; not S2's swipe
/// `UndoService`). Memory only: lost on restart (Decision 1). A new
/// operation replaces the stored one; undoing clears it (but an undo that
/// was declined or cancelled before it changed anything keeps it).
///
/// Follows F3's `idChanges`: a stored `after` whose id changes (a MediaStore
/// re-key) is updated, so undo still finds it.

abstract class _$LastOperationUndo extends $Notifier<LastOperation?> {
  LastOperation? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LastOperation?, LastOperation?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LastOperation?, LastOperation?>,
              LastOperation?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
