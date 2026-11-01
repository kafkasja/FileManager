import 'dart:typed_data';

import 'package:kfm/core/files/file_ref.dart';
import 'package:kfm/features/details/domain/known_files.dart';
import 'package:kfm/features/details/domain/path_app.dart';
import 'package:meta/meta.dart';

/// EXIF facts shown in file details (TASK-B10; read by C5's reader).
@immutable
class ExifDetails {
  const new({
    this.make,
    this.model,
    this.software,
    this.lens,
    this.iso,
    this.exposureSeconds,
    this.fNumber,
    this.focalLengthMm,
    this.description,
    this.userComment,
    this.lat,
    this.lng,
  });

  final String? make;
  final String? model;
  final String? software;
  final String? lens;
  final int? iso;
  final double? exposureSeconds;
  final double? fNumber;
  final double? focalLengthMm;
  final String? description;
  final String? userComment;
  final double? lat;
  final double? lng;

  /// 'Samsung SM-S908B'; the make is dropped when the model repeats it
  /// ('Canon' + 'Canon EOS R6' → 'Canon EOS R6').
  String? get camera {
    final make = this.make;
    final model = this.model;
    if (model == null) return make;
    if (make == null ||
        model.toLowerCase().startsWith(make.toLowerCase().split(' ').first)) {
      return model;
    }
    return '$make $model';
  }

  /// [software] unless it's just firmware ('S908BXXU2AVF1') or the model.
  String? get editor {
    final s = software;
    if (s == null) return null;
    if (_firmware.hasMatch(s)) return null;
    if (model != null && s.toLowerCase() == model!.toLowerCase()) return null;
    return s;
  }

  static final _firmware = RegExp(r'^[A-Z0-9_.-]{8,}$');

  bool get hasLocation => lat != null && lng != null;

  bool get hasSettings =>
      iso != null ||
      exposureSeconds != null ||
      fNumber != null ||
      focalLengthMm != null;
}

/// Where the file came from as the platform knows it.
@immutable
class OwnerApp {
  const new({
    required this.packageName,
    this.label,
    this.icon,
    this.installed = false,
  });

  final String packageName;

  /// The installed app's label, else the known-apps name, else null.
  final String? label;

  /// PNG, 48 dp; only for installed, visible apps.
  final Uint8List? icon;

  /// Visible to us right now (App info can be opened).
  final bool installed;
}

/// Everything the details sheet shows for one file (TASK-B10). Nothing is
/// stored: built on open by `FileDetailsRepository.load`.
@immutable
class FileDetails {
  const new({
    required this.file,
    required this.path,
    this.exists,
    this.mimeType,
    this.addedAt,
    this.ownerPackage,
    this.owner,
    this.downloadUri,
    this.refererUri,
    this.exif,
    this.pathApp,
    this.explanation,
    this.volumeLabel,
    this.volumeKind = VolumeKind.unknown,
    this.placeName,
    this.partial = false,
  });

  /// The FileRef as indexed.
  final FileRef file;

  /// Absolute path ('' for remote files).
  final String path;

  /// False: the file is gone. Null: couldn't tell.
  final bool? exists;

  /// MediaStore MIME, else the FileRef's.
  final String? mimeType;

  /// MediaStore DATE_ADDED: when it arrived on the phone.
  final DateTime? addedAt;

  /// MediaStore OWNER_PACKAGE_NAME (API 29+).
  final String? ownerPackage;

  /// The app named by [ownerPackage], else by [pathApp]; resolved.
  final OwnerApp? owner;

  /// MediaStore.Downloads DOWNLOAD_URI / REFERER_URI (API 29+). Shown,
  /// never fetched.
  final String? downloadUri;
  final String? refererUri;
  final ExifDetails? exif;
  final PathApp? pathApp;
  final KnownFileKind? explanation;

  /// The storage volume's own label (removable volumes).
  final String? volumeLabel;
  final VolumeKind volumeKind;

  /// C5's stored place name for the file's place group, if any (no
  /// lookup here).
  final String? placeName;

  /// Some details couldn't be read (rule 8: shown inline).
  final bool partial;

  /// [owner] came from the MediaStore owner, not only from the folder.
  bool get ownerFromMediaStore =>
      ownerPackage != null && owner?.packageName == ownerPackage;
}

enum VolumeKind { unknown, internal, removable }

/// 'https://www.example.com/a?b' → 'www.example.com'; null if no host.
String? hostOf(String? url) {
  if (url == null) return null;
  final uri = Uri.tryParse(url.trim());
  final host = uri?.host;
  return host == null || host.isEmpty ? null : host;
}
