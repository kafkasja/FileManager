// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The search screen's text, tokens and filter chips (TASK-B8 §5–§6). The
/// text is parsed 150 ms after the last keystroke; chips apply at once.
/// [folder] is the folder it was opened from ("Only in" chip).
///
/// Recording a recent search: on submit, when the screen closes, or
/// [recordDelay] after a chip change with no change (text or chip) since.
/// Typing cancels a pending chip record, so half-typed text is only saved
/// by submit or close. Empty searches, searches that can't match, and the
/// same query twice in a row are never recorded. What's recorded is always
/// `_parsed` of the current state: exactly what the screen shows.

@ProviderFor(SearchScreenController)
final searchScreenControllerProvider = SearchScreenControllerFamily._();

/// The search screen's text, tokens and filter chips (TASK-B8 §5–§6). The
/// text is parsed 150 ms after the last keystroke; chips apply at once.
/// [folder] is the folder it was opened from ("Only in" chip).
///
/// Recording a recent search: on submit, when the screen closes, or
/// [recordDelay] after a chip change with no change (text or chip) since.
/// Typing cancels a pending chip record, so half-typed text is only saved
/// by submit or close. Empty searches, searches that can't match, and the
/// same query twice in a row are never recorded. What's recorded is always
/// `_parsed` of the current state: exactly what the screen shows.
final class SearchScreenControllerProvider
    extends $NotifierProvider<SearchScreenController, SearchState> {
  /// The search screen's text, tokens and filter chips (TASK-B8 §5–§6). The
  /// text is parsed 150 ms after the last keystroke; chips apply at once.
  /// [folder] is the folder it was opened from ("Only in" chip).
  ///
  /// Recording a recent search: on submit, when the screen closes, or
  /// [recordDelay] after a chip change with no change (text or chip) since.
  /// Typing cancels a pending chip record, so half-typed text is only saved
  /// by submit or close. Empty searches, searches that can't match, and the
  /// same query twice in a row are never recorded. What's recorded is always
  /// `_parsed` of the current state: exactly what the screen shows.
  SearchScreenControllerProvider._({
    required SearchScreenControllerFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'searchScreenControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$searchScreenControllerHash();

  @override
  String toString() {
    return r'searchScreenControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SearchScreenController create() => SearchScreenController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SearchScreenControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$searchScreenControllerHash() =>
    r'b258c09e0da3d36bb90deadb08c826079f4aae8d';

/// The search screen's text, tokens and filter chips (TASK-B8 §5–§6). The
/// text is parsed 150 ms after the last keystroke; chips apply at once.
/// [folder] is the folder it was opened from ("Only in" chip).
///
/// Recording a recent search: on submit, when the screen closes, or
/// [recordDelay] after a chip change with no change (text or chip) since.
/// Typing cancels a pending chip record, so half-typed text is only saved
/// by submit or close. Empty searches, searches that can't match, and the
/// same query twice in a row are never recorded. What's recorded is always
/// `_parsed` of the current state: exactly what the screen shows.

final class SearchScreenControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          SearchScreenController,
          SearchState,
          SearchState,
          SearchState,
          String?
        > {
  SearchScreenControllerFamily._()
    : super(
        retry: null,
        name: r'searchScreenControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The search screen's text, tokens and filter chips (TASK-B8 §5–§6). The
  /// text is parsed 150 ms after the last keystroke; chips apply at once.
  /// [folder] is the folder it was opened from ("Only in" chip).
  ///
  /// Recording a recent search: on submit, when the screen closes, or
  /// [recordDelay] after a chip change with no change (text or chip) since.
  /// Typing cancels a pending chip record, so half-typed text is only saved
  /// by submit or close. Empty searches, searches that can't match, and the
  /// same query twice in a row are never recorded. What's recorded is always
  /// `_parsed` of the current state: exactly what the screen shows.

  SearchScreenControllerProvider call(String? folder) =>
      SearchScreenControllerProvider._(argument: folder, from: this);

  @override
  String toString() => r'searchScreenControllerProvider';
}

/// The search screen's text, tokens and filter chips (TASK-B8 §5–§6). The
/// text is parsed 150 ms after the last keystroke; chips apply at once.
/// [folder] is the folder it was opened from ("Only in" chip).
///
/// Recording a recent search: on submit, when the screen closes, or
/// [recordDelay] after a chip change with no change (text or chip) since.
/// Typing cancels a pending chip record, so half-typed text is only saved
/// by submit or close. Empty searches, searches that can't match, and the
/// same query twice in a row are never recorded. What's recorded is always
/// `_parsed` of the current state: exactly what the screen shows.

abstract class _$SearchScreenController extends $Notifier<SearchState> {
  late final _$args = ref.$arg as String?;
  String? get folder => _$args;

  SearchState build(String? folder);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<SearchState, SearchState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SearchState, SearchState>,
              SearchState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
