class AppRoutes {
  // Auth
  static const splash = '/';
  static const onboard = '/onboard';
  static const welcome = '/welcome';
  static const clientLogin = '/auth/client/login';
  static const clientSignUp = '/auth/client/signup';
  static const clientForgotPassword = '/auth/client/forgot-password';
  static const sellerLogin = '/auth/seller/login';
  static const sellerSignUp = '/auth/seller/signup';
  static const sellerForgotPassword = '/auth/seller/forgot-password';
  static const sellerSetupProfile = '/auth/seller/setup-profile';

  // Client shell tabs
  static const clientHome = '/client';
  static const clientChat = '/client/chat';
  static const clientChatInbox = '/client/chat/:id';
  static const clientJobs = '/client/jobs';
  static const clientJobCreate = '/client/jobs/create';
  static const clientJobDetails = '/client/jobs/:id';
  static const clientOrders = '/client/orders';
  static const clientOrderDetails = '/client/orders/:id';
  static const clientProfile = '/client/profile';
  static const clientProfileDetails = '/client/profile/details';
  static const clientProfileEdit = '/client/profile/edit';

  // Client non-tab routes
  static const clientDashboard = '/client/dashboard';
  static const clientFavourites = '/client/favourites';
  static const clientNotifications = '/client/notifications';
  static const clientDeposit = '/client/deposit';
  static const clientDepositHistory = '/client/deposit/history';
  static const clientTransactions = '/client/transactions';
  static const clientSearch = '/client/search';
  static const clientSettings = '/client/settings';

  // Seller shell tabs
  static const sellerHome = '/seller';
  static const sellerChat = '/seller/chat';
  static const sellerChatInbox = '/seller/chat/:id';
  static const sellerCreateService = '/seller/create-service';
  static const sellerOrders = '/seller/orders';
  static const sellerOrderDetails = '/seller/orders/:id';
  static const sellerProfile = '/seller/profile';
  static const sellerProfileDetails = '/seller/profile/details';
  static const sellerProfileEdit = '/seller/profile/edit';

  // Seller non-tab routes
  static const sellerMyServices = '/seller/services';
  static const sellerServiceDetails = '/seller/services/:id';
  static const sellerBuyerRequests = '/seller/buyer-requests';
  static const sellerBuyerRequestDetails = '/seller/buyer-requests/:id';
  static const sellerNotifications = '/seller/notifications';
  static const sellerTransactions = '/seller/transactions';
  static const sellerWithdraw = '/seller/withdraw';
  static const sellerWithdrawHistory = '/seller/withdraw/history';
  static const sellerSettings = '/seller/settings';

  // Shared
  static const serviceDetails = '/service/:id';
}
