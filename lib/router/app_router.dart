import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/colors.dart';

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
import '../screen/seller screen/seller messgae/chat_list.dart';
import '../screen/attendance/attendance_scan_screen.dart';
import '../screen/attendance/seller_attendance_hub_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
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
    navigatorKey: _rootNavigatorKey,
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
        if (isSplash) return '/welcome';
        return isPublicAuthRoute ? null : '/welcome';
      }

      // Signed in — bounce splash/auth screens to the correct home
      if (isSplash || isPublicAuthRoute) {
        final role = supabase.auth.currentUser?.userMetadata?['role'] as String?;
        return role == 'seller' ? '/seller' : '/client';
      }

      // Seller menu is the shell drawer (removed tab route).
      if (loggedIn && location == '/seller/profile') {
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
            scaffoldKey: clientShellScaffoldKey,
            drawer: const Drawer(child: ClientProfile()),
            navigationShell: navigationShell,
            items: const [
              BottomNavigationBarItem(icon: Icon(IconlyBold.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(IconlyBold.chat), label: 'Message'),
              BottomNavigationBarItem(icon: Icon(IconlyBold.user3), label: 'Talent'),
              BottomNavigationBarItem(icon: Icon(IconlyBold.paperPlus), label: 'My Jobs'),
              BottomNavigationBarItem(icon: Icon(IconlyBold.document), label: 'Contracts'),
            ],
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
              scaffoldKey: sellerShellScaffoldKey,
              drawer: const Drawer(child: SellerProfile()),
              navigationShell: navigationShell,
              items: const [
                BottomNavigationBarItem(icon: Icon(IconlyBold.home), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(IconlyBold.chat), label: 'Message'),
                BottomNavigationBarItem(icon: Icon(IconlyBold.search), label: 'Find Jobs'),
                BottomNavigationBarItem(icon: Icon(IconlyBold.document), label: 'Contracts'),
              ],
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
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SellerApplications(),
      ),
      GoRoute(
        path: '/seller/orders/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => SellerOrderDetails(
          orderId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/seller/attendance',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => SellerAttendanceHubScreen(
          highlightJobPostId: state.uri.queryParameters['jobPostId'],
        ),
      ),
      GoRoute(
        path: '/seller/attendance/scan',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => AttendanceScanScreen(
          hintJobPostId: state.uri.queryParameters['jobPostId'],
        ),
      ),
    ],
  );
}

/// Shared bottom nav for client and seller shells.
///
/// Uses a standard [BottomNavigationBar] with [extendBody] disabled so tab
/// bodies reserve space above the bar and content is not covered (no manual
/// “floating nav” padding hacks in every screen).
class _ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final List<BottomNavigationBarItem> items;
  final Widget? drawer;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const _ScaffoldWithNavBar({
    required this.navigationShell,
    required this.items,
    this.drawer,
    this.scaffoldKey,
  });

  @override
  Widget build(BuildContext context) {
    final manyTabs = items.length > 4;

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: false,
      drawer: drawer,
      body: navigationShell,
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: kPrimaryColor.withOpacity(0.12),
          highlightColor: Colors.transparent,
        ),
        child: SafeArea(
          top: false,
            child: Material(
            color: Theme.of(context).scaffoldBackgroundColor,
            elevation: 10,
            shadowColor: Colors.black26,
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              selectedItemColor: Theme.of(context).colorScheme.primary,
              unselectedItemColor: kLightNeutralColor,
              selectedFontSize: 12,
              unselectedFontSize: 11,
              showUnselectedLabels: !manyTabs,
              currentIndex: navigationShell.currentIndex,
              onTap: (i) => navigationShell.goBranch(
                i,
                initialLocation: i == navigationShell.currentIndex,
              ),
              items: items,
            ),
          ),
        ),
      ),
    );
  }
}

/// Bridges Supabase's auth state stream to a ChangeNotifier so GoRouter
/// re-evaluates the redirect every time the user signs in or out.
class _SupabaseAuthRefreshStream extends ChangeNotifier {
  _SupabaseAuthRefreshStream(Stream<AuthState> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
