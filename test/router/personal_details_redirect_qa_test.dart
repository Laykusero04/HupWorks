import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer/l10n/app_localizations.dart';
import 'package:freelancer/router/app_router.dart';
import 'package:freelancer/router/route_names.dart';
import 'package:freelancer/services/auth_service.dart';
import 'package:freelancer/services/personal_details_gate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/qa_supabase.dart';

/// T-0172 QA: GoRouter redirects for the first-sign-in personal details step,
/// through the real [createRouter] with a Router attached. The initial location
/// is set before the first pump so the splash screen never builds (its own
/// timers would race with the test). Fake signed-in user only.
/// The shell screens load Inter/Jost through google_fonts, which cannot fetch
/// or find assets in tests. Drop only those errors, as the other auth tests do.
void guardedTest(
  String name,
  Future<void> Function(WidgetTester t) body,
) {
  testWidgets(name, (t) {
    // The client shell needs app-root providers (ChatUnreadScope) that this
    // host does not mount. Only that known build error is dropped; the
    // redirect result is asserted from the router location.
    final previous = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exceptionAsString().contains('ChatUnreadScope not found')) return;
      previous?.call(d);
    };
    addTearDown(() => FlutterError.onError = previous);
    final done = Completer<void>();
    runZonedGuarded(() async {
      try {
        await body(t);
        if (!done.isCompleted) done.complete();
      } catch (e, s) {
        if (!done.isCompleted) done.completeError(e, s);
      }
    }, (error, stack) {
      if (error.toString().contains('google_fonts') ||
          error.toString().contains('allowRuntimeFetching')) {
        return;
      }
      if (!done.isCompleted) done.completeError(error, stack);
    });
    return done.future;
  });
}

void main() {
  // Mutable fake backend state.
  var role = 'client';
  var onboardingDone = true;
  Map<String, Object?>? detailsRow;

  setUpAll(() async {
    await initQaSupabase(
      signedIn: true,
      tables: {
        'my_profile': (_) => {
              'id': qaSignedInUserId,
              'role': role,
              'seller_onboarding_completed': onboardingDone,
            },
        'profiles': (_) => null,
        'user_private_details': (_) => detailsRow,
      },
    );
  });

  setUp(() async {
    role = 'client';
    onboardingDone = true;
    detailsRow = null;
    await (await SharedPreferences.getInstance()).clear();
    AuthService.clearRoleCache();
    PersonalDetailsGate.reset();
  });

  Future<void> settle(WidgetTester t) async {
    await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)));
    await t.pump();
  }

  /// Mounts the real router already at [path] and waits for the cold-start
  /// role and gate load (the refresh listener re-runs the redirects).
  Future<GoRouter> mount(WidgetTester t, String path) async {
    final router = createRouter();
    router.go(path);
    await t.pumpWidget(MaterialApp.router(
      routerConfig: router,
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
    ));
    await settle(t);
    return router;
  }

  /// Navigates and returns the resulting location after redirects.
  Future<String> go(WidgetTester t, GoRouter router, String path) async {
    router.go(path);
    await settle(t);
    return router.routeInformationProvider.value.uri.path;
  }

  /// Lets pending widget timers run out before the test ends.
  Future<void> unmount(WidgetTester t) async {
    await t.pump(const Duration(seconds: 1));
  }

  guardedTest('client, first sign-in: shell redirects to personal details',
      (t) async {
    final router = await mount(t, AppRoutes.clientHome);
    expect(router.routeInformationProvider.value.uri.path,
        AppRoutes.personalDetails);
    await unmount(t);
  });

  guardedTest('no loop: staying on personal details keeps it there',
      (t) async {
    final router = await mount(t, AppRoutes.personalDetails);
    for (var i = 0; i < 3; i++) {
      expect(await go(t, router, AppRoutes.personalDetails),
          AppRoutes.personalDetails,
          reason: 'round $i');
    }
    await unmount(t);
  });

  guardedTest('after skip: shell opens, personal details bounces home',
      (t) async {
    final router = await mount(t, AppRoutes.personalDetails);
    expect(PersonalDetailsGate.needsPrompt, isTrue);
    await PersonalDetailsGate.markSkipped();

    expect(await go(t, router, AppRoutes.clientHome), AppRoutes.clientHome);
    expect(await go(t, router, AppRoutes.personalDetails), AppRoutes.clientHome,
        reason: 'a skipped user is not forced back into the step');
    await unmount(t);
  });

  guardedTest('trust route stays reachable after skip', (t) async {
    final router = await mount(t, AppRoutes.clientHome);
    await PersonalDetailsGate.markSkipped();
    expect(await go(t, router, AppRoutes.personalDetailsEdit),
        AppRoutes.personalDetailsEdit);
    await unmount(t);
  });

  guardedTest('freelancer: wizard first, personal details only after it',
      (t) async {
    role = 'seller';
    onboardingDone = false;
    final router = await mount(t, '/seller');
    expect(router.routeInformationProvider.value.uri.path,
        AppRoutes.sellerSetupProfile,
        reason: 'wizard has priority over the personal details step');

    AuthService.markSellerOnboardingCompleted();
    expect(await go(t, router, '/seller'), AppRoutes.personalDetails);
    await unmount(t);
  });

  guardedTest('saved consent for the current text: no prompt', (t) async {
    detailsRow = {
      'user_id': qaSignedInUserId,
      'date_of_birth': '1990-05-07',
      'consent_version': 'privacy-2026-11',
      'consented_at': '2026-11-20T10:00:00Z',
    };
    final router = await mount(t, AppRoutes.clientHome);
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.clientHome);
    await unmount(t);
  });
}
