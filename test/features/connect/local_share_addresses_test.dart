import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/connect/data/share_server.dart';

InterfaceInfo _i(String name, List<String> ips) =>
    (name: name, addresses: [for (final ip in ips) InternetAddress(ip)]);

Future<List<String>> _run(List<InterfaceInfo> list, String os) async => [
  for (final a in await localShareAddresses(
    list: () async => list,
    operatingSystem: os,
  ))
    '${a.interfaceName}=${a.address.address}/${a.prefixLength}',
];

void main() {
  test('Android keeps wlan/ap/swlan RFC 1918, Wi-Fi first', () async {
    expect(
      await _run([
        _i('ap0', ['192.168.43.1']),
        _i('rmnet0', ['10.20.30.40']),
        _i('ccmni1', ['10.1.1.1']),
        _i('tun0', ['10.8.0.2']),
        _i('ppp0', ['172.16.0.9']),
        _i('lo', ['127.0.0.1']),
        _i('wlan0', ['192.168.1.23']),
        _i('swlan0', ['172.20.10.1']),
      ], 'android'),
      ['wlan0=192.168.1.23/24', 'ap0=192.168.43.1/24', 'swlan0=172.20.10.1/24'],
    );
  });

  test('public and non-private addresses are never shared', () async {
    expect(
      await _run([
        _i('wlan0', ['8.8.8.8', '172.32.0.1', '100.64.0.1', '169.254.1.1']),
      ], 'android'),
      isEmpty,
    );
  });

  test('at most 3 addresses', () async {
    expect(
      await _run([
        _i('wlan0', ['192.168.1.2', '192.168.2.2']),
        _i('wlan1', ['192.168.3.2']),
        _i('ap0', ['192.168.43.1']),
      ], 'android'),
      hasLength(kMaxAdvertisedAddresses),
    );
  });

  test('Windows keeps non-virtual adapters, Wi-Fi first', () async {
    expect(
      await _run([
        _i('Ethernet', ['192.168.0.10']),
        _i('vEthernet (WSL)', ['172.28.16.1']),
        _i('VirtualBox Host-Only Network', ['192.168.56.1']),
        _i('Wi-Fi', ['192.168.1.50']),
      ], 'windows'),
      ['Wi-Fi=192.168.1.50/24', 'Ethernet=192.168.0.10/24'],
    );
  });
}
