import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/platform/volumes/volumes_channel.dart';

class _Handler extends MockStreamHandler {
  MockStreamHandlerEventSink? sink;
  int listens = 0;

  @override
  void onListen(Object? arguments, MockStreamHandlerEventSink events) {
    listens++;
    sink = events;
  }

  @override
  void onCancel(Object? arguments) => sink = null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // U3 emulator check: the places list and the places watcher both listen;
  // a second `receiveBroadcastStream()` took the events from the first.
  test('every listener of events() gets volume events', () async {
    const channel = EventChannel(VolumesChannel.eventsName);
    final handler = _Handler();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(channel, handler);
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(channel, null),
    );

    final volumes = VolumesChannel();
    final a = <VolumeEvent>[];
    final b = <VolumeEvent>[];
    final subA = volumes.events().listen(a.add);
    final subB = volumes.events().listen(b.add);
    await pumpEventQueue();
    handler.sink!.success({'uuid': '0000-0000', 'state': 'unmounted'});
    await pumpEventQueue();

    expect(handler.listens, 1);
    expect(a, hasLength(1));
    expect(b, hasLength(1));
    expect((a.single as VolumeStateChanged).state, 'unmounted');
    await subA.cancel();
    await subB.cancel();
  });
}
