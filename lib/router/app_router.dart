import 'dart:async';

import 'package:flutter/material.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/auth/role_cache.dart';
import '../core/constants/colors.dart';
import '../core/utils/app_logger.dart';
import '../services/auth_service.dart';

// Old screens — used during incremental migration
import '../screen/splash screen/mt_splash_screen.dart';
import '../screen/splash screen/onboard.dart';
import '../screen/welcome screen/welcome_screen.dart';
import '../screen/client screen/client_authentication/client_log_in.dart';
import '../screen/client screen/client_authentication/client_sign_up.dart';
import '../screen/client screen/client home/client_home_screen.dart';
import '../screen/client screen/client home/top_seller.dart';
import '../screen/client screen/client orders/client_orders.dart';
import '../screen/client screen/client profile/client_profile.dart';
import '../screen/client screen/client job post/client_job_post.dart';
import '../screen/seller screen/seller authentication/seller_log_in.dart';
import '../screen/seller screen/seller authentication/seller_sign_up.dart';
import '../screen/seller screen/seller home/seller_home_screen.dart';
import '../screen/seller screen/orders/seller_orders.dart';
import '../screen/seller screen/orders/seller_order_details.dart';
import '../screen/seller screen/profile/seller_profile.dart';
import '../screen/seller screen/applications/seller_applications.dart';
import '../screen/seller screen/buyer request/seller_buyer_request.dart';
import '../screen/seller screen/seller message/chat_list.dart';
import '../screen/attendance/attendance_scan_screen.dart';
import '../screen/attendance/seller_attendance_hub_screen.dart';
import '../screen/widgets/shell_tab_header.dart';

/// Root navigator for overlays and notification tap navigation.
final rootNavigatorKey = GlobalKey<NavigatorState>();
final _clientShellKey = GlobalKey<NavigatorState>();
final _sellerShellKey = GlobalKey<NavigatorState>();

/// Key on the client shell's Scaffold so descendant screens can open the
/// drawer (e.g. from a hamburger button in the AppHeader).
final clientShellScaffoldKey = GlobalKey<ScaffoldState>();

/// Key on the seller shell's Scaffold (drawer with [SellerProfile]).
final sellerShellScaffoldKey = GlobalKey<ScaffoldState>();

/// Opens the client or seller shell drawer based on the current shell route.
void openRoleShellDrawer(BuildContext context) {
  final path = GoRouterState.of(context).uri.path;
  if (path.startsWith('/seller')) {
    sellerShellScaffoldKey.currentState?.openDrawer();
  } else if (path.startsWith('/client')) {
    clientShellScaffoldKey.currentState?.openDrawer();
  }
}

GoRouter createRouter() {
  final supabase = Supabase.instance.client;

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final session = supabase.auth.currentSession;
      final loggedIn = session != null;
      final location = state.matchedLocation;
      final isSplash = location == '/';
      final isPublicAuthRoute = location.startsWith('/onboard') ||
          location.startsWith('/welcome') ||
          location.startsWith('/auth');

      // Not signed in — send to the login hub (welcome)
      if (!loggedIn) {
        RoleCache.clear();
        if (isSplash) return '/welcome';
        return isPublicAuthRoute ? null : '/welcome';
      }

      // Source of truth: profiles.role (cached). Never use JWT userMetadata here.
      final role = AuthService.cachedRole;

      // Signed in — bounce splash/auth screens to the correct home
      if (isSplash || isPublicAuthRoute) {
        if (role == null) {
          // Role still loading from profiles; stay put until refresh notifies.
          return null;
        }
        return AuthService.homePathForRole(role);
      }

      // Keep users on the shell that matches their DB role.
      if (role != null) {
        if (role == 'seller' && location.startsWith('/client')) {
          return '/seller';
        }
        if (role == 'client' && location.startsWith('/seller')) {
          return '/client';
        }
      }

      // Seller menu is the shell drawer (removed tab route).
      if (location == '/seller/profile') {
        return '/seller';
      }

      return null;
    },
    refreshListenable:
        _SupabaseAuthRefreshStream(supabase.auth.onAuthStateChange),
    routes: [
      // Splash
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth routes
      GoRoute(path: '/onboard', builder: (context, state) => const OnBoard()),
      GoRoute(path: '/welcome', builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: '/auth/client/login', builder: (context, state) => const ClientLogIn()),
      GoRoute(path: '/auth/client/signup', builder: (context, state) => const ClientSignUp()),
      GoRoute(path: '/auth/seller/login', builder: (context, state) => const SellerLogIn()),
      GoRoute(path: '/auth/seller/signup', builder: (context, state) => const SellerSignUp()),

      // Client shell with bottom nav
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _ScaffoldWithNavBar(
            persona: ShellPersona.client,
            scaffoldKey: clientShellScaffoldKey,
            drawer: const Drawer(child: ClientProfile()),
            navigationShell: navigationShell,
          );
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _clientShellKey,
            routes: [
              GoRoute(
                path: '/client',
                builder: (context, state) => const ClientHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/client/chat',
              builder: (context, state) => const ChatScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/client/talent',
              builder: (context, state) => const TopSeller(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/client/jobs',
              builder: (context, state) => const JobPost(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/client/orders',
              builder: (context, state) => const ClientOrderList(),
            ),
          ]),
        ],
      ),

      // Seller shell with bottom nav
      // Seller shell: blue primary, tinted scaffold (see [kSellerSurface]).
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          final base = Theme.of(context);
          return Theme(
            data: base.copyWith(
              colorScheme: base.colorScheme.copyWith(
                primary: kSellerPrimary,
                secondary: kSellerAccent,
                onPrimary: kWhite,
              ),
              primaryColor: kSellerPrimary,
              scaffoldBackgroundColor: kSellerSurface,
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kSellerPrimary,
                  foregroundColor: kWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
              ),
              floatingActionButtonTheme: const FloatingActionButtonThemeData(
                backgroundColor: kSellerPrimary,
                foregroundColor: kWhite,
              ),
              progressIndicatorTheme: const ProgressIndicatorThemeData(color: kSellerPrimary),
            ),
            child: _ScaffoldWithNavBar(
              persona: ShellPersona.seller,
              scaffoldKey: sellerShellScaffoldKey,
              drawer: const Drawer(child: SellerProfile()),
              navigationShell: navigationShell,
            ),
          );
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _sellerShellKey,
            routes: [
              GoRoute(
                path: '/seller',
                builder: (context, state) => const SellerHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/seller/chat',
              builder: (context, state) => const ChatScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/seller/find-jobs',
              builder: (context, state) => const SellerBuyerRequest(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/seller/orders',
              builder: (context, state) => const SellerOrderList(),
            ),
          ]),
        ],
      ),

      // Seller — My Applications (sub-screen, outside the shell so it pushes
      // on top of the bottom-nav scaffold).
      GoRoute(
        path: '/seller/applications',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SellerApplications(),
      ),
      GoRoute(
        path: '/seller/orders/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => SellerOrderDetails(
          orderId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/seller/attendance',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => SellerAttendanceHubScreen(
          highlightJobPostId: state.uri.queryParameters['jobPostId'],
        ),
      ),
      GoRoute(
        path: '/seller/attendance/scan',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => AttendanceScanScreen(
          hintJobPostId: state.uri.queryParameters['jobPostId'],
        ),
      ),
    ],
  );
}

