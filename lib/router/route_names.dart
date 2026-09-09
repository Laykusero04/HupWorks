/// Canonical path names for [GoRouter]. Prefer helpers below when building
/// parameterized URLs for deep links / notifications.
class AppRoutes {
  // Auth
  static const splash = '/';
  static const onboard = '/onboard';
  static const welcome = '/welcome';
  static const clientLogin = '/auth/client/login';
  static const clientSignUp = '/auth/client/signup';
  static const sellerLogin = '/auth/seller/login';
  static const sellerSignUp = '/auth/seller/signup';
  static const updatePassword = '/auth/update-password';
  static const sellerSetupProfile = '/auth/seller/setup-profile';

  // Client shell tabs
  static const clientHome = '/client';
  static const clientChat = '/client/chat';
  static const clientTalent = '/client/talent';
  static const clientJobs = '/client/jobs';
  static const clientOrders = '/client/orders';

  /// Profile menu lives in the shell drawer (no tab route).
  static const clientProfile = '/client/profile';

  // Client pushed routes (root navigator)
  static const clientJobCreate = '/client/jobs/create';
  static const clientJobDetails = '/client/jobs/:id';
  static const clientOrderDetails = '/client/orders/:id';
  static const clientChatInbox = '/client/chat/:id';
  static const clientApplications = '/client/applications';
  static const clientFavourites = '/client/favourites';
  static const clientNotifications = '/client/notifications';
  static const clientSettings = '/client/settings';
  static const clientDashboard = '/client/dashboard';
  static const clientProfileDetails = '/client/profile/details';
  static const clientProfileEdit = '/client/profile/edit';

  // Seller shell tabs
  static const sellerHome = '/seller';
  static const sellerChat = '/seller/chat';
  static const sellerFindJobs = '/seller/find-jobs';
  static const sellerOrders = '/seller/orders';

  /// Profile menu lives in the shell drawer (no tab route).
  static const sellerProfile = '/seller/profile';

  // Seller pushed routes (root navigator)
  static const sellerChatInbox = '/seller/chat/:id';
  static const sellerOrderDetails = '/seller/orders/:id';
  static const sellerBuyerRequestDetails = '/seller/find-jobs/:id';
  static const sellerApplications = '/seller/applications';
  static const sellerAttendance = '/seller/attendance';
  static const sellerAttendanceScan = '/seller/attendance/scan';
  static const sellerNotifications = '/seller/notifications';
  static const sellerSettings = '/seller/settings';
  static const sellerDashboard = '/seller/dashboard';
  static const sellerProfileDetails = '/seller/profile/details';
  static const sellerProfileEdit = '/seller/profile/edit';
  static const sellerProfileVerify = '/seller/profile/verify';

  // Path helpers for deep links / notifications
  static String clientJobDetailsOf(String id) => '/client/jobs/$id';
  static String clientOrderDetailsOf(String id) => '/client/orders/$id';
  static String clientChatInboxOf(String id) => '/client/chat/$id';
  static String sellerOrderDetailsOf(String id) => '/seller/orders/$id';
  static String sellerBuyerRequestDetailsOf(String id) =>
      '/seller/find-jobs/$id';
  static String sellerChatInboxOf(String id) => '/seller/chat/$id';
}
