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
import '../screen/client screen/client orders/client_orders.dart';
import '../screen/client screen/client profile/client_profile.dart';
import '../screen/client screen/client job post/client_job_post.dart';
import '../screen/seller screen/seller authentication/seller_log_in.dart';
import '../screen/seller screen/seller authentication/seller_sign_up.dart';
import '../screen/seller screen/seller home/seller_home_screen.dart';
import '../screen/seller screen/orders/seller_orders.dart';
import '../screen/seller screen/profile/seller_profile.dart';
import '../screen/seller screen/applications/seller_applications.dart';
import '../screen/seller screen/buyer request/seller_buyer_request.dart';
import '../screen/seller screen/seller messgae/chat_list.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _clientShellKey = GlobalKey<NavigatorState>();
final _sellerShellKey = GlobalKey<NavigatorState>();

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
            navigationShell: navigationShell,
            items: const [
              BottomNavigationBarItem(icon: Icon(IconlyBold.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(IconlyBold.chat), label: 'Message'),
              BottomNavigationBarItem(icon: Icon(IconlyBold.paperPlus), label: 'My Jobs'),
              BottomNavigationBarItem(icon: Icon(IconlyBold.document), label: 'Contracts'),
              BottomNavigationBarItem(icon: Icon(IconlyBold.profile), label: 'Profile'),
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
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/client/profile',
              builder: (context, state) => const ClientProfile(),
            ),
          ]),
        ],
      ),

      // Seller shell with bottom nav
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _ScaffoldWithNavBar(
            navigationShell: navigationShell,
            items: const [
              BottomNavigationBarItem(icon: Icon(IconlyBold.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(IconlyBold.chat), label: 'Message'),
              BottomNavigationBarItem(icon: Icon(IconlyBold.search), label: 'Find Jobs'),
              BottomNavigationBarItem(icon: Icon(IconlyBold.document), label: 'Contracts'),
              BottomNavigationBarItem(icon: Icon(IconlyBold.profile), label: 'Profile'),
            ],
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
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/seller/profile',
              builder: (context, state) => const SellerProfile(),
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
    ],
  );
}

/// Shared bottom nav scaffold for both client and seller shells
class _ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final List<BottomNavigationBarItem> items;

  const _ScaffoldWithNavBar({
    required this.navigationShell,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWhite,
      body: navigationShell,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: const BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(30.0),
            topLeft: Radius.circular(30.0),
          ),
          boxShadow: [BoxShadow(color: kDarkWhite, blurRadius: 5.0, spreadRadius: 3.0, offset: Offset(0, -2))],
        ),
        child: BottomNavigationBar(
          elevation: 0.0,
          selectedItemColor: kPrimaryColor,
          unselectedItemColor: kLightNeutralColor,
          backgroundColor: kWhite,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          items: items,
          currentIndex: navigationShell.currentIndex,
          onTap: (index) => navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
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
