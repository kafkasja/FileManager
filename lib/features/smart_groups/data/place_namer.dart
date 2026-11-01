import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'place_namer.g.dart';

/// Names a place group's centre (TASK-C5 §8). Called once per group
/// centre, never per photo, and only while "Look up place names online" is
/// on.
abstract interface class PlaceNamer {
  /// Null when offline naming is used or the lookup fails.
  Future<String?> nameFor(double lat, double lng);
}

/// No lookups: "Place N" titles.
class OfflinePlaceNamer implements PlaceNamer {
  const new();

  @override
  Future<String?> nameFor(double lat, double lng) async => null;
}

/// Android `Geocoder` through `com.kaf.kfm/geocoder` (GeocoderChannel.kt).
/// Best effort: failures are logged and answer null.
class GeocoderPlaceNamer implements PlaceNamer {
  new([MethodChannel? channel])
    : _channel = channel ?? const MethodChannel('com.kaf.kfm/geocoder');

  final MethodChannel _channel;

  @override
  Future<String?> nameFor(double lat, double lng) async {
    try {
      final name = await _channel.invokeMethod<String>('nameFor', {
        'lat': lat,
        'lng': lng,
      });
      final trimmed = name?.trim();
      return trimmed == null || trimmed.isEmpty ? null : trimmed;
    } on PlatformException catch (e, st) {
      developer.log(
        'geocode failed',
        name: 'kfm.groups',
        error: e,
        stackTrace: st,
      );
      return null;
    } on MissingPluginException catch (e) {
      developer.log('geocoder missing', name: 'kfm.groups', error: e);
      return null;
    }
  }
}

/// The online namer (used only while the setting is on; the job checks).
@Riverpod(keepAlive: true)
PlaceNamer placeNamer(Ref ref) =>
    Platform.isAndroid ? GeocoderPlaceNamer() : const OfflinePlaceNamer();
