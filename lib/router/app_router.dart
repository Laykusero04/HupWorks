import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/colors.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../features/auth/bloc/auth_state.dart';

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
import '../screen/seller screen/seller services/create_service.dart';
import '../screen/seller screen/seller messgae/chat_list.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _clientShellKey = GlobalKey<NavigatorState>();
final _sellerShellKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final authState = authBloc.state;
      final location = state.matchedLocation;
      final isAuthRoute = location == '/' ||
          location.startsWith('/onboard') ||
          location.startsWith('/welcome') ||
          location.startsWith('/auth');

      // Still loading auth state — show splash
      if (authState is AuthInitial || authState is AuthLoading) {
        return location == '/' ? null : '/';
      }

      // Not authenticated — redirect to onboard if trying to access protected routes
      if (authState is Unauthenticated || authState is AuthError) {
        return isAuthRoute ? null : '/onboard';
      }

      // Authenticated — redirect away from auth routes to correct home
      if (authState is Authenticated && isAuthRoute) {
        return authState.role == 'seller' ? '/seller' : '/client';
      }

      return null;
    },
    refreshListenable: _GoRouterAuthRefreshStream(authBloc.stream),
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
              BottomNavigationBarItem(icon: Icon(IconlyBold.paperPlus), label: 'Job Apply'),
              BottomNavigationBarItem(icon: Icon(IconlyBold.document), label: 'Orders'),
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
              BottomNavigationBarItem(icon: Icon(IconlyBold.paperPlus), label: 'Service'),
              BottomNavigationBarItem(icon: Icon(IconlyBold.document), label: 'Orders'),
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
              path: '/seller/create-service',
              builder: (context, state) => const CreateService(),
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

/// Converts a BLoC stream to a ChangeNotifier for GoRouter's refreshListenable
class _GoRouterAuthRefreshStream extends ChangeNotifier {
  _GoRouterAuthRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
