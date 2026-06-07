import 'package:riderzz_app/app/constants/api_constants.dart';
import 'package:riderzz_app/core/api/dio_client.dart';
import 'package:riderzz_app/core/models/user_model.dart';

class AuthService {
  final DioClient _dioClient;

  AuthService(this._dioClient);

  /// Requests OTP to be sent to the specified phone number.
  Future<String> sendOtp(String phone) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.sendOtp,
        data: {'phone': phone},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data?.toString() ?? 'OTP Sent Successfully';
      }
      throw Exception('Failed to send OTP');
    } catch (e) {
      rethrow;
    }
  }

  /// Registers a user using Name, Phone, Password, and OTP.
  Future<UserModel> register({
    required String name,
    required String phone,
    required String password,
    required String otp,
  }) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.register,
        data: {
          'name': name,
          'phone': phone,
          'password': password,
          'otp': otp,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(response.data);
        return UserModel.fromJson(data, name: name, phone: phone);
      }
      throw Exception('Registration failed');
    } catch (e) {
      rethrow;
    }
  }

  /// Requests OTP to be sent for login.
  Future<String> loginSendOtp(String phone) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.loginSendOtp,
        data: {'phone': phone},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(response.data);
        return data['message'] ?? 'OTP Sent Successfully';
      }
      throw Exception('Failed to send Login OTP');
    } catch (e) {
      rethrow;
    }
  }

  /// Verifies login OTP and logs the user in.
  Future<UserModel> loginVerifyOtp({
    required String phone,
    required String otp,
  }) async {
    try {
      final response = await _dioClient.post(
        ApiConstants.loginVerifyOtp,
        data: {
          'phone': phone,
          'otp': otp,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(response.data);
        return UserModel.fromJson(data, phone: phone);
      }
      throw Exception('Verification failed');
    } catch (e) {
      rethrow;
    }
  }
}
