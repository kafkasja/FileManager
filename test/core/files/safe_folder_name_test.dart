import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/core/files/file_names.dart';

void main() {
  test('safeFolderName keeps a peer name inside one folder segment', () {
    expect(safeFolderName('Galaxy S22 Ultra'), 'Galaxy S22 Ultra');
    expect(safeFolderName('../evil'), '_evil');
    expect(safeFolderName('..'), 'Device');
    expect(safeFolderName(r'a/b\c:d*e?f"g<h>i|j'), 'a_b_c_d_e_f_g_h_i_j');
    expect(safeFolderName('  .hidden. '), 'hidden');
    expect(safeFolderName('tab\there'), 'tab_here');
    expect(safeFolderName(''), 'Device');
    expect(safeFolderName('x' * 300), 'x' * 64);
  });
}
