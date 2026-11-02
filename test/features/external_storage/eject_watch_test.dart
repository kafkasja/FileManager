import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/external_storage/data/eject_watch.dart';
import 'package:kfm/features/external_storage/data/places_watcher.dart';
import 'package:kfm/features/external_storage/domain/storage_place.dart';

const _sd = StoragePlace(
  id: '1234-ABCD',
  label: 'SD',
  kind: PlaceKind.sdCard,
  access: AccessMethod.directPath,
  isMounted: true,
  rootPath: '/storage/1234-ABCD',
);

void main() {
  test('back in the app still mounted: not yet; 30 s in the foreground '
      'cancels the eject (background time does not count)', () {
    fakeAsync((async) {
      final cancelled = <String>[];
      final watch = EjectWatch(cancelEject: cancelled.add);
      final notices = <EjectNotYet>[];
      watch.notices.listen(notices.add);
      watch
        ..start(_sd)
        ..onBackground();
      async.elapse(const Duration(minutes: 5)); // in settings
      expect(cancelled, isEmpty);
      watch.onForeground();
      async.elapse(const Duration(seconds: 2));
      expect(notices.single.place.id, '1234-ABCD');
      async.elapse(const Duration(seconds: 27));
      expect(cancelled, isEmpty);
      async.elapse(const Duration(seconds: 2));
      expect(cancelled, ['1234-ABCD']);
      expect(watch.waitingFor, isNull);
      watch.dispose();
    });
  });

  test('an unmount stops the watch: no notice, no cancel', () {
    fakeAsync((async) {
      final cancelled = <String>[];
      final watch = EjectWatch(cancelEject: cancelled.add);
      final notices = <EjectNotYet>[];
      watch.notices.listen(notices.add);
      watch
        ..start(_sd)
        ..onBackground()
        ..onForeground()
        ..stop('1234-ABCD');
      async.elapse(const Duration(minutes: 1));
      expect(notices, isEmpty);
      expect(cancelled, isEmpty);
      watch.dispose();
    });
  });

  test('PlacesWatcher: a removed place that was ejecting is PlaceEjected', () {
    fakeAsync((async) {
      final ejected = <String>[];
      final watcher = PlacesWatcher(
        scanRoot: (_) async {},
        isEjecting: (id) => id == '1234-ABCD',
        onEjected: ejected.add,
      );
      final notices = <ExternalNotice>[];
      watcher.notices.listen(notices.add);
      watcher
        ..onPlaces([_sd])
        ..onPlaces(const []);
      async.flushMicrotasks();
      expect(notices.single, isA<PlaceEjected>());
      expect(ejected, ['1234-ABCD']);
      watcher.dispose();
    });
  });
}
