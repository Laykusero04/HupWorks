import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/utils/auth_error_message.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  AuthErrorKind k(Object e) => classifyAuthError(e);

  test('database error saving new user (500) -> server', () {
    expect(
      k(AuthApiException('Database error saving new user',
          statusCode: '500', code: 'unexpected_failure')),
      AuthErrorKind.server,
    );
    expect(
      k(AuthApiException('Database error saving new user', statusCode: '500')),
      AuthErrorKind.server,
    );
  });

  test('rate limit', () {
    expect(
      k(AuthApiException('email rate limit exceeded',
          statusCode: '429', code: 'over_email_send_rate_limit')),
      AuthErrorKind.rateLimit,
    );
    expect(k(AuthApiException('slow down', statusCode: '429')),
        AuthErrorKind.rateLimit);
  });

  test('error sending confirmation email', () {
    expect(
      k(AuthApiException('Error sending confirmation email',
          statusCode: '500', code: 'unexpected_failure')),
      AuthErrorKind.emailSend,
    );
  });

  test('already registered', () {
    expect(
      k(AuthApiException('User already registered',
          statusCode: '422', code: 'user_already_exists')),
      AuthErrorKind.alreadyRegistered,
    );
    expect(
      k(AuthApiException('exists', code: 'email_exists')),
      AuthErrorKind.alreadyRegistered,
    );
  });

  test('weak password and invalid email', () {
    expect(
      k(AuthApiException('Password is known to be weak',
          statusCode: '422', code: 'weak_password')),
      AuthErrorKind.weakPassword,
    );
    expect(
      k(AuthApiException('Email address "x" is invalid',
          statusCode: '400', code: 'email_address_invalid')),
      AuthErrorKind.invalidEmail,
    );
  });

  test('login errors', () {
    expect(
      k(AuthApiException('Invalid login credentials',
          statusCode: '400', code: 'invalid_credentials')),
      AuthErrorKind.invalidCredentials,
    );
    expect(
      k(AuthApiException('Email not confirmed',
          statusCode: '400', code: 'email_not_confirmed')),
      AuthErrorKind.emailNotConfirmed,
    );
  });

  test('network errors', () {
    expect(
        k(const SocketException('Failed host lookup')), AuthErrorKind.network);
    expect(k(TimeoutException('t')), AuthErrorKind.network);
    expect(k(Exception('ClientException: Connection refused')),
        AuthErrorKind.network);
  });

  test('fallback never exposes raw text kind', () {
    expect(k(Exception('boom')), AuthErrorKind.generic);
    expect(
        k(AuthApiException('weird', statusCode: '418')), AuthErrorKind.generic);
  });

  test('round 2 codes', () {
    expect(k(AuthApiException('x', code: 'same_password')),
        AuthErrorKind.samePassword);
    expect(k(AuthApiException('x', code: 'otp_expired')),
        AuthErrorKind.linkExpired);
    expect(k(AuthApiException('x', code: 'signup_disabled')),
        AuthErrorKind.signupDisabled);
    expect(k(AuthApiException('x', code: 'user_banned')),
        AuthErrorKind.userBanned);
    expect(
      k(AuthRetryableFetchException(
          message: 'ClientException with SocketException: Failed host lookup')),
      AuthErrorKind.network,
    );
  });

  test('redactEmails masks addresses', () {
    expect(redactEmails('Email address "a.b@ex.com" is invalid'),
        'Email address "<email>" is invalid');
  });
}
