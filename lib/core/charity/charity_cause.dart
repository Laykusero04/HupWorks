/// Cause a profile can link to their platform share.
/// Null means they have not chosen one.
abstract final class CharityCause {
  static const food = 'food';
  static const education = 'education';
  static const health = 'health';
  static const shelter = 'shelter';

  static const values = <String>[food, education, health, shelter];

  static String? normalize(String? raw) {
    final value = raw?.trim().toLowerCase();
    if (value == null || value.isEmpty) return null;
    if (values.contains(value)) return value;
    return null;
  }
}
