import 'package:freelancer/l10n/l10n.dart';
import 'package:freelancer/services/user_private_details_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Friendly message for a failed private-details save. Never includes the
/// value or the raw exception text.
String privateDetailsErrorMessage(AppLocalizations l10n, Object error) {
  if (error is PrivateDetailsValidationException) {
    return switch (error.field) {
      PrivateDetailsField.dateOfBirth => l10n.pdDobErrorUnder16,
      PrivateDetailsField.legalName => l10n.pdErrLegalName,
      PrivateDetailsField.streetAddress => l10n.pdErrStreet,
      PrivateDetailsField.postalCode => l10n.pdErrPostal,
      PrivateDetailsField.consentVersion => l10n.pdInvalidValue,
    };
  }
  // The DB check (23514) is the backstop for age / postal / length rules.
  if (error is PostgrestException && error.code == '23514') {
    final m = (error.message).toLowerCase();
    if (m.contains('date_of_birth')) return l10n.pdDobErrorUnder16;
    if (m.contains('postal')) return l10n.pdErrPostal;
    return l10n.pdInvalidValue;
  }
  return l10n.pdSaveError;
}
