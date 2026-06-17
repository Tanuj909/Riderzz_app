import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://10.228.162.2:4000';

  // Auth Endpoints
  static const String sendOtp = '/auth/send-otp';
  static const String register = '/auth/register';
  static const String loginVerifyOtp = '/auth/login-otp';
  static const String me = '/auth/me';
  static const String adminLogin = '/admin/auth/login';
  static const String vehicleTypes = '/admin/vehicle-types';
  static const String adminDrivers = '/admin/drivers';

  // User Endpoints
  static const String addresses = '/user/addresses';

  // Driver Endpoints
  static const String driverProfile = '/driver/profile';
  static const String driverWallet = '/driver/wallet';
  static const String driverWalletRecharge = '/driver/wallet/recharge';
  static const String driverOnline = '/driver/online';
  static const String driverOffline = '/driver/offline';
}
