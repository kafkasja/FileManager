/// Compares two byte strings in time that depends only on their length
/// (TASK-N2 rule 6). Lengths are public (fixed by the protocol), so a length
/// mismatch returns early.
bool constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= (a[i] ^ b[i]) & 0xff;
  }
  return diff == 0;
}
