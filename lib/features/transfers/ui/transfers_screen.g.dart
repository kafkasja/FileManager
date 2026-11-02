// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfers_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(transferSections)
final transferSectionsProvider = TransferSectionsProvider._();

final class TransferSectionsProvider
    extends
        $FunctionalProvider<
          List<TransferSection>,
          List<TransferSection>,
          List<TransferSection>
        >
    with $Provider<List<TransferSection>> {
  TransferSectionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transferSectionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transferSectionsHash();

  @$internal
  @override
  $ProviderElement<List<TransferSection>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  List<TransferSection> create(Ref ref) {
    return transferSections(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<TransferSection> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<TransferSection>>(value),
    );
  }
}

String _$transferSectionsHash() => r'7b65ddb739bebb84a9b89c6fcf4079a0c6d33afe';
