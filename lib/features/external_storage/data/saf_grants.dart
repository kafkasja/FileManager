import 'dart:io';

import 'package:kfm/core/db/db_providers.dart';
import 'package:kfm/core/db/settings/app_settings.dart';
import 'package:kfm/core/db/settings/settings_repository.dart';
import 'package:kfm/core/files/android/files_channel.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'saf_grants.g.dart';

/// The SAF tree picker and persisted grants (Android: `SafTrees.kt` on the
/// files channel; X3 reuses it).
abstract interface class SafTreePlatform {
  Future<({String uri, String? treeDocumentId})?> pickTree({String? uuid});
  Future<bool> persistTree(String uri);
  Future<bool> releaseTree(String uri);
  Future<List<String>> persistedTrees();
  Future<bool> validateTree(String uri);
}

class ChannelSafTreePlatform implements SafTreePlatform {
  const new(this._channel);

  final FilesChannel _channel;

  @override
  Future<({String uri, String? treeDocumentId})?> pickTree({String? uuid}) =>
      _channel.pickTree(uuid: uuid);

  @override
  Future<bool> persistTree(String uri) => _channel.persistTree(uri);

  @override
  Future<bool> releaseTree(String uri) => _channel.releaseTree(uri);

  @override
  Future<List<String>> persistedTrees() => _channel.persistedTrees();

  @override
  Future<bool> validateTree(String uri) => _channel.validateTree(uri);
}

/// How [SafGrants.grant] ended.
enum GrantOutcome {
  granted,
  cancelled,

  /// A subfolder (or another volume) was picked: nothing saved.
  wrongFolder,

  /// The system refused to keep the grant.
  failed,
}

/// U1: one SAF grant per volume uuid, kept in
/// [AppSettings.externalSafGrants].
class SafGrants {
  const new(this._platform, this._settings);

  final SafTreePlatform _platform;
  final SettingsRepository _settings;

  /// The picker at the volume [uuid]; only the volume's root is accepted
  /// (checked before the grant is persisted, so a wrong pick keeps
  /// nothing).
  Future<GrantOutcome> grant(String uuid) async {
    final picked = await _platform.pickTree(uuid: uuid);
    if (picked == null) return GrantOutcome.cancelled;
    if (picked.treeDocumentId != '$uuid:') return GrantOutcome.wrongFolder;
    if (!await _platform.persistTree(picked.uri)) return GrantOutcome.failed;
    final grants = await _settings.read(AppSettings.externalSafGrants);
    await _settings.write(AppSettings.externalSafGrants, {
      ...grants,
      uuid: picked.uri,
    });
    return GrantOutcome.granted;
  }

  /// Still persisted and the root still accepts new files. A reformatted
  /// stick with the same uuid fails.
  Future<bool> isValid(String treeUri) async =>
      (await _platform.persistedTrees()).contains(treeUri) &&
      await _platform.validateTree(treeUri);

  /// Forgets the grant of [uuid] (released when still held).
  Future<void> drop(String uuid) async {
    final grants = await _settings.read(AppSettings.externalSafGrants);
    final uri = grants[uuid];
    if (uri == null) return;
    await _settings.write(AppSettings.externalSafGrants, {
      for (final MapEntry(:key, :value) in grants.entries)
        if (key != uuid) key: value,
    });
    if ((await _platform.persistedTrees()).contains(uri)) {
      await _platform.releaseTree(uri);
    }
  }
}

/// Null off Android.
@Riverpod(keepAlive: true)
SafTreePlatform? safTreePlatform(Ref ref) =>
    Platform.isAndroid ? ChannelSafTreePlatform(FilesChannel()) : null;

/// Null off Android.
@Riverpod(keepAlive: true)
SafGrants? safGrants(Ref ref) {
  final platform = ref.watch(safTreePlatformProvider);
  return platform == null
      ? null
      : SafGrants(platform, ref.watch(settingsRepositoryProvider));
}
