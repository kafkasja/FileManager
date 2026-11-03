import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/cloud/domain/cloud_state.dart';

CloudUploadFact _u({int dest = 1, int size = 100, int ms = 5000}) =>
    CloudUploadFact(
      destinationId: dest,
      sizeBytes: size,
      sourceModifiedAtMs: ms,
      uploadedAtMs: 9000,
    );

CloudBadge _badge(List<CloudUploadFact> uploads) => cloudBadgeFor(
  uploads: uploads,
  localSizeBytes: 100,
  localModifiedAtMs: 5000,
);

void main() {
  test('no uploads → none', () {
    expect(_badge(const []), CloudBadge.none);
  });

  test('unchanged → onCloud (ms precision, no seconds rounding)', () {
    expect(_badge([_u()]), CloudBadge.onCloud);
    expect(_badge([_u(ms: 5001)]), CloudBadge.changedSinceUpload);
  });

  test('size differs or modified ms newer/older → changedSinceUpload', () {
    expect(_badge([_u(size: 101)]), CloudBadge.changedSinceUpload);
    expect(_badge([_u(ms: 9999)]), CloudBadge.changedSinceUpload);
    expect(_badge([_u(ms: 1)]), CloudBadge.changedSinceUpload);
  });

  test('two destinations, one unchanged → onCloud', () {
    expect(_badge([_u(ms: 1), _u(dest: 2)]), CloudBadge.onCloud);
  });
}
