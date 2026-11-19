import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/utils/auth_error_message.dart';
import 'package:freelancer/l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Edge cases for [classifyAuthError] and [authErrorMessage] (T-0161 QA).
void main() {
  AuthErrorKind k(Object e) => classifyAuthError(e);

  group('null / empty code and message', () {
    test('no code, 500 + "error sending ... email" -> emailSend', () {
      expect(
        k(AuthApiException('Error sending confirmation email',
            statusCode: '500')),
        AuthErrorKind.emailSend,
      );
    });

    test('no code, no status, "Database error" -> server', () {
      expect(
        k(AuthApiException('Database error saving new user')),
        AuthErrorKind.server,
      );
    });

    test('empty code string behaves like null code', () {
      expect(
        k(AuthApiException('Database error saving new user',
            statusCode: '500', code: '')),
        AuthErrorKind.server,
      );
    });

    test('empty message and no code/status -> generic', () {
      expect(k(AuthApiException('')), AuthErrorKind.generic);
    });

    test('empty string error object -> generic', () {
      expect(k(''), AuthErrorKind.generic);
    });

    test('code is matched case-insensitively', () {
      expect(
        k(AuthApiException('rate limit', code: 'OVER_EMAIL_SEND_RATE_LIMIT')),
        AuthErrorKind.rateLimit,
      );
    });
  });

  group('unknown codes and statuses', () {
    test('unknown code with a known message still classifies by message', () {
      expect(
        k(AuthApiException('User already registered',
            statusCode: '422', code: 'some_future_code')),
        AuthErrorKind.alreadyRegistered,
      );
    });

    test('unknown status string "abc" with generic message -> generic', () {
      expect(
        k(AuthApiException('Something odd', statusCode: 'abc')),
        AuthErrorKind.generic,
      );
    });

    test('empty status string with generic message -> generic', () {
      expect(
        k(AuthApiException('Something odd', statusCode: '')),
        AuthErrorKind.generic,
      );
    });

    test('unknown message with 503 status -> server (5xx fallback)', () {
      expect(
        k(AuthApiException('Upstream unavailable', statusCode: '503')),
        AuthErrorKind.server,
      );
    });

    test('unknown message with 4xx status -> generic, not server', () {
      expect(
        k(AuthApiException('Teapot', statusCode: '418')),
        AuthErrorKind.generic,
      );
    });
  });

  group('statusCode as string', () {
    test('"429" with no code and no rate-limit text -> rateLimit', () {
      expect(
        k(AuthApiException('Too fast', statusCode: '429')),
        AuthErrorKind.rateLimit,
      );
    });

    test('"500" with no code and no text -> server', () {
      expect(
        k(AuthApiException('Internal', statusCode: '500')),
        AuthErrorKind.server,
      );
    });

    test('status is not used to override a specific code', () {
      expect(
        k(AuthApiException('Invalid login credentials',
            statusCode: '500', code: 'invalid_credentials')),
        AuthErrorKind.invalidCredentials,
      );
    });
  });

  group('validation_failed / email_address_invalid fallthrough', () {
    test('validation_failed mentioning email -> invalidEmail', () {
      expect(
        k(AuthApiException('Unable to validate email address: invalid format',
            statusCode: '400', code: 'validation_failed')),
        AuthErrorKind.invalidEmail,
      );
    });

    test('validation_failed about password -> weakPassword (not invalidEmail)',
        () {
      expect(
        k(AuthApiException('Password should be at least 6 characters',
            statusCode: '422', code: 'validation_failed')),
        AuthErrorKind.weakPassword,
      );
    });

    test('email_address_invalid maps by code alone -> invalidEmail', () {
      expect(
        k(AuthApiException('Address is not allowed',
            statusCode: '400', code: 'email_address_invalid')),
        AuthErrorKind.invalidEmail,
      );
    });

    test('weak_password typed exception -> weakPassword', () {
      expect(
        k(AuthWeakPasswordException(
          message: 'Password is too weak',
          statusCode: '422',
          reasons: const ['length'],
        )),
        AuthErrorKind.weakPassword,
      );
    });
  });

  group('network and transport errors', () {
    test('real http.ClientException -> network', () {
      expect(
        k(http.ClientException('Connection refused',
            Uri.parse('https://example.invalid/auth/v1/signup'))),
        AuthErrorKind.network,
      );
    });

    test('SocketException with no message -> network', () {
      expect(k(const SocketException('')), AuthErrorKind.network);
    });

    test('exception wrapping a SocketException text -> network', () {
      expect(
        k(Exception('Caught SocketException: Network is unreachable')),
        AuthErrorKind.network,
      );
    });

    test('TimeoutException with message -> network', () {
      expect(
        k(TimeoutException('Future not completed', const Duration(seconds: 5))),
        AuthErrorKind.network,
      );
    });

    test('AuthRetryableFetchException with fetch-failure text -> network', () {
      expect(
        k(AuthRetryableFetchException(
          message: 'ClientException: Failed host lookup',
        )),
        AuthErrorKind.network,
      );
    });

    test('AuthRetryableFetchException with "Connection refused" -> network', () {
      expect(
        k(AuthRetryableFetchException(message: 'Connection refused')),
        AuthErrorKind.network,
      );
    });

    // gotrue wraps any HTTP 5xx body as AuthRetryableFetchException(message: raw
    // body, statusCode: '500'), so these shapes are what production produces.
    test('AuthRetryableFetchException 500 raw body "Database error" -> server',
        () {
      expect(
        k(AuthRetryableFetchException(
          message:
              '{"code":500,"error_code":"unexpected_failure","msg":"Database error saving new user"}',
          statusCode: '500',
        )),
        AuthErrorKind.server,
      );
    });

    test('AuthRetryableFetchException 500 raw body "Error sending" -> emailSend',
        () {
      expect(
        k(AuthRetryableFetchException(
          message:
              '{"code":500,"error_code":"unexpected_failure","msg":"Error sending confirmation email"}',
          statusCode: '500',
        )),
        AuthErrorKind.emailSend,
      );
    });
  });

  group('authErrorMessage (localized, never raw)', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final nl = lookupAppLocalizations(const Locale('nl'));

    final samples = <Object>[
      AuthApiException('Database error saving new user',
          statusCode: '500', code: 'unexpected_failure'),
      AuthApiException('Error sending confirmation email',
          statusCode: '500', code: 'unexpected_failure'),
      AuthApiException('email rate limit exceeded',
          statusCode: '429', code: 'over_email_send_rate_limit'),
      AuthApiException('User already registered',
          statusCode: '422', code: 'user_already_exists'),
      AuthWeakPasswordException(
          message: 'Password is too weak',
          statusCode: '422',
          reasons: const ['length']),
      AuthApiException('Email address "x" is invalid',
          statusCode: '400', code: 'email_address_invalid'),
      const SocketException('Failed host lookup'),
      AuthRetryableFetchException(message: 'ClientException: x'),
      AuthApiException('Invalid login credentials',
          statusCode: '400', code: 'invalid_credentials'),
      AuthApiException('Email not confirmed',
          statusCode: '400', code: 'email_not_confirmed'),
      Exception('boom'),
    ];

    test('EN and NL never contain raw exception text', () {
      for (final e in samples) {
        for (final l10n in [en, nl]) {
          final out = authErrorMessage(l10n, e);
          expect(out.trim(), isNotEmpty);
          expect(out, isNot(contains('Exception')), reason: out);
          expect(out, isNot(contains('statusCode')), reason: out);
          expect(out, isNot(contains('AuthApiException')), reason: out);
          expect(out, isNot(contains('unexpected_failure')), reason: out);
          expect(out, isNot(contains('Database error')), reason: out);
        }
      }
    });

    test('database error maps to the server message in EN and NL', () {
      final e = samples.first;
      expect(authErrorMessage(en, e), en.authErrorServer);
      expect(authErrorMessage(nl, e), nl.authErrorServer);
      expect(en.authErrorServer, isNot(equals(nl.authErrorServer)));
    });

    test('all 10 message keys are non-empty and distinct in EN and NL', () {
      final enMsgs = [
        en.authErrorServer,
        en.authErrorRateLimit,
        en.authErrorEmailSend,
        en.authErrorAlreadyRegistered,
        en.authErrorWeakPassword,
        en.authErrorInvalidEmail,
        en.authErrorNetwork,
        en.authErrorInvalidCredentials,
        en.authErrorEmailNotConfirmed,
        en.authErrorGeneric,
      ];
      final nlMsgs = [
        nl.authErrorServer,
        nl.authErrorRateLimit,
        nl.authErrorEmailSend,
        nl.authErrorAlreadyRegistered,
        nl.authErrorWeakPassword,
        nl.authErrorInvalidEmail,
        nl.authErrorNetwork,
        nl.authErrorInvalidCredentials,
        nl.authErrorEmailNotConfirmed,
        nl.authErrorGeneric,
      ];
      for (final list in [enMsgs, nlMsgs]) {
        expect(list.every((s) => s.trim().isNotEmpty), isTrue);
        expect(list.toSet(), hasLength(10));
      }
    });
  });
}
