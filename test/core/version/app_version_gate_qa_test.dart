import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/core/version/app_build.dart';
import 'package:freelancer/core/version/app_version_gate.dart';
import 'package:freelancer/l10n/app_localizations.dart';

/// T-0128 QA: the minimum-build gate.
///  - blocks with the "Update required" screen when build < min
///  - fails OPEN when the check errors, returns nothing or never returns
Widget _host(Widget child, {Locale locale = const Locale('en')}) =>
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: child,
    );

void main() {
  group('blocks when build < min', () {
    testWidgets('below the minimum shows Update required and the store button',
        (tester) async {
      await tester.pumpWidget(_host(AppVersionGate(
        currentBuild: 5,
        fetch: () async => const AppUpdateRequirement(
            minBuild: 6, updateUrl: 'https://example.test/store'),
        child: const Text('APP'),
      )));
      await tester.pumpAndSettle();
      expect(find.text('Update required'), findsOneWidget);
      expect(find.text('Update the app'), findsOneWidget);
      expect(find.byIcon(Icons.system_update), findsOneWidget);
    });

    testWidgets('uses the real kAppBuildNumber: min = current + 1 blocks',
        (tester) async {
      await tester.pumpWidget(_host(AppVersionGate(
        fetch: () async =>
            AppUpdateRequirement(minBuild: kAppBuildNumber + 1),
        child: const Text('APP'),
      )));
      await tester.pumpAndSettle();
      expect(find.text('Update required'), findsOneWidget);
      // No store URL: the screen still blocks, without a button.
      expect(find.text('Update the app'), findsNothing);
    });

    testWidgets('uses the real kAppBuildNumber: min = current does not block',
        (tester) async {
      await tester.pumpWidget(_host(AppVersionGate(
        fetch: () async => AppUpdateRequirement(minBuild: kAppBuildNumber),
        child: const Text('APP'),
      )));
      await tester.pumpAndSettle();
      expect(find.text('Update required'), findsNothing);
      expect(find.text('APP'), findsOneWidget);
    });

    testWidgets('NL at XL text scale (1.5): blocking screen renders without overflow',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('nl'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: AppVersionGate(
          currentBuild: 5,
          fetch: () async => const AppUpdateRequirement(
              minBuild: 6, updateUrl: 'https://example.test/store'),
          child: const Text('APP'),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Update vereist'), findsOneWidget);
      expect(find.text('App bijwerken'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('EN at XL text scale (1.5): blocking screen renders without overflow',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(1.5)),
        child: child!,
      ),
      home: AppVersionGate(
        currentBuild: 5,
        fetch: () async => const AppUpdateRequirement(
            minBuild: 6, updateUrl: 'https://example.test/store'),
        child: const Text('APP'),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Update required'), findsOneWidget);
    expect(find.text('Update the app'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('fails open', () {
    testWidgets('check returns nothing: app stays usable', (tester) async {
      await tester.pumpWidget(_host(AppVersionGate(
        currentBuild: 1,
        fetch: () async => null,
        child: const Text('APP'),
      )));
      await tester.pumpAndSettle();
      expect(find.text('Update required'), findsNothing);
      expect(find.text('APP'), findsOneWidget);
    });

    testWidgets('check never returns: app stays usable, nothing is blocked',
        (tester) async {
      await tester.pumpWidget(_host(AppVersionGate(
        currentBuild: 1,
        fetch: () => Completer<AppUpdateRequirement?>().future,
        child: const Text('APP'),
      )));
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('Update required'), findsNothing);
      expect(find.text('APP'), findsOneWidget);
    });

    testWidgets('check throws: app stays usable and no error escapes',
        (tester) async {
      await tester.pumpWidget(_host(AppVersionGate(
        currentBuild: 1,
        fetch: () async => throw StateError('simulated RPC failure'),
        child: const Text('APP'),
      )));
      await tester.pumpAndSettle();
      expect(find.text('Update required'), findsNothing);
      expect(find.text('APP'), findsOneWidget);
    });

    test('production fetch on this desktop test host returns null (no RPC)',
        () async {
      // Platform is neither iOS nor Android here, so the gate never calls the
      // RPC and stays open. Supabase is not initialised in this file.
      expect(await fetchAppUpdateRequirement(), isNull);
    });
  });
}
