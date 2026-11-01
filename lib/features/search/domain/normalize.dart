/// Normalizes a search word or term-file key for keyword matching (TASK-B8):
/// trim, lower case, Turkish `İ`/`ı` → `i`, accents stripped (`é → e`,
/// `ö → o`, `ç → c`, `ş → s`, `ğ → g`, `ß → ss`), whitespace runs → one
/// space. Not used for name search (that must match `name_lower`).
String normalizeSearchWord(String s) {
  // `'İ'.toLowerCase()` is `i` + a combining dot, so map it first.
  final lower = s.trim().replaceAll('İ', 'i').toLowerCase();
  final out = StringBuffer();
  var lastSpace = false;
  for (final rune in lower.runes) {
    // Combining diacritical marks (U+0300–U+036F) are dropped.
    if (rune >= 0x300 && rune <= 0x36f) continue;
    final ch = String.fromCharCode(rune);
    if (ch.trim().isEmpty) {
      if (!lastSpace) out.write(' ');
      lastSpace = true;
      continue;
    }
    lastSpace = false;
    out.write(_fold[ch] ?? ch);
  }
  return out.toString();
}

/// Precomposed Latin letters → their base letters (lower case only: the
/// input is lowercased first).
final Map<String, String> _fold = () {
  const groups = {
    'a': 'àáâãäåāăą',
    'ae': 'æ',
    'c': 'çćĉċč',
    'd': 'ďđ',
    'e': 'èéêëēĕėęě',
    'g': 'ĝğġģ',
    'h': 'ĥħ',
    'i': 'ìíîïĩīĭįı',
    'j': 'ĵ',
    'k': 'ķ',
    'l': 'ĺļľŀł',
    'n': 'ñńņňŉ',
    'o': 'òóôõöøōŏő',
    'oe': 'œ',
    'r': 'ŕŗř',
    's': 'śŝşšș',
    'ss': 'ß',
    't': 'ţťŧț',
    'u': 'ùúûüũūŭůűų',
    'w': 'ŵ',
    'y': 'ýÿŷ',
    'z': 'źżž',
  };
  return {
    for (final MapEntry(key: base, value: chars) in groups.entries)
      for (final ch in chars.split('')) ch: base,
  };
}();
