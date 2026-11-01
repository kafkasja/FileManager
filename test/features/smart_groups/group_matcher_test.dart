import 'package:flutter_test/flutter_test.dart';
import 'package:kfm/features/smart_groups/domain/group_matcher.dart';

Set<String> ids(String p, int n, [int from = 0]) => {
  for (var i = from; i < from + n; i++) '$p$i',
};

void main() {
  test('jaccard edge cases', () {
    expect(jaccard({}, {}), 1);
    expect(jaccard({'a'}, {}), 0);
    expect(jaccard({'a', 'b'}, {'b', 'c'}), closeTo(1 / 3, 1e-9));
    expect(jaccard({'a'}, {'a'}), 1);
  });

  test('identical members keep the id', () {
    expect(matchGroups({7: ids('a', 20)}, [ids('a', 20)]), {0: 7});
  });

  test('a 15-photo group that gains 10 photos keeps its id', () {
    expect(matchGroups({3: ids('a', 15)}, [ids('a', 25)]), {0: 3});
  });

  test('losing more than 20% of the old members = new group', () {
    expect(matchGroups({3: ids('a', 20)}, [ids('a', 15)]), isEmpty);
  });

  test('a group swallowed by a much larger cluster is not matched', () {
    expect(matchGroups({3: ids('a', 15)}, [ids('a', 100)]), isEmpty);
  });

  test('one-to-one, best overlap first', () {
    // Old 1 and 2 both fully inside the new cluster 0; 1 has the better
    // Jaccard and wins, 2 stays unmatched.
    final old = {1: ids('a', 18), 2: ids('a', 2, 18)};
    final matches = matchGroups(old, [ids('a', 20), ids('z', 5)]);
    expect(matches, {0: 1});
  });

  test('no shared members → no match', () {
    expect(matchGroups({1: ids('a', 10)}, [ids('b', 10)]), isEmpty);
    expect(matchGroups({}, [ids('b', 10)]), isEmpty);
    expect(matchGroups({1: ids('a', 10)}, []), isEmpty);
  });
}
