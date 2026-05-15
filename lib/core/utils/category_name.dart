/// Normalizes user-typed category names for consistent storage (e.g. "janitor" → "Janitor").
abstract final class CategoryName {
  static const int minLength = 2;
  static const int maxLength = 48;

  /// Title-cases each word and collapses extra spaces.
  static String normalize(String raw) {
    final trimmed = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.length < minLength) {
      throw FormatException('Category must be at least $minLength characters');
    }
    if (trimmed.length > maxLength) {
      throw FormatException('Category must be $maxLength characters or less');
    }

    return trimmed.split(' ').map((word) {
      if (word.isEmpty) return word;
      final lower = word.toLowerCase();
      return lower[0].toUpperCase() + (lower.length > 1 ? lower.substring(1) : '');
    }).join(' ');
  }
}
