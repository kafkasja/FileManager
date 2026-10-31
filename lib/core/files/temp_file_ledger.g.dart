// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'temp_file_ledger.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's ledger (Android). Null elsewhere for now (no `path:` copies).

@ProviderFor(tempFileLedger)
final tempFileLedgerProvider = TempFileLedgerProvider._();

/// The app's ledger (Android). Null elsewhere for now (no `path:` copies).

final class TempFileLedgerProvider
    extends
        $FunctionalProvider<
          AsyncValue<TempFileLedger?>,
          TempFileLedger?,
          FutureOr<TempFileLedger?>
        >
    with $FutureModifier<TempFileLedger?>, $FutureProvider<TempFileLedger?> {
  /// The app's ledger (Android). Null elsewhere for now (no `path:` copies).
  TempFileLedgerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tempFileLedgerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tempFileLedgerHash();

  @$internal
  @override
  $FutureProviderElement<TempFileLedger?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TempFileLedger?> create(Ref ref) {
    return tempFileLedger(ref);
  }
}

String _$tempFileLedgerHash() => r'672d72dc1f8604887ed06beb2ced1cb091020a07';
