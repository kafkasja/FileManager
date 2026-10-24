import 'dart:convert';

import 'package:meta/meta.dart';

/// A setting declared once with its type and default. Features add their keys
/// to `AppSettings` instead of using raw strings.
@immutable
class SettingKey<T extends Object> {
  const new(
    this.name,
    this.defaultValue, {
    required this.decode,
    required this.encode,
  });

  final String name;
  final T defaultValue;

  /// Turns decoded JSON into [T]; returns [defaultValue] for unexpected input.
  final T Function(Object? json) decode;
  final Object? Function(T value) encode;

  static SettingKey<bool> boolean(String name, {required bool defaultValue}) =>
      SettingKey<bool>(
        name,
        defaultValue,
        decode: (j) => j is bool ? j : defaultValue,
        encode: (v) => v,
      );

  static SettingKey<int> integer(String name, int defaultValue) =>
      SettingKey<int>(
        name,
        defaultValue,
        decode: (j) => j is int ? j : defaultValue,
        encode: (v) => v,
      );

  static SettingKey<String> string(String name, String defaultValue) =>
      SettingKey<String>(
        name,
        defaultValue,
        decode: (j) => j is String ? j : defaultValue,
        encode: (v) => v,
      );

  static SettingKey<E> enumeration<E extends Enum>(
    String name,
    E defaultValue,
    List<E> values,
  ) => SettingKey<E>(
    name,
    defaultValue,
    decode: (j) =>
        values.firstWhere((e) => e.name == j, orElse: () => defaultValue),
    encode: (v) => v.name,
  );

  String encodeToDb(T value) => jsonEncode(encode(value));

  /// Corrupt rows fall back to [defaultValue]; reading a setting never throws.
  T decodeFromDb(String raw) {
    try {
      return decode(jsonDecode(raw));
    } on FormatException {
      return defaultValue;
    }
  }
}
