import 'dart:math';

/// A 128-bit random id as 32 lowercase hex characters (16 bytes from
/// [random], default `Random.secure()`). Used by D4's pending folder and by
/// every Phase 5 id (device id, pair attempt id); no `uuid` package.
String randomHexId([Random? random]) {
  final r = random ?? Random.secure();
  return List.generate(
    16,
    (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}
