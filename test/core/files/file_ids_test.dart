import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/files/file_ids.dart';

void main() {
  test('saf ids round-trip, document ids may hold / : and |', () {
    const tree =
        'content://com.android.externalstorage.documents/tree/1234-ABCD%3A';
    for (final doc in ['1234-ABCD:', '1234-ABCD:DCIM/a b.jpg', 'x:y|z']) {
      final id = safId(tree, doc);
      expect(id, startsWith('saf:'));
      expect(parseSafId(id), SafId(tree, doc));
    }
  });

  test('mtp ids round-trip', () {
    final id = mtpId('/dev/bus/usb/001/002', 65537, 42);
    expect(id, 'mtp:/dev/bus/usb/001/002|65537|42');
    expect(parseMtpId(id), const MtpId('/dev/bus/usb/001/002', 65537, 42));
  });

  test('malformed ids parse to null', () {
    expect(parseSafId('ms:12'), isNull);
    expect(parseSafId('saf:no-bar'), isNull);
    expect(parseSafId('saf:|doc'), isNull);
    expect(parseMtpId('mtp:dev|1'), isNull);
    expect(parseMtpId('mtp:dev|x|2'), isNull);
    expect(parseMtpId('mtp:|1|2'), isNull);
    expect(parseMtpId('path:/x'), isNull);
  });

  test('a | in the tree uri or device name is refused', () {
    expect(() => safId('a|b', 'c'), throwsArgumentError);
    expect(() => mtpId('', 1, 2), throwsArgumentError);
  });
}
