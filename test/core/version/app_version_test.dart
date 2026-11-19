import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/version/app_build.dart';
import 'package:freelancer/core/version/app_version_gate.dart';
import 'package:freelancer/l10n/app_localizations.dart';

Widget _host(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: child,
    );

void main() {
  test('kAppBuildNumber matches the build number in pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final m = RegExp(r'^version:\s*\S+\+(\d+)\s*$', multiLine: true)
        .firstMatch(pubspec);
    expect(m, isNotNull, reason: 'pubspec version: x.y.z+N not found');
    expect(kAppBuildNumber, int.parse(m!.group(1)!));
  });

  group('AppUpdateRequirement', () {
    test('parses the RPC payload', () {
      final r = AppUpdateRequirement.fromRpc(
          {'min_build': 7, 'update_url': ' https://example.test/app '});
      expect(r!.minBuild, 7);
      expect(r.updateUrl, 'https://example.test/app');
    });

    test('unexpected payloads are ignored (gate stays open)', () {
      expect(AppUpdateRequirement.fromRpc(null), isNull);
      expect(AppUpdateRequirement.fromRpc('x'), isNull);
      expect(AppUpdateRequirement.fromRpc({'min_build': 'abc'}), isNull);
      expect(
          AppUpdateRequirement.fromRpc({'min_build': 3, 'update_url': ''})!
              .updateUrl,
          isNull);
    });

    test('blocks only when a positive minimum is above the current build', () {
      expect(const AppUpdateRequirement(minBuild: 0).blocks(1), isFalse);
      expect(const AppUpdateRequirement(minBuild: 6).blocks(5), isTrue);
      expect(const AppUpdateRequirement(minBuild: 6).blocks(6), isFalse);
      expect(const AppUpdateRequirement(minBuild: 6).blocks(9), isFalse);
    });
  });

  group('AppVersionGate widget', () {
    testWidgets('shows the update screen when the build is too old',
        (tester) async {
      await tester.pumpWidget(_host(AppVersionGate(
        currentBuild: 5,
        fetch: () async => const AppUpdateRequirement(
            minBuild: 6, updateUrl: 'https://example.test/app'),
        child: const Text('APP'),
      )));
      await tester.pumpAndSettle();
      expect(find.text('Update required'), findsOneWidget);
      expect(find.text('Update the app'), findsOneWidget);
    });

    testWidgets('does not block when the build is new enough', (tester) async {
      await tester.pumpWidget(_host(AppVersionGate(
        currentBuild: 6,
        fetch: () async => const AppUpdateRequirement(minBuild: 6),
        child: const Text('APP'),
      )));
      await tester.pumpAndSettle();
      expect(find.text('Update required'), findsNothing);
      expect(find.text('APP'), findsOneWidget);
    });

    testWidgets('fails open when the check returns nothing', (tester) async {
      await tester.pumpWidget(_host(AppVersionGate(
        currentBuild: 1,
        fetch: () async => null,
        child: const Text('APP'),
      )));
      await tester.pumpAndSettle();
      expect(find.text('Update required'), findsNothing);
    });
  });
}
