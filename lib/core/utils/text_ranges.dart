/// B8: the parts of [name] that match any of [words] (case-insensitive,
/// like `name_lower`), as sorted `[start, end)` ranges with overlapping or
/// touching ones merged. Empty when nothing matches, or when lower-casing
/// changes the name's length (the ranges wouldn't line up).
List<(int, int)> highlightRanges(String name, Iterable<String> words) {
  final lower = name.toLowerCase();
  if (lower.length != name.length) return const [];
  final found = <(int, int)>[];
  for (final word in words) {
    final w = word.toLowerCase();
    if (w.isEmpty) continue;
    var at = lower.indexOf(w);
    while (at >= 0) {
      found.add((at, at + w.length));
      at = lower.indexOf(w, at + 1);
    }
  }
  if (found.isEmpty) return const [];
  found.sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2);
  final merged = <(int, int)>[found.first];
  for (final (start, end) in found.skip(1)) {
    final (lastStart, lastEnd) = merged.last;
    if (start <= lastEnd) {
      if (end > lastEnd) merged.last = (lastStart, end);
    } else {
      merged.add((start, end));
    }
  }
  return List.unmodifiable(merged);
}
