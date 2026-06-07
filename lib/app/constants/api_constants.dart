import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:4000/api';

  // Auth Endpoints
  static const String sendOtp = '/auth/send-otp';
  static const String register = '/auth/register';
  static const String loginSendOtp = '/auth/login/send-otp';
  static const String loginVerifyOtp = '/auth/login/verify-otp';
}