List<BottomNavigationBarItem> _clientNavItems(BuildContext context) {
  final l10n = context.l10n;
  return [
    BottomNavigationBarItem(
      icon: const Icon(Icons.home_outlined),
      activeIcon: const Icon(Icons.home),
      label: l10n.home,
    ),
    BottomNavigationBarItem(
      icon: const Icon(Icons.chat_bubble_outline),
      activeIcon: const Icon(Icons.chat_bubble),
      label: l10n.message,
    ),
    BottomNavigationBarItem(
      icon: const Icon(Icons.people_outline),
      activeIcon: const Icon(Icons.people),
      label: l10n.talent,
    ),
    BottomNavigationBarItem(
      icon: const Icon(Icons.work_outline),
      activeIcon: const Icon(Icons.work),
      label: l10n.myJobs,
    ),
    BottomNavigationBarItem(
      icon: const Icon(Icons.description_outlined),
      activeIcon: const Icon(Icons.description),
      label: l10n.contracts,
    ),
  ];
}

List<BottomNavigationBarItem> _sellerNavItems(BuildContext context) {
  final l10n = context.l10n;
  return [
    BottomNavigationBarItem(
      icon: const Icon(Icons.home_outlined),
      activeIcon: const Icon(Icons.home),
      label: l10n.home,
    ),
    BottomNavigationBarItem(
      icon: const Icon(Icons.chat_bubble_outline),
      activeIcon: const Icon(Icons.chat_bubble),
      label: l10n.message,
    ),
    BottomNavigationBarItem(
      icon: const Icon(Icons.search),
      activeIcon: const Icon(Icons.search),
      label: l10n.findJobs,
    ),
    BottomNavigationBarItem(
      icon: const Icon(Icons.description_outlined),
      activeIcon: const Icon(Icons.description),
      label: l10n.contracts,
    ),
  ];
}

/// Shared bottom nav for client and seller shells.
class _ScaffoldWithNavBar extends StatelessWidget {
  final ShellPersona persona;
  final StatefulNavigationShell navigationShell;
  final Widget? drawer;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const _ScaffoldWithNavBar({
    required this.persona,
    required this.navigationShell,
    this.drawer,
    this.scaffoldKey,
  });

  Color get _accentColor =>
      persona == ShellPersona.client ? kPrimaryColor : kSellerPrimary;

  @override
  Widget build(BuildContext context) {
    final items = persona == ShellPersona.client
        ? _clientNavItems(context)
        : _sellerNavItems(context);

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: kWhite,
      extendBody: false,
      drawer: drawer,
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: kWhite,
          border: Border(top: BorderSide(color: kBorderColorTextField)),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: kWhite,
          elevation: 0,
          selectedItemColor: _accentColor,
          unselectedItemColor: kLightNeutralColor,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          showUnselectedLabels: true,
          currentIndex: navigationShell.currentIndex,
          onTap: (i) => navigationShell.goBranch(
            i,
            initialLocation: i == navigationShell.currentIndex,
          ),
          items: items,
        ),
      ),
    );
  }
}

/// Bridges Supabase auth + [profiles.role] loading to GoRouter redirects.
class _SupabaseAuthRefreshStream extends ChangeNotifier {
  _SupabaseAuthRefreshStream(Stream<AuthState> stream) {
    _subscription = stream.listen((authState) {
      unawaited(_onAuthEvent(authState));
    });
    // Cold start: session may already exist before the first stream event.
    if (Supabase.instance.client.auth.currentSession != null) {
      unawaited(_ensureRoleCached());
    }
  }

  late final StreamSubscription<AuthState> _subscription;

  Future<void> _onAuthEvent(AuthState authState) async {
    final session = authState.session;
    if (session == null) {
      RoleCache.clear();
      notifyListeners();
      return;
    }
    await _ensureRoleCached();
  }

  Future<void> _ensureRoleCached() async {
    try {
      await AuthService.getUserRole(forceRefresh: true);
    } catch (e, st) {
      AppLogger.error('Router.ensureRoleCached', e, st);
      // Keep previous cache if refresh fails; redirect will wait or use last value.
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
