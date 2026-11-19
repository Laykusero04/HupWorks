enum PasswordStrength { empty, weak, medium, strong }

/// Hint only. The hard rule stays "at least 6 characters" (Supabase minimum).
/// Strong = 8+ chars with a letter, a number and a symbol, or 12+ chars with
/// three character classes. Medium = 6+ chars with two classes. Else weak.
PasswordStrength passwordStrength(String p) {
  if (p.isEmpty) return PasswordStrength.empty;
  final lower = RegExp(r'[a-z]').hasMatch(p);
  final upper = RegExp(r'[A-Z]').hasMatch(p);
  final digit = RegExp(r'[0-9]').hasMatch(p);
  final symbol = RegExp(r'[^A-Za-z0-9]').hasMatch(p);
  final letter = lower || upper;
  final classes = [lower, upper, digit, symbol].where((c) => c).length;
  if (p.length >= 8 && letter && digit && symbol) {
    return PasswordStrength.strong;
  }
  if (p.length >= 12 && classes >= 3) return PasswordStrength.strong;
  if (p.length >= 6 && classes >= 2) return PasswordStrength.medium;
  return PasswordStrength.weak;
}
