// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_operation_runner.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(fileOperationRunner)
final fileOperationRunnerProvider = FileOperationRunnerProvider._();

final class FileOperationRunnerProvider
    extends
        $FunctionalProvider<
          FileOperationRunner,
          FileOperationRunner,
          FileOperationRunner
        >
    with $Provider<FileOperationRunner> {
  FileOperationRunnerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fileOperationRunnerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fileOperationRunnerHash();

  @$internal
  @override
  $ProviderElement<FileOperationRunner> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FileOperationRunner create(Ref ref) {
    return fileOperationRunner(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FileOperationRunner value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FileOperationRunner>(value),
    );
  }
}

String _$fileOperationRunnerHash() =>
    r'0fab2ef12888733e66a2ade7131448c0214c1904';
