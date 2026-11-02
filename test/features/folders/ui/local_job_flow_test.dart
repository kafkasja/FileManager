import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/external_storage/data/volume_activity_tracker.dart';
import 'package:kfm/features/folders/ui/local_job_flow.dart';

void main() {
  // U3 emulator check: a copy to an SD card being ejected started a job
  // ("Copying 1 file…") that only paused itself.
  test('a job into or out of an ejecting place is refused', () {
    const activity = VolumeActivity(ejecting: {'0000-0000'});
    expect(
      jobTouchesEjectingPlace(
        activity,
        targetPlace: '0000-0000',
        sourcePlaces: const ['primary'],
      ),
      isTrue,
    );
    expect(
      jobTouchesEjectingPlace(
        activity,
        targetPlace: 'primary',
        sourcePlaces: const ['primary', '0000-0000'],
      ),
      isTrue,
    );
    expect(
      jobTouchesEjectingPlace(
        activity,
        targetPlace: 'primary',
        sourcePlaces: const ['1234-ABCD'],
      ),
      isFalse,
    );
  });
}
