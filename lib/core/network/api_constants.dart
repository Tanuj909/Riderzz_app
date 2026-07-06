import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://10.24.69.2:4000/api';

  // Auth Endpoints
  static const String sendOtp = '/auth/send-otp';
  static const String register = '/auth/register';
  static const String loginVerifyOtp = '/auth/login/otp';
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
  static const String driverWallet = '/driver/wallet';
  static const String driverWalletRecharge = '/driver/wallet/recharge';
  static const String driverOnline = '/driver/online';
  static const String driverOffline = '/driver/offline';
  static const String driverApply = '/driver/register';
  static const String availableVehicles = '/driver/vehicles/available';
  static const String driverDocuments = '/driver/documents';
  static const String bankAccounts = '/wallet/bank-accounts';
  static const String primaryBankAccount = '/wallet/bank-accounts/primary';
}
