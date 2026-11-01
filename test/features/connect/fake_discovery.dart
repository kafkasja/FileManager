import 'dart:async';

import 'package:kfm/features/connect/data/discovery.dart';

/// In-memory [ShareDiscovery] for N2 tests.
class FakeDiscovery implements ShareDiscovery {
  final List<ShareAdvert> adverts = [];
  int stops = 0;
  Object? advertiseError;

  /// What `browse()` emits; add lists to it in tests.
  final StreamController<List<NearbyDevice>> nearby =
      StreamController.broadcast();

  @override
  Future<void> advertise(ShareAdvert advert) async {
    final e = advertiseError;
    // ignore: only_throw_errors, the test decides what to throw
    if (e != null) throw e;
    adverts.add(advert);
  }

  @override
  Future<void> stopAdvertising() async => stops++;

  @override
  Stream<List<NearbyDevice>> browse() => nearby.stream;
}
