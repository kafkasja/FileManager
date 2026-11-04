import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/swipe/ui/video_surface.dart';
import 'package:video_player/video_player.dart';

void main() {
  VideoPlayerValue at(Duration position, Duration duration) =>
      VideoPlayerValue(duration: duration, position: position);

  test('counts down while the video plays', () {
    const total = Duration(seconds: 90);
    expect(videoTimeLeft(at(Duration.zero, total), fallbackMs: 0), total);
    expect(
      videoTimeLeft(at(const Duration(seconds: 30), total), fallbackMs: 0),
      const Duration(seconds: 60),
    );
    expect(
      videoTimeLeft(at(const Duration(seconds: 89), total), fallbackMs: 0),
      const Duration(seconds: 1),
    );
  });

  test("uses MediaStore's length until the player knows it", () {
    expect(
      videoTimeLeft(
        at(const Duration(seconds: 5), Duration.zero),
        fallbackMs: 20000,
      ),
      const Duration(seconds: 15),
    );
  });

  test('never negative past the end', () {
    expect(
      videoTimeLeft(
        at(const Duration(seconds: 12), const Duration(seconds: 10)),
        fallbackMs: 0,
      ),
      Duration.zero,
    );
  });
}
