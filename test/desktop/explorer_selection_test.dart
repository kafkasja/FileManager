import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/desktop/widgets/explorer_selection.dart';

void main() {
  const order = ['a', 'b', 'c', 'd', 'e'];
  const empty = ExplorerSelection.empty;

  test('click selects only that item', () {
    final s = empty.click('b', order).click('d', order);
    expect(s.ids, {'d'});
    expect(s.anchor, 'd');
    expect(s.focus, 'd');
  });

  test('Ctrl+click toggles, Shift+click selects a range from the anchor', () {
    var s = empty.click('b', order).click('d', order, ctrl: true);
    expect(s.ids, {'b', 'd'});
    s = s.click('b', order, ctrl: true);
    expect(s.ids, {'d'});
    s = empty.click('b', order).click('e', order, shift: true);
    expect(s.ids, {'b', 'c', 'd', 'e'});
    // The anchor stays: a second Shift+click re-ranges from it.
    s = s.click('a', order, shift: true);
    expect(s.ids, {'a', 'b'});
  });

  test('Ctrl+Shift+click adds a range to the selection', () {
    final s = empty
        .click('a', order)
        .click('c', order, ctrl: true)
        .click('e', order, ctrl: true, shift: true);
    expect(s.ids, {'a', 'c', 'd', 'e'});
  });

  test('keyboard moves: plain, Shift range, Ctrl focus only', () {
    var s = empty.moveTo(1, order);
    expect(s.ids, {'b'});
    s = s.moveTo(3, order, shift: true);
    expect(s.ids, {'b', 'c', 'd'});
    s = s.moveTo(4, order, ctrl: true);
    expect(s.ids, {'b', 'c', 'd'});
    expect(s.focus, 'e');
    expect(s.toggleFocus().ids, {'b', 'c', 'd', 'e'});
  });

  test('select all and rubber band (Ctrl adds to the base)', () {
    expect(empty.selectAll(order).ids, order.toSet());
    final s = empty.click('a', order);
    expect(s.band({'c', 'd'}).ids, {'c', 'd'});
    expect(s.band({'c', 'd'}, base: s.ids).ids, {'a', 'c', 'd'});
  });

  test('right-click keeps a selection it belongs to', () {
    final s = empty.click('a', order).click('c', order, shift: true);
    expect(s.secondaryClick('b').ids, {'a', 'b', 'c'});
    expect(s.secondaryClick('e').ids, {'e'});
  });

  test('retain: acted files leave, the focus moves to the next file', () {
    final s = empty.click('b', order).click('c', order, shift: true);
    final after = s.retain(['a', 'd', 'e'], before: order);
    expect(after.ids, {'d'});
    expect(after.focus, 'd');
    // The last file sorted: the focus falls back to the one before it.
    final last = empty.click('e', order).retain(['a', 'b'], before: order);
    expect(last.focus, 'b');
    expect(last.ids, {'b'});
    // Nothing left.
    expect(empty.click('a', order).retain([], before: order).isEmpty, isTrue);
  });
}
