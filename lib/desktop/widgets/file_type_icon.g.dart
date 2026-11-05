// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_type_icon.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The chosen icon style; KFM icons wherever the shell has none (not
/// Windows, tests).

@ProviderFor(desktopIconStyle)
final desktopIconStyleProvider = DesktopIconStyleProvider._();

/// The chosen icon style; KFM icons wherever the shell has none (not
/// Windows, tests).

final class DesktopIconStyleProvider
    extends
        $FunctionalProvider<
          AsyncValue<DesktopIconStyle>,
          DesktopIconStyle,
          Stream<DesktopIconStyle>
        >
    with $FutureModifier<DesktopIconStyle>, $StreamProvider<DesktopIconStyle> {
  /// The chosen icon style; KFM icons wherever the shell has none (not
  /// Windows, tests).
  DesktopIconStyleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'desktopIconStyleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$desktopIconStyleHash();

  @$internal
  @override
  $StreamProviderElement<DesktopIconStyle> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<DesktopIconStyle> create(Ref ref) {
    return desktopIconStyle(ref);
  }
}

String _$desktopIconStyleHash() => r'0d134d17dd8fa8b6948e5bc62b6eaeb02fb40f55';

/// The shell icon cache, null without the Windows shell.

@ProviderFor(shellIconCache)
final shellIconCacheProvider = ShellIconCacheProvider._();

/// The shell icon cache, null without the Windows shell.

final class ShellIconCacheProvider
    extends
        $FunctionalProvider<ShellIconCache?, ShellIconCache?, ShellIconCache?>
    with $Provider<ShellIconCache?> {
  /// The shell icon cache, null without the Windows shell.
  ShellIconCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shellIconCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shellIconCacheHash();

  @$internal
  @override
  $ProviderElement<ShellIconCache?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ShellIconCache? create(Ref ref) {
    return shellIconCache(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShellIconCache? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShellIconCache?>(value),
    );
  }
}

String _$shellIconCacheHash() => r'6ef6ce3525ff1f464c8fe5af6a91574ae5a453da';

/// Known folders (lower-case paths) that get their own shell icon
/// (Downloads' arrow, Pictures' image…).

@ProviderFor(shellSpecialFolders)
final shellSpecialFoldersProvider = ShellSpecialFoldersProvider._();

/// Known folders (lower-case paths) that get their own shell icon
/// (Downloads' arrow, Pictures' image…).

final class ShellSpecialFoldersProvider
    extends
        $FunctionalProvider<
          AsyncValue<Set<String>>,
          Set<String>,
          FutureOr<Set<String>>
        >
    with $FutureModifier<Set<String>>, $FutureProvider<Set<String>> {
  /// Known folders (lower-case paths) that get their own shell icon
  /// (Downloads' arrow, Pictures' image…).
  ShellSpecialFoldersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shellSpecialFoldersProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shellSpecialFoldersHash();

  @$internal
  @override
  $FutureProviderElement<Set<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Set<String>> create(Ref ref) {
    return shellSpecialFolders(ref);
  }
}

String _$shellSpecialFoldersHash() =>
    r'bc6758cd85a8a097c128e4ae3ee1206146554cb1';

/// Explorer's type name for [ext] (`.jpg` → "JPEG image", `folder` → "File
/// folder"); null when there's no shell or it knows none. Cached for the
/// run.

@ProviderFor(shellTypeName)
final shellTypeNameProvider = ShellTypeNameFamily._();

/// Explorer's type name for [ext] (`.jpg` → "JPEG image", `folder` → "File
/// folder"); null when there's no shell or it knows none. Cached for the
/// run.

final class ShellTypeNameProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  /// Explorer's type name for [ext] (`.jpg` → "JPEG image", `folder` → "File
  /// folder"); null when there's no shell or it knows none. Cached for the
  /// run.
  ShellTypeNameProvider._({
    required ShellTypeNameFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'shellTypeNameProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$shellTypeNameHash();

  @override
  String toString() {
    return r'shellTypeNameProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    final argument = this.argument as String;
    return shellTypeName(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ShellTypeNameProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$shellTypeNameHash() => r'3e5c5be30bdf26089d36792dba9576be33b5e78f';

/// Explorer's type name for [ext] (`.jpg` → "JPEG image", `folder` → "File
/// folder"); null when there's no shell or it knows none. Cached for the
/// run.

final class ShellTypeNameFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String?>, String> {
  ShellTypeNameFamily._()
    : super(
        retry: null,
        name: r'shellTypeNameProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// Explorer's type name for [ext] (`.jpg` → "JPEG image", `folder` → "File
  /// folder"); null when there's no shell or it knows none. Cached for the
  /// run.

  ShellTypeNameProvider call(String ext) =>
      ShellTypeNameProvider._(argument: ext, from: this);

  @override
  String toString() => r'shellTypeNameProvider';
}
