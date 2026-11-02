import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

/// A camera on USB (PTP/MTP) as `MtpChannel.kt` reports it (TASK-U1).
@immutable
class UsbCamera {
  const new({
    required this.deviceName,
    required this.hasPermission,
    this.product,
    this.manufacturer,
    this.model,
    this.supported,
  });

  factory fromRow(Map<Object?, Object?> r) {
    String? str(Object? v) =>
        v is String && v.trim().isNotEmpty ? v.trim() : null;
    final supported = r['supported'];
    return UsbCamera(
      deviceName: str(r['deviceName']) ?? '',
      hasPermission: r['hasPermission'] == true,
      product: str(r['product']),
      manufacturer: str(r['manufacturer']),
      model: str(r['model']),
      supported: supported is bool ? supported : null,
    );
  }

  /// `UsbDevice.getDeviceName()`; the stable key while attached.
  final String deviceName;
  final bool hasPermission;
  final String? product;
  final String? manufacturer;

  /// From the camera itself (only with permission).
  final String? model;

  /// Null = not checked (no permission); false = MtpDevice.open failed.
  final bool? supported;

  /// The best name there is ('' when the device says nothing).
  String get name => model ?? product ?? manufacturer ?? '';

  @override
  bool operator ==(Object other) =>
      other is UsbCamera &&
      other.deviceName == deviceName &&
      other.hasPermission == hasPermission &&
      other.product == product &&
      other.manufacturer == manufacturer &&
      other.model == model &&
      other.supported == supported;

  @override
  int get hashCode => Object.hash(
    deviceName,
    hasPermission,
    product,
    manufacturer,
    model,
    supported,
  );
}

/// Cameras over USB (Android: [MtpChannel]).
abstract interface class MtpPlatform {
  Future<List<UsbCamera>> list();

  /// Shows the system USB permission prompt; the answer arrives as a
  /// [changes] tick. False when the camera is gone.
  Future<bool> requestPermission(String deviceName);

  /// Attach, detach and permission answers (broadcast).
  Stream<void> changes();
}

/// Typed wrapper around `com.kaf.kfm/mtp` (+ `/events`).
class MtpChannel implements MtpPlatform {
  new({MethodChannel? channel, EventChannel? events})
    : _channel = channel ?? const MethodChannel(name),
      _events = events ?? const EventChannel(eventsName);

  static const name = 'com.kaf.kfm/mtp';
  static const eventsName = 'com.kaf.kfm/mtp/events';

  final MethodChannel _channel;
  final EventChannel _events;

  @override
  Future<List<UsbCamera>> list() async {
    final rows =
        await _channel.invokeListMethod<Map<Object?, Object?>>('list') ??
        const [];
    return [
      for (final r in rows)
        if (UsbCamera.fromRow(r) case final c when c.deviceName.isNotEmpty) c,
    ];
  }

  @override
  Future<bool> requestPermission(String deviceName) async =>
      await _channel.invokeMethod<bool>('requestPermission', {
        'deviceName': deviceName,
      }) ??
      false;

  @override
  Stream<void> changes() => _events.receiveBroadcastStream().map((_) {});
}
