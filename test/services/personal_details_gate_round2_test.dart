import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/services/personal_details_gate.dart';
import 'package:freelancer/services/user_private_details_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../support/qa_supabase.dart';

/// T-0172 fix round 2: version-aware skip, pending DOB never overwrites a
/// stored one, and a hanging load cannot hold the router. Fake data only.
void main() {
  Map<String, Object?>? row;
  late List<Map<String, dynamic>> writes;
  SupabaseClient client() => Supabase.instance.client;

  setUpAll(() async {
    await initQaSupabase(
      signedIn: true,
      tables: {
        UserPrivateDetailsService.table: (request) {
          if (request.method == 'POST') {
            writes.add(jsonDecode(request.body) as Map<String, dynamic>);
            return null;
          }
          if (row == null) return null;
          return {...row!, 'user_id': qaSignedInUserId};
        },
      },
    );
  });

  setUp(() async {
    row = null;
    writes = [];
    PendingSignupDob.clear();
    PersonalDetailsGate.reset();
    PersonalDetailsGate.loadOverride = null;
    PersonalDetailsGate.refreshTimeout = const Duration(seconds: 5);
    SharedPreferences.setMockInitialValues({});
  });

  const key = 'private_details_skip_version_$qaSignedInUserId';
  const current = 'privacy-2026-11';

  test('skip is remembered for the current consent version only', () async {
    SharedPreferences.setMockInitialValues({key: current});
    await PersonalDetailsGate.refresh();
    expect(PersonalDetailsGate.needsPrompt, isFalse);

    // Version bump: the skip was for an older version, prompt once more.
    SharedPreferences.setMockInitialValues({key: 'privacy-2025-01'});
    await PersonalDetailsGate.refresh();
    expect(PersonalDetailsGate.needsPrompt, isTrue);
  });

  test('markSkipped stores the current version, not a bare flag', () async {
    await PersonalDetailsGate.refresh();
    expect(PersonalDetailsGate.needsPrompt, isTrue);
    await PersonalDetailsGate.markSkipped();
    expect(PersonalDetailsGate.needsPrompt, isFalse);
    expect((await SharedPreferences.getInstance()).getString(key), current);
    await PersonalDetailsGate.refresh();
    expect(PersonalDetailsGate.needsPrompt, isFalse);
  });

  test('pending signup DOB does not overwrite an existing stored DOB',
      () async {
    row = {'date_of_birth': '1990-05-17'};
    PendingSignupDob.hold(
        client().auth.currentUser!.email!, DateTime(2005, 1, 1));
    final stored =
        await PendingSignupDob.flushFor(client().auth.currentUser!.email);
    expect(stored, isFalse);
    expect(writes, isEmpty);
    expect(PendingSignupDob.hasPending, isFalse); // dropped, not retried
  });

  test('pending signup DOB is written when none is stored', () async {
    PendingSignupDob.hold(
        client().auth.currentUser!.email!, DateTime(2005, 1, 1));
    expect(await PendingSignupDob.flushFor(client().auth.currentUser!.email),
        isTrue);
    expect(writes.single['date_of_birth'], '2005-01-01');
  });

  test('a different signed-in email keeps the pending DOB', () async {
    PendingSignupDob.hold('other@example.invalid', DateTime(2005, 1, 1));
    expect(await PendingSignupDob.flushFor(client().auth.currentUser!.email),
        isFalse);
    expect(PendingSignupDob.hasPending, isTrue);
    expect(writes, isEmpty);
  });

  test('a hanging load times out: no prompt, refresh still returns', () async {
    PersonalDetailsGate.refreshTimeout = const Duration(milliseconds: 50);
    PersonalDetailsGate.loadOverride = (_, __) => Completer<void>().future;
    await PersonalDetailsGate.refresh().timeout(const Duration(seconds: 2));
    expect(PersonalDetailsGate.needsPrompt, isFalse);
  });
}
