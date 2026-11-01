import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/connect/domain/pairing.dart';

final _secret = Uint8List.fromList(List.generate(32, (i) => i * 7));
final String _fp = 'a1' * 32;
final String _k = base64Url.encode(_secret).replaceAll('=', '');

PairingOffer _offer({String name = 'Kaf phone'}) => PairingOffer(
  addresses: const [
    (host: '192.168.1.23', port: 48211),
    (host: '192.168.43.1', port: 48211),
  ],
  serverFingerprint: _fp,
  secret: _secret,
  deviceName: name,
);

void main() {
  group('PairingOffer', () {
    test('toUri / parse round trip', () {
      final uri = _offer(name: 'Kaf’s phone & tab').toUri();
      expect(uri, startsWith('kfm1://pair?v=1&a=192.168.1.23:48211,'));
      final back = PairingOffer.parse(uri);
      expect(back.addresses, _offer().addresses);
      expect(back.serverFingerprint, _fp);
      expect(back.secret, _secret);
      expect(back.deviceName, 'Kaf’s phone & tab');
    });

    test('the QR payload format of the plan parses', () {
      final o = PairingOffer.parse(
        'kfm1://pair?v=1&a=192.168.1.23:48211,192.168.43.1:48211'
        '&f=$_fp&k=$_k&n=Kaf%20phone',
      );
      expect(o.addresses.length, 2);
      expect(o.deviceName, 'Kaf phone');
    });

    test('keeps only the first 3 addresses', () {
      final o = PairingOffer.parse(
        'kfm1://pair?v=1&a=10.0.0.1:1,10.0.0.2:2,10.0.0.3:3,10.0.0.4:4'
        '&f=$_fp&k=$_k&n=x',
      );
      expect(o.addresses.map((a) => a.port), [1, 2, 3]);
    });

    test('foreign scheme, random text and URLs are FormatException', () {
      for (final s in [
        'https://example.com/pair?v=1',
        'hello world',
        'WIFI:S:home;T:WPA;P:secret;;',
        'kfm1://other?v=1&a=1.2.3.4:5&f=$_fp&k=$_k',
        '',
      ]) {
        expect(() => PairingOffer.parse(s), throwsFormatException, reason: s);
      }
    });

    test('v != 1 is UnsupportedVersionException', () {
      expect(
        () => PairingOffer.parse('kfm1://pair?v=2&a=1.2.3.4:5&f=$_fp&k=$_k'),
        throwsA(isA<UnsupportedVersionException>()),
      );
    });

    test('missing or malformed fields are FormatException', () {
      final cases = [
        'kfm1://pair?a=1.2.3.4:5&f=$_fp&k=$_k', // no v
        'kfm1://pair?v=1&a=1.2.3.4:5&k=$_k', // no f
        'kfm1://pair?v=1&a=1.2.3.4:5&f=${'a1' * 31}&k=$_k', // short f
        'kfm1://pair?v=1&a=1.2.3.4:5&f=${'A1' * 32}&k=$_k', // upper hex
        'kfm1://pair?v=1&a=1.2.3.4:5&f=${'zz' * 32}&k=$_k', // bad hex
        'kfm1://pair?v=1&a=1.2.3.4:5&f=$_fp', // no k
        'kfm1://pair?v=1&a=1.2.3.4:5&f=$_fp&k=${_k.substring(4)}', // short k
        'kfm1://pair?v=1&a=1.2.3.4:5&f=$_fp&k=$_k$_k', // long k
        'kfm1://pair?v=1&a=1.2.3.4:5&f=$_fp&k=!!', // bad base64
        'kfm1://pair?v=1&f=$_fp&k=$_k', // no a
        'kfm1://pair?v=1&a=&f=$_fp&k=$_k', // empty a
        'kfm1://pair?v=1&a=1.2.3.4&f=$_fp&k=$_k', // no port
        'kfm1://pair?v=1&a=1.2.3.4:0&f=$_fp&k=$_k', // port 0
        'kfm1://pair?v=1&a=1.2.3.4:70000&f=$_fp&k=$_k', // port too big
        'kfm1://pair?v=1&a=a/b:5&f=$_fp&k=$_k', // bad host
      ];
      for (final s in cases) {
        expect(() => PairingOffer.parse(s), throwsFormatException, reason: s);
      }
    });

    test('an oversized name is cut, an oversized payload rejected', () {
      final o = PairingOffer.parse(
        'kfm1://pair?v=1&a=1.2.3.4:5&f=$_fp&k=$_k&n=${'x' * 200}',
      );
      expect(o.deviceName.length, kMaxOfferNameLength);
      expect(
        () => PairingOffer.parse('kfm1://pair?v=1&n=${'x' * 2000}'),
        throwsFormatException,
      );
    });
  });

  group('ShortCode', () {
    test('normalises case, dashes, spaces, O→0 and I/L→1', () {
      expect(ShortCode.normalize('abcd-efgh')?.value, 'ABCDEFGH');
      expect(ShortCode.normalize(' ab cd ef gh ')?.value, 'ABCDEFGH');
      expect(ShortCode.normalize('oOiIlL12')?.value, '00111112');
      expect(ShortCode.normalize('7K3M-9QPZ')?.display, '7K3M-9QPZ');
    });

    test('invalid characters and wrong lengths give null', () {
      expect(ShortCode.normalize('ABCD-EFGU'), isNull); // U excluded
      expect(ShortCode.normalize('ABCD-EFG!'), isNull);
      expect(ShortCode.normalize('ABCDEFG'), isNull);
      expect(ShortCode.normalize('ABCDEFGHJ'), isNull);
      expect(ShortCode.normalize(''), isNull);
    });

    test('display groups as XXXX-XXXX and toString hides the code', () {
      const c = ShortCode('ABCDEFGH');
      expect(c.display, 'ABCD-EFGH');
      expect(c.toString(), isNot(contains('ABCD')));
    });
  });
}
