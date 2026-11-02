import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/swipe/data/swipe_action_dispatcher.dart';
import 'package:kfm/features/swipe/domain/swipe_action.dart';
import 'package:kfm/features/undo/domain/previous_state.dart';

void main() {
  const send = SwipeAction(
    SwipeActionType.sendToDevice,
    deviceId: 'pc',
    targetFolder: 'cam/Phone',
  );
  SwipeActionProblem? problem(
    SwipeAction a, {
    RemoteSwipeRules? remote,
    Set<String>? known,
  }) => SwipeActionDispatcher.problemFor(
    a,
    const {},
    remote: remote,
    knownDeviceIds: known,
  );

  test('a local send needs a remembered device and a folder', () {
    expect(problem(send, known: {'pc'}), isNull);
    expect(problem(send), isNull); // devices not loaded: not checked
    expect(problem(send, known: {'other'}), SwipeActionProblem.deviceMissing);
    expect(
      problem(const SwipeAction(SwipeActionType.sendToDevice, deviceId: 'pc')),
      SwipeActionProblem.unsupported,
    );
    expect(
      problem(const SwipeAction(SwipeActionType.sendToDevice)),
      SwipeActionProblem.unsupported,
    );
  });

  test('in a remote session only "to that device" (a download) works', () {
    expect(
      problem(send, remote: const RemoteSwipeRules(peerDeviceId: 'pc')),
      isNull,
    );
    expect(
      problem(send, remote: const RemoteSwipeRules(peerDeviceId: 'phone')),
      SwipeActionProblem.notOnDevice,
    );
    expect(
      problem(send, remote: const RemoteSwipeRules()),
      SwipeActionProblem.notOnDevice,
    );
  });

  test('the undo row keeps the transfer file; old rows stay readable', () {
    final s = PreviousState.fromJson(
      SwipeActionType.sendToDevice,
      const SendPreviousState(transferFileId: 7).toJson(),
    );
    expect(s, isA<SendPreviousState>());
    expect((s as SendPreviousState).transferFileId, 7);
    expect(
      PreviousState.fromJson(SwipeActionType.sendToDevice, const {}),
      isA<NoPreviousState>(),
    );
  });
}
