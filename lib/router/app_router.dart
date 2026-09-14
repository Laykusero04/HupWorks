import 'dart:async';

import 'package:flutter/material.dart';
import 'package:freelancer/l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/auth/role_cache.dart';
import '../core/chat/chat_unread_scope.dart';
import '../core/constants/colors.dart';
import '../core/onboarding/onboarding_prefs.dart';
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
import '../screen/client screen/client job post/create_new_job_post.dart';
import '../screen/client screen/client job post/job_details.dart';
import '../screen/client screen/client orders/client_order_details.dart';
import '../screen/client screen/applications/client_applications.dart';
import '../screen/client screen/client favourite/client_favourite_list.dart';
import '../screen/client screen/client notification/client_notification.dart';
import '../screen/client screen/client_setting/client_setting.dart';
import '../screen/client screen/client dashboard/client_dashboard.dart';
import '../screen/client screen/client profile/client_profile_details.dart';
import '../screen/client screen/client profile/client_edit_profile_details.dart';
import '../screen/client screen/client profile/employer_verification_screen.dart';
import '../screen/seller screen/seller authentication/seller_log_in.dart';
import '../screen/seller screen/seller authentication/seller_sign_up.dart';
import '../screen/seller screen/seller home/seller_home_screen.dart';
import '../screen/seller screen/orders/seller_orders.dart';
import '../screen/seller screen/orders/seller_order_details.dart';
import '../screen/seller screen/profile/seller_profile.dart';
import '../screen/seller screen/profile/seller_profile_details.dart';
import '../screen/seller screen/profile/seller_edit_profile_details.dart';
import '../screen/seller screen/profile/seller_identity_verification_screen.dart';
import '../screen/seller screen/applications/seller_applications.dart';
import '../screen/seller screen/buyer request/seller_buyer_request.dart';
import '../screen/seller screen/buyer request/buyer_request_details.dart';
import '../screen/seller screen/seller message/chat_list.dart';
import '../screen/seller screen/seller message/chat_inbox_route.dart';
import '../screen/seller screen/notification/seller_notification.dart';
import '../screen/seller screen/setting/seller_setting.dart';
import '../screen/seller screen/seller dashboard/seller_dashboard.dart';
import '../screen/seller screen/setup seller profile/setup_profile.dart';
import '../screen/attendance/attendance_scan_screen.dart';
import '../screen/attendance/seller_attendance_hub_screen.dart';
import '../screen/widgets/auth/update_password_screen.dart';
import '../screen/widgets/shell_tab_header.dart';
import 'route_names.dart';

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
      final isUpdatePassword = location == AppRoutes.updatePassword;
      final isSellerSetup = location == AppRoutes.sellerSetupProfile;
      final isPublicAuthRoute = location.startsWith('/onboard') ||
          location.startsWith('/welcome') ||
          location.startsWith('/auth');

      // Password recovery deep link — force the set-password screen first.
      if (AuthService.passwordRecoveryPending) {
        return isUpdatePassword ? null : AppRoutes.updatePassword;
      }

      // Splash owns its own exit after the Rubik loader animation.
      if (isSplash) {
        return null;
      }

      // Not signed in — first-run onboarding, then welcome / auth
      if (!loggedIn) {
        RoleCache.clear();
        final seenOnboarding = OnboardingPrefs.hasSeen;
        if (!seenOnboarding && location.startsWith('/welcome')) {
          return '/onboard';
        }
        if (seenOnboarding && location.startsWith('/onboard')) {
          return '/welcome';
        }
        if (isUpdatePassword) {
          return '/welcome';
        }
        // Setup requires a session.
        if (isSellerSetup) {
          return '/welcome';
        }
        return isPublicAuthRoute ? null : '/welcome';
      }

      // Source of truth: profiles.role (cached). Never use JWT userMetadata here.
      final role = AuthService.cachedRole;

      // Freelancer must finish account setup before using the app.
      if (role == 'seller' && AuthService.needsSellerOnboarding) {
        return isSellerSetup ? null : AppRoutes.sellerSetupProfile;
      }

      // Already finished setup — don't stay on the setup screen.
      if (isSellerSetup) {
        return AuthService.homePathForRole(role);
      }

      // Signed in — bounce other auth screens to the correct home (splash navigates itself)
      if (isPublicAuthRoute && !isSellerSetup) {
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
      if (location == '/client/profile') {
        return '/client';
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
      GoRoute(
        path: AppRoutes.sellerSetupProfile,
        builder: (context, state) => const SetupSellerProfile(),
      ),
      GoRoute(
        path: AppRoutes.updatePassword,
        builder: (context, state) => const UpdatePasswordScreen(),
      ),

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

      // Client — Applications inbox (outside shell so it pushes over bottom nav).
      GoRoute(
        path: AppRoutes.clientApplications,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ClientApplications(),
      ),
      GoRoute(
        path: AppRoutes.clientJobCreate,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CreateNewJobPost(),
      ),
      GoRoute(
        path: AppRoutes.clientJobDetails,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => JobDetails(
          jobPostId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.clientOrderDetails,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => ClientOrderDetails(
          orderId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.clientChatInbox,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => ChatInboxRoute(
          conversationId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.clientFavourites,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ClientFavList(),
      ),
      GoRoute(
        path: AppRoutes.clientNotifications,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ClientNotification(),
      ),
      GoRoute(
        path: AppRoutes.clientSettings,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ClientSetting(),
      ),
      GoRoute(
        path: AppRoutes.clientDashboard,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ClientDashBoard(),
      ),
      GoRoute(
        path: AppRoutes.clientProfileDetails,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ClientProfileDetails(),
      ),
      GoRoute(
        path: AppRoutes.clientProfileEdit,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ClientEditProfile(),
      ),
      GoRoute(
        path: AppRoutes.clientProfileVerify,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const EmployerVerificationScreen(),
      ),

      // Seller — My Applications (sub-screen, outside the shell so it pushes
      // on top of the bottom-nav scaffold).
      GoRoute(
        path: AppRoutes.sellerApplications,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SellerApplications(),
      ),
      GoRoute(
        path: AppRoutes.sellerOrderDetails,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => SellerOrderDetails(
          orderId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.sellerBuyerRequestDetails,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => BuyerRequestDetails(
          jobPostId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.sellerChatInbox,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => ChatInboxRoute(
          conversationId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.sellerAttendance,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => SellerAttendanceHubScreen(
          highlightJobPostId: state.uri.queryParameters['jobPostId'],
        ),
      ),
      GoRoute(
        path: AppRoutes.sellerAttendanceScan,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => AttendanceScanScreen(
          hintJobPostId: state.uri.queryParameters['jobPostId'],
        ),
      ),
      GoRoute(
        path: AppRoutes.sellerNotifications,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SellerNotification(),
      ),
      GoRoute(
        path: AppRoutes.sellerSettings,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SellerSetting(),
      ),
      GoRoute(
        path: AppRoutes.sellerDashboard,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SellerDashBoard(),
      ),
      GoRoute(
        path: AppRoutes.sellerProfileDetails,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SellerProfileDetails(),
      ),
      GoRoute(
        path: AppRoutes.sellerProfileEdit,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SellerEditProfile(),
      ),
      GoRoute(
        path: AppRoutes.sellerProfileVerify,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SellerIdentityVerificationScreen(),
      ),
    ],
  );
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
    final chatUnread = ChatUnreadScope.of(context);

    return ListenableBuilder(
      listenable: chatUnread,
      builder: (context, _) {
        final unread = chatUnread.totalUnread;
        final items = persona == ShellPersona.client
            ? _clientNavItems(context, unread)
            : _sellerNavItems(context, unread);

        return Scaffold(
          key: scaffoldKey,
          backgroundColor: kWhite,
          extendBody: false,
          drawer: drawer,
          body: navigationShell,
          bottomNavigationBar: _ShellBottomNav(
            accent: _accentColor,
            currentIndex: navigationShell.currentIndex,
            items: items,
            onTap: (i) => navigationShell.goBranch(
              i,
              initialLocation: i == navigationShell.currentIndex,
            ),
          ),
        );
      },
    );
  }
}

class _ShellNavItem {
  const _ShellNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final Widget icon;
  final Widget activeIcon;
  final String label;
}

List<_ShellNavItem> _clientNavItems(BuildContext context, int chatUnread) {
  final l10n = context.l10n;
  return [
    _ShellNavItem(
      icon: const Icon(Icons.home_outlined),
      activeIcon: const Icon(Icons.home_rounded),
      label: l10n.home,
    ),
    _ShellNavItem(
      icon: _badgedNavIcon(Icons.chat_bubble_outline, chatUnread),
      activeIcon: _badgedNavIcon(Icons.chat_bubble, chatUnread),
      label: l10n.message,
    ),
    _ShellNavItem(
      icon: const Icon(Icons.people_outline),
      activeIcon: const Icon(Icons.people_rounded),
      label: l10n.talent,
    ),
    _ShellNavItem(
      icon: const Icon(Icons.work_outline),
      activeIcon: const Icon(Icons.work_rounded),
      label: l10n.myJobs,
    ),
    _ShellNavItem(
      icon: const Icon(Icons.description_outlined),
      activeIcon: const Icon(Icons.description_rounded),
      label: l10n.contracts,
    ),
  ];
}

List<_ShellNavItem> _sellerNavItems(BuildContext context, int chatUnread) {
  final l10n = context.l10n;
  return [
    _ShellNavItem(
      icon: const Icon(Icons.home_outlined),
      activeIcon: const Icon(Icons.home_rounded),
      label: l10n.home,
    ),
    _ShellNavItem(
      icon: _badgedNavIcon(Icons.chat_bubble_outline, chatUnread),
      activeIcon: _badgedNavIcon(Icons.chat_bubble, chatUnread),
      label: l10n.message,
    ),
    _ShellNavItem(
      icon: const Icon(Icons.search),
      activeIcon: const Icon(Icons.search_rounded),
      label: l10n.findJobs,
    ),
    _ShellNavItem(
      icon: const Icon(Icons.description_outlined),
      activeIcon: const Icon(Icons.description_rounded),
      label: l10n.contracts,
    ),
  ];
}

Widget _badgedNavIcon(IconData icon, int count) {
  if (count <= 0) return Icon(icon);
  return Badge(
    label: Text(
      count > 9 ? '9+' : '$count',
      style: const TextStyle(fontSize: 10),
    ),
    child: Icon(icon),
  );
}

/// Compact shell bottom nav — clear selected state, tight safe-area padding.
class _ShellBottomNav extends StatelessWidget {
  const _ShellBottomNav({
    required this.accent,
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  final Color accent;
  final int currentIndex;
  final List<_ShellNavItem> items;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Material(
      color: kWhite,
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: kWhite,
          border: const Border(
            top: BorderSide(color: kBorderColorTextField, width: 0.8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(6, 6, 6, bottomInset > 0 ? bottomInset : 8),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _ShellBottomNavTile(
                    item: items[i],
                    selected: i == currentIndex,
                    accent: accent,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShellBottomNavTile extends StatelessWidget {
  const _ShellBottomNavTile({
    required this.item,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final _ShellNavItem item;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? accent : kLightNeutralColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? accent.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconTheme(
                data: IconThemeData(color: color, size: 22),
                child: selected ? item.activeIcon : item.icon,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                height: 1.1,
              ),
            ),
          ],
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
    if (authState.event == AuthChangeEvent.passwordRecovery) {
      AuthService.passwordRecoveryPending = true;
    }

    final session = authState.session;
    if (session == null) {
      RoleCache.clear();
      AuthService.passwordRecoveryPending = false;
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
