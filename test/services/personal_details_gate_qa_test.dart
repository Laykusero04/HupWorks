import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:freelancer/services/personal_details_gate.dart';
import 'package:freelancer/services/user_private_details_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../support/qa_supabase.dart';

/// T-0172 QA: first-sign-in gate, per-user skip on a shared device, and the
/// pending signup date of birth (email confirmation path, other email, failed
/// write). The router listener is simulated: sign-in calls [refresh], sign-out
/// calls [PersonalDetailsGate.reset]. Fake users and emails only.
const _userA = qaSignedInUserId; // qa-user@example.invalid
const _emailA = 'qa-user@example.invalid';
const _userB = '00000000-0000-4000-8000-0000000000b1';
const _emailB = 'qa-other@example.invalid';

String _sessionFor(String id, String email) {
  final m = jsonDecode(qaSessionJson()) as Map<String, dynamic>;
  final user = m['user'] as Map<String, dynamic>;
  user['id'] = id;
  user['email'] = email;
  return jsonEncode(m);
}

SupabaseClient get _client => Supabase.instance.client;

Future<void> _signIn(String id, String email) async {
  await _client.auth.signOut(scope: SignOutScope.local);
  PersonalDetailsGate.reset();
  await _client.auth.recoverSession(_sessionFor(id, email));
  await PersonalDetailsGate.refresh();
}

Future<void> _signOut() async {
  await _client.auth.signOut(scope: SignOutScope.local);
  PersonalDetailsGate.reset();
}

