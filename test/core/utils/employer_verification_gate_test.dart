import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/utils/employer_verification_gate.dart';
import 'package:freelancer/l10n/app_localizations.dart';
import 'package:freelancer/screen/client%20screen/client%20job%20post/employer_verification_required_gate.dart';
import 'package:google_fonts/google_fonts.dart';

/// T-0171: employers may post only after an admin approved the verification.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('ever approved (first_verified_at)', () {
    test('approved once keeps posting while pending/rejected', () {
      final row = {'first_verified_at': '2026-11-01T10:00:00Z'};
      for (final st in ['pending', 'rejected', 'unverified', null]) {
        expect(
            EmployerVerificationGate.accessFor({'verification_status': st},
                verification: row),
            EmployerPostAccess.approved,
            reason: '$st');
      }
    });
    test('never approved: pending stays under review, rejected/none blocked',
        () {
      final row = {'first_verified_at': null, 'status': 'pending'};
      expect(
          EmployerVerificationGate.accessFor({'verification_status': 'pending'},
              verification: row),
          EmployerPostAccess.pending);
      expect(
          EmployerVerificationGate.accessFor(
              {'verification_status': 'rejected'},
              verification: row),
          EmployerPostAccess.rejected);
      expect(EmployerVerificationGate.accessFor(null, verification: row),
          EmployerPostAccess.required);
      expect(EmployerVerificationGate.canPost({}, verification: null), isFalse);
    });
  });

  group('EmployerVerificationGate.accessFor', () {
    test('only "verified" may post', () {
      expect(
          EmployerVerificationGate.accessFor(
              {'verification_status': 'verified'}),
          EmployerPostAccess.approved);
      expect(
          EmployerVerificationGate.canPost({'verification_status': 'verified'}),
          isTrue);
    });
    test('pending / rejected / unverified / missing / null are blocked', () {
      expect(
          EmployerVerificationGate.accessFor(
              {'verification_status': 'pending'}),
          EmployerPostAccess.pending);
      expect(
          EmployerVerificationGate.accessFor(
              {'verification_status': 'rejected'}),
          EmployerPostAccess.rejected);
      for (final p in <Map<String, dynamic>?>[
        {'verification_status': 'unverified'},
        {'verification_status': ''},
        {'verification_status': null},
        {'verification_status': 'approved'},
        <String, dynamic>{},
        null,
      ]) {
        expect(
            EmployerVerificationGate.accessFor(p), EmployerPostAccess.required);
        expect(EmployerVerificationGate.canPost(p), isFalse);
      }
    });
    test('photo status alone does not unlock posting', () {
      expect(
          EmployerVerificationGate.canPost({
            'profile_photo_status': 'verified',
            'verification_status': 'unverified'
          }),
          isFalse);
    });
    test('server refusal is recognised', () {
      expect(
          EmployerVerificationGate.isBlockedByServer(
              'PostgrestException(message: new row violates row-level security policy for table "job_posts", code: 42501)'),
          isTrue);
      expect(EmployerVerificationGate.isBlockedByServer('SocketException'),
          isFalse);
    });
  });

  Future<void> pump(WidgetTester t, EmployerPostAccess a, Locale l,
      {VoidCallback? onVerify}) async {
    await t.pumpWidget(MaterialApp(
      locale: l,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: EmployerVerificationRequiredGate(
        access: a,
        onVerify: () async => onVerify?.call(),
      ),
    ));
  }

  for (final code in ['en', 'nl', 'bn']) {
    testWidgets('gate copy + button ($code)', (t) async {
      final l10n = lookupAppLocalizations(Locale(code));
      var taps = 0;
      await pump(t, EmployerPostAccess.required, Locale(code),
          onVerify: () => taps++);
      expect(find.text(l10n.employerVerifyRequiredTitle), findsOneWidget);
      expect(find.text(l10n.employerVerifyRequiredBody), findsOneWidget);
      await t.tap(find.text(l10n.employerVerifyStartButton));
      expect(taps, 1);

      await pump(t, EmployerPostAccess.pending, Locale(code));
      expect(find.text(l10n.employerVerifyPendingTitle), findsOneWidget);
      expect(find.text(l10n.employerVerifyPendingBody), findsOneWidget);
      expect(find.text(l10n.employerVerifyViewStatusButton), findsOneWidget);

      await pump(t, EmployerPostAccess.rejected, Locale(code));
      expect(find.text(l10n.employerVerifyRejectedBody), findsOneWidget);
    });
  }

  test('copy says required (verplicht), not optional', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final nl = lookupAppLocalizations(const Locale('nl'));
    final bn = lookupAppLocalizations(const Locale('bn'));
    for (final s in [en.employerVerifyUpgradeHint, en.guideEmpVerifScoreDesc]) {
      expect(s.toLowerCase(), contains('required'));
      expect(s.toLowerCase(), isNot(contains('optional')));
    }
    for (final s in [nl.employerVerifyUpgradeHint, nl.guideEmpVerifScoreDesc]) {
      expect(s.toLowerCase(), contains('verplicht'));
      expect(s.toLowerCase(), isNot(contains('optioneel')));
    }
    expect(nl.employerVerifyRequiredBody.toLowerCase(), contains('verplicht'));
    expect(bn.employerVerifyUpgradeHint, isNot(contains('ঐচ্ছিক')));
    expect(bn.guideEmpVerifScoreDesc, contains('বাধ্যতামূলক'));
  });

  testWidgets('small phone, big text: no overflow', (t) async {
    await t.binding.setSurfaceSize(const Size(375, 667));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(MaterialApp(
      locale: const Locale('nl'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (c, w) => MediaQuery(
          data: MediaQuery.of(c)
              .copyWith(textScaler: const TextScaler.linear(2.0)),
          child: w!),
      home: EmployerVerificationRequiredGate(
          access: EmployerPostAccess.required, onVerify: () async {}),
    ));
    expect(t.takeException(), isNull);
  });
}
