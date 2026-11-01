import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// N1: the device identity (flutter_secure_storage) must never be backed up
/// or moved to another phone. These are the shared-prefs files
/// flutter_secure_storage 11 writes for the default namespace (seen on the
/// API 34 emulator): data, wrapped AES key, and the algorithm config
/// (namespaced, plus the legacy global file it still reads).
const _secureStorageFiles = {
  'FlutterSecureStorage.xml',
  'FlutterSecureKeyStorage.xml',
  'FlutterSecureStorageConfiguration:FlutterSecureStorage.xml',
  'FlutterSecureStorageConfiguration.xml',
};

Set<String> _excluded(String xml) => {
  for (final m in RegExp(
    r'<exclude domain="sharedpref" path="([^"]+)"\s*/>',
  ).allMatches(xml))
    m.group(1)!,
};

String _section(String xml, String tag) =>
    RegExp('<$tag>(.*?)</$tag>', dotAll: true).firstMatch(xml)!.group(1)!;

void main() {
  const dir = 'android/app/src/main/res/xml';

  test('Auto Backup (API 23-30) excludes every secure-storage file', () {
    final xml = File('$dir/backup_rules.xml').readAsStringSync();
    expect(_excluded(xml), _secureStorageFiles);
  });

  test('cloud backup and device transfer (API 31+) exclude them too', () {
    final xml = File('$dir/data_extraction_rules.xml').readAsStringSync();
    expect(_excluded(_section(xml, 'cloud-backup')), _secureStorageFiles);
    expect(_excluded(_section(xml, 'device-transfer')), _secureStorageFiles);
  });
}
