// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'desktop_command_bar.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The commands the screen of each section shows in the shell's command
/// bar. Screens publish them after each build.

@ProviderFor(DesktopCommands)
final desktopCommandsProvider = DesktopCommandsFamily._();

/// The commands the screen of each section shows in the shell's command
/// bar. Screens publish them after each build.
final class DesktopCommandsProvider
    extends $NotifierProvider<DesktopCommands, List<DesktopCommand>> {
  /// The commands the screen of each section shows in the shell's command
  /// bar. Screens publish them after each build.
  DesktopCommandsProvider._({
    required DesktopCommandsFamily super.from,
    required DesktopSection super.argument,
  }) : super(
         retry: null,
         name: r'desktopCommandsProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$desktopCommandsHash();

  @override
  String toString() {
    return r'desktopCommandsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  DesktopCommands create() => DesktopCommands();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<DesktopCommand> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<DesktopCommand>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DesktopCommandsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$desktopCommandsHash() => r'aae03a85ccf9875b48435a8f276ee67d8978ce47';

/// The commands the screen of each section shows in the shell's command
/// bar. Screens publish them after each build.

final class DesktopCommandsFamily extends $Family
    with
        $ClassFamilyOverride<
          DesktopCommands,
          List<DesktopCommand>,
          List<DesktopCommand>,
          List<DesktopCommand>,
          DesktopSection
        > {
  DesktopCommandsFamily._()
    : super(
        retry: null,
        name: r'desktopCommandsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// The commands the screen of each section shows in the shell's command
  /// bar. Screens publish them after each build.

  DesktopCommandsProvider call(DesktopSection section) =>
      DesktopCommandsProvider._(argument: section, from: this);

  @override
  String toString() => r'desktopCommandsProvider';
}

/// The commands the screen of each section shows in the shell's command
/// bar. Screens publish them after each build.

abstract class _$DesktopCommands extends $Notifier<List<DesktopCommand>> {
  late final _$args = ref.$arg as DesktopSection;
  DesktopSection get section => _$args;

  List<DesktopCommand> build(DesktopSection section);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<DesktopCommand>, List<DesktopCommand>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<DesktopCommand>, List<DesktopCommand>>,
              List<DesktopCommand>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
