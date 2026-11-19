import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Categories of auth failures shown to the user.
enum AuthErrorKind {
  server,
  rateLimit,
  emailSend,
  alreadyRegistered,
  weakPassword,
  invalidEmail,
  network,
  invalidCredentials,
  emailNotConfirmed,
  samePassword,
  linkExpired,
  signupDisabled,
  userBanned,
  generic,
}

/// Classifies an error thrown by Supabase Auth (or the network layer).
AuthErrorKind classifyAuthError(Object error) {
  if (error is SocketException || error is TimeoutException) {
    return AuthErrorKind.network;
  }
  final text = error.toString().toLowerCase();
  if (error is AuthException) {
    final code = (error.code ?? '').toLowerCase();
    final msg = error.message.toLowerCase();
    final status = int.tryParse(error.statusCode ?? '');

    switch (code) {
      case 'over_email_send_rate_limit':
      case 'over_request_rate_limit':
      case 'over_sms_send_rate_limit':
        return AuthErrorKind.rateLimit;
      case 'user_already_exists':
      case 'email_exists':
        return AuthErrorKind.alreadyRegistered;
      case 'weak_password':
        return AuthErrorKind.weakPassword;
      case 'email_address_invalid':
        return AuthErrorKind.invalidEmail;
      case 'validation_failed':
        if (msg.contains('email')) return AuthErrorKind.invalidEmail;
      case 'same_password':
        return AuthErrorKind.samePassword;
      case 'otp_expired':
      case 'flow_state_expired':
      case 'session_expired':
        return AuthErrorKind.linkExpired;
      case 'signup_disabled':
      case 'email_provider_disabled':
        return AuthErrorKind.signupDisabled;
      case 'user_banned':
        return AuthErrorKind.userBanned;
      case 'invalid_credentials':
        return AuthErrorKind.invalidCredentials;
      case 'email_not_confirmed':
        return AuthErrorKind.emailNotConfirmed;
      case 'unexpected_failure':
        if (msg.contains('confirmation email') || msg.contains('sending')) {
          return AuthErrorKind.emailSend;
        }
        return AuthErrorKind.server;
    }

    // gotrue wraps transport failures as AuthRetryableFetchException with the
    // raw exception text and no status code.
    if ((status == null || error is AuthRetryableFetchException) &&
        _looksLikeNetwork(msg)) {
      return AuthErrorKind.network;
    }
    if (msg.contains('same password') ||
        msg.contains('different from the old password')) {
      return AuthErrorKind.samePassword;
    }
    if (msg.contains('token has expired') || msg.contains('link is invalid')) {
      return AuthErrorKind.linkExpired;
    }
    if (msg.contains('error sending') && msg.contains('email')) {
      return AuthErrorKind.emailSend;
    }
    if (msg.contains('database error')) return AuthErrorKind.server;
    if (msg.contains('rate limit') || status == 429) {
      return AuthErrorKind.rateLimit;
    }
    if (msg.contains('already registered') || msg.contains('already exists')) {
      return AuthErrorKind.alreadyRegistered;
    }
    if (msg.contains('weak') ||
        (msg.contains('password') && msg.contains('at least'))) {
      return AuthErrorKind.weakPassword;
    }
    if (msg.contains('invalid login credentials')) {
      return AuthErrorKind.invalidCredentials;
    }
    if (msg.contains('email not confirmed')) {
      return AuthErrorKind.emailNotConfirmed;
    }
    if (msg.contains('invalid') && msg.contains('email')) {
      return AuthErrorKind.invalidEmail;
    }
    if (status != null && status >= 500) return AuthErrorKind.server;
    return AuthErrorKind.generic;
  }

  if (_looksLikeNetwork(text)) return AuthErrorKind.network;
  return AuthErrorKind.generic;
}

bool _looksLikeNetwork(String lower) =>
    lower.contains('socketexception') ||
    lower.contains('failed host lookup') ||
    lower.contains('clientexception') ||
    lower.contains('network is unreachable') ||
    lower.contains('connection refused') ||
    lower.contains('connection closed') ||
    lower.contains('connection reset') ||
    lower.contains('timed out');

final _emailLike = RegExp(r'[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+');

/// Masks email addresses before text goes to the debug log.
String redactEmails(String input) => input.replaceAll(_emailLike, '<email>');

/// Localized, user-friendly message for an auth error. The technical details
/// stay in the debug log only (never shown to the user).
String authErrorMessage(AppLocalizations l10n, Object error) {
  if (kDebugMode) {
    if (error is AuthException) {
      debugPrint('[HupWorks:auth] AuthException status=${error.statusCode} '
          'code=${error.code} message=${redactEmails(error.message)}');
    } else {
      debugPrint('[HupWorks:auth] ${error.runtimeType}: '
          '${redactEmails(error.toString())}');
    }
  }
  switch (classifyAuthError(error)) {
    case AuthErrorKind.server:
      return l10n.authErrorServer;
    case AuthErrorKind.rateLimit:
      return l10n.authErrorRateLimit;
    case AuthErrorKind.emailSend:
      return l10n.authErrorEmailSend;
    case AuthErrorKind.alreadyRegistered:
      return l10n.authErrorAlreadyRegistered;
    case AuthErrorKind.weakPassword:
      return l10n.authErrorWeakPassword;
    case AuthErrorKind.invalidEmail:
      return l10n.authErrorInvalidEmail;
    case AuthErrorKind.network:
      return l10n.authErrorNetwork;
    case AuthErrorKind.invalidCredentials:
      return l10n.authErrorInvalidCredentials;
    case AuthErrorKind.emailNotConfirmed:
      return l10n.authErrorEmailNotConfirmed;
    case AuthErrorKind.samePassword:
      return l10n.authErrorSamePassword;
    case AuthErrorKind.linkExpired:
      return l10n.authErrorLinkExpired;
    case AuthErrorKind.signupDisabled:
      return l10n.authErrorSignupDisabled;
    case AuthErrorKind.userBanned:
      return l10n.authErrorUserBanned;
    case AuthErrorKind.generic:
      return l10n.authErrorGeneric;
  }
}