void main() {
  // Mutable fake backend state for user_private_details.
  Map<String, Object?>? row;
  var readFails = false;
  var writeFails = false;
  late List<Map<String, dynamic>> writes;

  setUpAll(() async {
    await initQaSupabase(
      tables: {
        UserPrivateDetailsService.table: (request) {
          if (request.method == 'POST') {
            if (writeFails) throw Exception('offline');
            writes.add(jsonDecode(request.body) as Map<String, dynamic>);
            return null;
          }
          if (readFails) throw Exception('offline');
          if (row == null) return null;
          final uid = _client.auth.currentUser?.id;
          return {...row!, 'user_id': uid};
        },
      },
    );
  });

  setUp(() async {
    row = null;
    readFails = false;
    writeFails = false;
    writes = [];
    PendingSignupDob.clear();
    // Skip flags are stored per user; clear them so tests stay independent.
    await (await SharedPreferences.getInstance()).clear();
    await _signOut();
  });

  tearDown(() async {
    PendingSignupDob.clear();
    await _signOut();
  });

  const current = 'privacy-2026-11';

  group('prompt decision', () {
    test('no row, not skipped: prompted', () async {
      await _signIn(_userA, _emailA);
      expect(PersonalDetailsGate.needsPrompt, isTrue);
    });

    test('DOB but no consent: still prompted', () async {
      row = {'date_of_birth': '1990-05-07'};
      await _signIn(_userA, _emailA);
      expect(PersonalDetailsGate.needsPrompt, isTrue);
    });

    test('consent to an older text: prompted again', () async {
      row = {
        'date_of_birth': '1990-05-07',
        'consent_version': 'privacy-2025-01',
        'consented_at': '2025-01-01T00:00:00Z',
      };
      await _signIn(_userA, _emailA);
      expect(PersonalDetailsGate.needsPrompt, isTrue);
    });

    test('consent flag without consented_at does not count as consent', () async {
      row = {'date_of_birth': '1990-05-07', 'consent_version': current};
      await _signIn(_userA, _emailA);
      expect(PersonalDetailsGate.needsPrompt, isTrue);
    });

    test('current consent: not prompted', () async {
      row = {
        'date_of_birth': '1990-05-07',
        'consent_version': current,
        'consented_at': '2026-11-20T10:00:00Z',
      };
      await _signIn(_userA, _emailA);
      expect(PersonalDetailsGate.needsPrompt, isFalse);
    });

    test('a failed read never prompts (trust item still offers the step)',
        () async {
      readFails = true;
      await _signIn(_userA, _emailA);
      expect(PersonalDetailsGate.needsPrompt, isFalse);
    });

    test('signed out: never prompted and state is reset', () async {
      await _signIn(_userA, _emailA);
      expect(PersonalDetailsGate.needsPrompt, isTrue);
      await _signOut();
      expect(PersonalDetailsGate.needsPrompt, isFalse);
      await PersonalDetailsGate.refresh();
      expect(PersonalDetailsGate.needsPrompt, isFalse);
    });

    test('markSaved clears the prompt for this session', () async {
      await _signIn(_userA, _emailA);
      PersonalDetailsGate.markSaved();
      expect(PersonalDetailsGate.needsPrompt, isFalse);
    });
  });

  group('skip is per user on a shared device', () {
    test('A skips; B signs in on the same device and is still prompted',
        () async {
      await _signIn(_userA, _emailA);
      expect(PersonalDetailsGate.needsPrompt, isTrue);
      await PersonalDetailsGate.markSkipped();
      expect(PersonalDetailsGate.needsPrompt, isFalse);

      await _signOut();
      await _signIn(_userB, _emailB);
      expect(PersonalDetailsGate.needsPrompt, isTrue,
          reason: "A's skip must not hide the step for B");
    });

    test('A signs in again after B: A stays skipped (remembered per user)',
        () async {
      await _signIn(_userA, _emailA);
      await PersonalDetailsGate.markSkipped();
      await _signIn(_userB, _emailB);
      expect(PersonalDetailsGate.needsPrompt, isTrue);
      await _signIn(_userA, _emailA);
      expect(PersonalDetailsGate.needsPrompt, isFalse);
    });

    test('skip survives a fresh start (flag persisted, not in-memory only)',
        () async {
      await _signIn(_userA, _emailA);
      await PersonalDetailsGate.markSkipped();
      // Simulate a restart: the in-memory gate state is lost, prefs remain.
      PersonalDetailsGate.reset();
      await PersonalDetailsGate.refresh();
      expect(PersonalDetailsGate.needsPrompt, isFalse);
    });
  });

  group('pending signup date of birth (email confirmation path)', () {
    test('held while signed out, nothing written, kept for first sign-in',
        () async {
      PendingSignupDob.hold(' QA-User@Example.invalid ', DateTime(1990, 5, 7));
      expect(await PendingSignupDob.flushFor(null), isFalse);
      expect(writes, isEmpty);
      expect(PendingSignupDob.hasPending, isTrue);

      await PersonalDetailsGate.refresh(); // signed out
      expect(writes, isEmpty);
      expect(PendingSignupDob.hasPending, isTrue);
    });

    test('first sign-in with the same email writes the DOB, then clears it',
        () async {
      PendingSignupDob.hold('QA-User@Example.invalid', DateTime(1990, 5, 7));
      await _signIn(_userA, _emailA);
      expect(writes, hasLength(1));
      expect(writes.single['user_id'], _userA);
      expect(writes.single['date_of_birth'], '1990-05-07');
      expect(writes.single.containsKey('consent_version'), isFalse,
          reason: 'signup writes only the DOB, never consent');
      expect(PendingSignupDob.hasPending, isFalse);
      // Still prompted: consent has not been given.
      expect(PersonalDetailsGate.needsPrompt, isTrue);
    });

    test('a different email signing in never receives the pending DOB',
        () async {
      PendingSignupDob.hold(_emailA, DateTime(1990, 5, 7));
      await _signIn(_userB, _emailB);
      expect(writes, isEmpty);
      expect(PendingSignupDob.hasPending, isTrue);

      await _signOut();
      await _signIn(_userA, _emailA);
      expect(writes, hasLength(1));
      expect(writes.single['user_id'], _userA);
    });

    test('failed write keeps the pending DOB and never blocks sign-in',
        () async {
      PendingSignupDob.hold(_emailA, DateTime(1990, 5, 7));
      writeFails = true;
      await _signIn(_userA, _emailA);
      expect(PendingSignupDob.hasPending, isTrue);
      expect(PersonalDetailsGate.needsPrompt, isTrue);

      writeFails = false;
      await PersonalDetailsGate.refresh();
      expect(writes, hasLength(1));
      expect(PendingSignupDob.hasPending, isFalse);
    });

    test('an under-16 pending date is refused by the service and never written',
        () async {
      // The signup form blocks this, so it can only come from a bug. The
      // service must still refuse it (DB backstop).
      PendingSignupDob.hold(_emailA, DateTime(DateTime.now().year - 5, 1, 1));
      await _signIn(_userA, _emailA);
      expect(writes, isEmpty);
      expect(PendingSignupDob.hasPending, isTrue);
      expect(PersonalDetailsGate.needsPrompt, isTrue);
    });
  });
}
