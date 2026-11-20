import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/utils/employer_verification_gate.dart';
import 'package:freelancer/l10n/app_localizations.dart';
import 'package:freelancer/screen/client screen/client job post/employer_verification_required_gate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// T-0171 edge cases (QA): every status value, unknown strings, server refusal
/// detection, and the gate screen's button callbacks. Fake data only.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('accessFor: every status value', () {
    test('known statuses map one-to-one', () {
      expect(
          EmployerVerificationGate.accessFor(
              {'verification_status': 'verified'}),
          EmployerPostAccess.approved);
      expect(
          EmployerVerificationGate.accessFor(
              {'verification_status': 'pending'}),
          EmployerPostAccess.pending);
      expect(
          EmployerVerificationGate.accessFor(
              {'verification_status': 'rejected'}),
          EmployerPostAccess.rejected);
    });

    test('unknown, empty and case-variant strings fall back to required', () {
      for (final s in [
        'approved',
        'unverified',
        'none',
        'VERIFIED',
        'Verified',
        'PENDING',
        'verified_pending',
        'pendingx',
        '',
        '   ',
      ]) {
        expect(EmployerVerificationGate.accessFor({'verification_status': s}),
            EmployerPostAccess.required,
            reason: 'status "$s"');
      }
    });

    test('surrounding whitespace is trimmed before matching', () {
      expect(
          EmployerVerificationGate.accessFor(
              {'verification_status': ' verified '}),
          EmployerPostAccess.approved);
      expect(
          EmployerVerificationGate.accessFor(
              {'verification_status': 'rejected\n'}),
          EmployerPostAccess.rejected);
    });

    test('missing profile and missing key both fall back to required', () {
      expect(EmployerVerificationGate.accessFor(null),
          EmployerPostAccess.required);
      expect(EmployerVerificationGate.accessFor(<String, dynamic>{}),
          EmployerPostAccess.required);
      expect(EmployerVerificationGate.canPost(null), isFalse);
    });

    test('a non-string status throws a TypeError (screen catches it)', () {
      // CreateNewJobPost._checkPostGate wraps accessFor in try/catch and then
      // sets EmployerPostAccess.required, so this cannot unlock posting.
      expect(
          () => EmployerVerificationGate.accessFor({'verification_status': 1}),
          throwsA(isA<TypeError>()));
    });

    test('only the exact approved value unlocks posting (canPost)', () {
      for (final s in ['verified', ' verified ']) {
        expect(EmployerVerificationGate.canPost({'verification_status': s}),
            isTrue,
            reason: s);
      }
      for (final s in ['pending', 'rejected', 'VERIFIED', 'approved', '']) {
        expect(EmployerVerificationGate.canPost({'verification_status': s}),
            isFalse,
            reason: s);
      }
    });
  });

  group('isBlockedByServer', () {
    test('RLS refusal as PostgrestException is recognised', () {
      final e = PostgrestException(
        message:
            'new row violates row-level security policy for table "job_posts"',
        code: '42501',
      );
      expect(EmployerVerificationGate.isBlockedByServer(e), isTrue);
    });

    test('matching is case-insensitive', () {
      expect(
          EmployerVerificationGate.isBlockedByServer(
              'ROW-LEVEL SECURITY POLICY VIOLATION'),
          isTrue);
    });

    test('bare 42501 (missing GRANT) is NOT a verification refusal', () {
      // A missing GRANT says "permission denied" and must show the raw error.
      final e = PostgrestException(
        message: 'permission denied for table job_posts',
        code: '42501',
      );
      expect(EmployerVerificationGate.isBlockedByServer(e), isFalse);
    });

    test('unrelated failures are not recognised', () {
      for (final e in <Object>[
        PostgrestException(message: 'duplicate key value', code: '23505'),
        PostgrestException(message: 'check constraint violated', code: '23514'),
        Exception('Not logged in'),
        'SocketException: Failed host lookup',
        'TimeoutException after 0:00:30',
      ]) {
        expect(EmployerVerificationGate.isBlockedByServer(e), isFalse,
            reason: e.toString());
      }
    });
  });

  group('gate screen buttons', () {
    Future<void> pump(
      WidgetTester t,
      EmployerPostAccess a, {
      required Future<void> Function() onVerify,
      Locale locale = const Locale('en'),
    }) async {
      await t.pumpWidget(MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: EmployerVerificationRequiredGate(access: a, onVerify: onVerify),
      ));
    }

    testWidgets('pending button label and callback', (t) async {
      final l10n = lookupAppLocalizations(const Locale('en'));
      var taps = 0;
      await pump(t, EmployerPostAccess.pending, onVerify: () async => taps++);
      expect(find.text(l10n.employerVerifyViewStatusButton), findsOneWidget);
      expect(find.text(l10n.employerVerifyStartButton), findsNothing);
      await t.tap(find.text(l10n.employerVerifyViewStatusButton));
      await t.pump();
      expect(taps, 1);
    });

    testWidgets('rejected shows resubmit copy and the start button', (t) async {
      final l10n = lookupAppLocalizations(const Locale('en'));
      await pump(t, EmployerPostAccess.rejected, onVerify: () async {});
      expect(find.text(l10n.employerVerifyRejectedBody), findsOneWidget);
      expect(find.text(l10n.employerVerifyRequiredTitle), findsOneWidget);
      expect(find.text(l10n.employerVerifyStartButton), findsOneWidget);
      expect(find.text(l10n.employerVerifyPendingTitle), findsNothing);
    });

    testWidgets('approved passed to the gate still shows required copy',
        (t) async {
      // Not reachable from CreateNewJobPost (it only builds the gate when not
      // approved). Recorded so a future change does not assume otherwise.
      final l10n = lookupAppLocalizations(const Locale('en'));
      await pump(t, EmployerPostAccess.approved, onVerify: () async {});
      expect(find.text(l10n.employerVerifyRequiredTitle), findsOneWidget);
    });

    testWidgets('NL pending: title switches to under-review copy', (t) async {
      final l10n = lookupAppLocalizations(const Locale('nl'));
      await pump(t, EmployerPostAccess.pending,
          onVerify: () async {}, locale: const Locale('nl'));
      expect(find.text(l10n.employerVerifyPendingTitle), findsOneWidget);
      expect(find.text(l10n.employerVerifyPendingBody), findsOneWidget);
      expect(find.text(l10n.employerVerifyRequiredTitle), findsNothing);
    });
  });
}
