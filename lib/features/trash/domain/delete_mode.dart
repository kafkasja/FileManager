/// What a trash swipe finally does (D1). Fixed per session.
enum DeleteMode {
  trash,
  permanent;

  /// Missing or unknown → the safe default.
  static DeleteMode parse(String? raw) =>
      raw == 'permanent' ? DeleteMode.permanent : DeleteMode.trash;
}
