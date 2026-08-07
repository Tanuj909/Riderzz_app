import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String? _customBaseUrl;
  static set customBaseUrl(String url) => _customBaseUrl = url;

  static String get baseUrl =>
      _customBaseUrl ?? dotenv.env['API_BASE_URL'] ?? 'http://10.24.69.2:4000/api';

  // Auth Endpoints
  static const String sendOtp = '/auth/send-otp';
  static const String register = '/auth/register';
  static const String registerNoOtp = '/auth/register/no-otp';
  static const String loginVerifyOtp = '/auth/login/otp';
  static const String loginWithPassword = '/auth/login/password';
  static const String refreshToken = '/auth/refresh-token';
  static const String forgotPassword = '/auth/forgot-password';
  static const String me = '/auth/me';
  static const String customerProfileMe = '/profile/me';
  static const String customerProfileUpdate = '/profile/customer';
  static const String uploadProfileImage = '/profile/image';
  static const String adminLogin = '/auth/login/password';
  static const String vehicleTypes = '/vehicle-types';
  static const String adminDrivers = '/drivers';
  static const String adminDriverList = '/driver/admin/list';
  static const String adminVehicles = '/admin/vehicles';
  static const String adminCommissionConfigs = '/admin/commission-configs';

  // User Endpoints
  static const String addresses = '/addresses';
  static const String savedRoutes = '/saved-routes';
  static const String bookings = '/bookings';

  // Driver Endpoints
  static const String driverProfile = '/driver/profile';
  static const String driverWallet = '/wallet';
  static const String driverWalletTransactions = '/wallet/transactions';
  static const String driverWalletCreate = '/wallet/create';
  static const String walletRechargeInitiate = '/wallet/recharge/initiate';
  static const String walletRechargeVerify = '/wallet/recharge/verify';
  static const String driverOnline = '/driver/online';
  static const String driverLocation = '/driver/location';
  static const String driverApply = '/driver/register';
  static const String availableVehicles = '/driver/vehicles/available';
  static const String driverDocuments = '/driver/documents';
  static const String bankAccounts = '/wallet/bank-accounts';
  static const String primaryBankAccount = '/wallet/bank-accounts/primary';
  static const String bookingsAll = '/bookings/all';
  static const String driverBookings = '/driver/bookings';
  static const String driverPendingBroadcasts = '/driver/bookings/broadcasts/pending';
  static const String bookingsCurrent = '/bookings/current';
  static const String driverEarnings = '/driver/earnings';
  static const String driverMessages = '/driver/messages';
  static const String driverMessagesRead = '/driver/messages/read';

  // Admin Wallet Endpoints
  static const String adminWallets = '/admin/wallet/wallets';
  static String adminDriverTransactions(int driverId) => '/admin/wallet/drivers/$driverId/transactions';
  static const String adminWithdrawalsPending = '/admin/wallet/withdrawals/pending';
  static const String adminWithdrawalsAll = '/admin/wallet/withdrawals/all';
  static const String adminWalletOverview = '/admin/wallet/overview';

  // Support Endpoints
  static const String supportTickets = '/support/tickets';

  // Notification Endpoints
  static const String registerDeviceToken = '/notifications/device-token';
  static const String unregisterDeviceToken = '/notifications/device-token';
}
