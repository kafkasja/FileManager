import 'dart:io';
import 'dart:typed_data';

import 'package:kfm/core/files/cross_place_ops.dart';
import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/core/files/file_source.dart';
import 'package:kfm/core/files/mtp/mtp_file_source.dart';
import 'package:kfm/core/files/routing_file_source.dart';
import 'package:kfm/core/files/saf/saf_file_source.dart';

import 'fake_file_source.dart';
import 'fake_saf_platform.dart';

class FakeMtp implements MtpObjectsPlatform {
  final Map<int, (String, List<int>)> objects = {
    7: ('IMG_7.JPG', [7, 7]),
  };

  @override
  Future<bool> canDelete(String device) async => false;

  @override
  Future<List<MtpObject>> children(
    String device,
    int storage,
    int parent,
  ) async => [
    for (final MapEntry(key: h, value: (name, bytes)) in objects.entries)
      MtpObject(
        handle: h,
        storage: storage,
        name: name,
        isFolder: false,
        sizeBytes: bytes.length,
        modifiedSec: 100,
      ),
  ];

  @override
  Future<bool> delete(String device, int handle) async => false;

  @override
  Future<bool> importTo(String device, int handle, String path) async {
    await File(path).writeAsBytes(objects[handle]!.$2);
    return true;
  }

  @override
  Future<MtpObject?> info(String device, int handle) async {
    final o = objects[handle];
    if (o == null) return null;
    return MtpObject(
      handle: handle,
      storage: 1,
      name: o.$1,
      isFolder: false,
      sizeBytes: o.$2.length,
      modifiedSec: 100,
      path: 'DCIM',
    );
  }

  @override
  Future<List<({String description, int id})>> storages(String device) async =>
      [(id: 1, description: 'SD')];

  @override
  Future<Uint8List?> thumbnail(String device, int handle) async => null;
}

/// Device storage (fake) + one SAF volume + a camera behind the router.
class Setup {
  new({Future<String> Function(FileRef f, FileSource s)? hashRef}) {
    android.addFolder('$internal/Pictures');
    router = RoutingFileSource(
      android: android,
      saf: saf,
      mtp: mtp,
      crossPlace: (self) => CrossPlaceOps(
        sourceOfId: self.sourceForId,
        sourceOfFolder: self.sourceForFolder,
        staging: () async => staging,
        hashRef: hashRef,
      ),
    );
  }

  static const internal = '/storage/emulated/0';
  final FakeFileSource android = FakeFileSource();
  final FakeSafPlatform safFake = FakeSafPlatform();

  /// False = the SAF grant is gone (U2 review #8).
  bool granted = true;
  late final SafFileSource saf = SafFileSource(
    channel: safFake,
    trees: () => [if (granted) safFake.tree],
  );
  final MtpFileSource mtp = MtpFileSource(channel: FakeMtp());
  late final RoutingFileSource router;
  final Directory staging = Directory.systemTemp.createTempSync('kfm_xp');

  String get usb => safFake.root;

  Future<FileRef> safFile(String rel, List<int> bytes) async {
    safFake.addFile('$usb/$rel', bytes);
    return (await saf.statPath('$usb/$rel'))!;
  }

  Future<void> dispose() async {
    await router.dispose();
    await saf.dispose();
    await android.dispose();
    if (staging.existsSync()) staging.deleteSync(recursive: true);
  }
}
