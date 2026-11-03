// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sort_history.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The session's undoable actions, newest first, with file names. Follows
/// the undo log (S2) through its undoable count.

@ProviderFor(sortHistory)
final sortHistoryProvider = SortHistoryFamily._();

/// The session's undoable actions, newest first, with file names. Follows
/// the undo log (S2) through its undoable count.

final class SortHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SortHistoryEntry>>,
          List<SortHistoryEntry>,
          FutureOr<List<SortHistoryEntry>>
        >
    with
        $FutureModifier<List<SortHistoryEntry>>,
        $FutureProvider<List<SortHistoryEntry>> {
  /// The session's undoable actions, newest first, with file names. Follows
  /// the undo log (S2) through its undoable count.
  SortHistoryProvider._({
    required SortHistoryFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'sortHistoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sortHistoryHash();

  @override
  String toString() {
    return r'sortHistoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<SortHistoryEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SortHistoryEntry>> create(Ref ref) {
    final argument = this.argument as int;
    return sortHistory(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SortHistoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sortHistoryHash() => r'53992fc6842e2a1fd9cc0e9488b5d63a80454fba';

/// The session's undoable actions, newest first, with file names. Follows
/// the undo log (S2) through its undoable count.

final class SortHistoryFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<SortHistoryEntry>>, int> {
  SortHistoryFamily._()
    : super(
        retry: null,
        name: r'sortHistoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The session's undoable actions, newest first, with file names. Follows
  /// the undo log (S2) through its undoable count.

  SortHistoryProvider call(int sessionId) =>
      SortHistoryProvider._(argument: sessionId, from: this);

  @override
  String toString() => r'sortHistoryProvider';
}
